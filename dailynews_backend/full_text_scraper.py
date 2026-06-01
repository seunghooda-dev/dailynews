from __future__ import annotations

import argparse
import json
import random
import re
from dataclasses import asdict, dataclass
from html import unescape
from typing import Iterable
from urllib.parse import urljoin, urlparse


USER_AGENTS = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/125.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 "
    "(KHTML, like Gecko) Version/17.5 Safari/605.1.15",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/125.0 Safari/537.36",
)


@dataclass(frozen=True)
class FullTextArticle:
    url: str
    title: str
    source: str
    full_text: str

    def to_dict(self) -> dict[str, str]:
        return asdict(self)


class FullTextScraper:
    def __init__(
        self,
        timeout_seconds: int = 20,
        browser_timeout_ms: int = 20_000,
        user_agents: Iterable[str] = USER_AGENTS,
    ) -> None:
        self.timeout_seconds = timeout_seconds
        self.browser_timeout_ms = browser_timeout_ms
        self.user_agents = tuple(user_agents)

    def scrape(self, url: str) -> dict[str, str]:
        normalized_url = _normalize_url(url)
        domain = _domain(normalized_url)

        if _is_google_news_domain(domain):
            resolved_url = self._resolve_google_news_url(normalized_url)
            resolved_domain = _domain(resolved_url)
            if _is_yahoo_finance_domain(resolved_domain):
                return self._scrape_yahoo_finance(resolved_url).to_dict()
            return self._scrape_generic_article(resolved_url).to_dict()

        if _is_yahoo_finance_domain(domain):
            return self._scrape_yahoo_finance(normalized_url).to_dict()

        return self._scrape_generic_article(normalized_url).to_dict()

    def scrape_many(self, urls: Iterable[str]) -> list[dict[str, str]]:
        return [self.scrape(url) for url in urls]

    def _resolve_google_news_url(self, url: str) -> str:
        requests = _import_requests()
        response = requests.get(
            url,
            headers=self._headers(accept_html=True),
            timeout=self.timeout_seconds,
            allow_redirects=True,
        )
        response.raise_for_status()

        if not _is_google_news_domain(_domain(response.url)):
            return response.url

        html = response.text or ""
        refresh_url = _extract_meta_refresh_url(html, response.url)
        if refresh_url and not _is_google_news_domain(_domain(refresh_url)):
            return refresh_url

        external_link = _extract_first_external_link(html, response.url)
        if external_link and not _is_google_news_domain(_domain(external_link)):
            return external_link

        return response.url

    def _scrape_generic_article(self, url: str) -> FullTextArticle:
        parsed = self._newspaper_parse(url)
        if parsed.full_text.strip():
            return parsed
        return self._fallback_readability_parse(url)

    def _newspaper_parse(self, url: str) -> FullTextArticle:
        try:
            from newspaper import Article
        except ImportError:
            return FullTextArticle(
                url=url,
                title="",
                source=_source_from_url(url),
                full_text="",
            )

        article = Article(
            url,
            browser_user_agent=self._user_agent(),
            request_timeout=self.timeout_seconds,
            fetch_images=True,
        )
        article.download()
        article.parse()
        return FullTextArticle(
            url=article.url or url,
            title=_normalize_text(article.title),
            source=_source_from_url(article.source_url or url),
            full_text=_normalize_multiline_text(article.text),
        )

    def _fallback_readability_parse(self, url: str) -> FullTextArticle:
        requests = _import_requests()
        BeautifulSoup = _import_beautifulsoup()
        response = requests.get(
            url,
            headers=self._headers(accept_html=True),
            timeout=self.timeout_seconds,
            allow_redirects=True,
        )
        response.raise_for_status()

        soup = BeautifulSoup(response.text, "html.parser")
        for tag in soup(["script", "style", "noscript", "svg"]):
            tag.decompose()

        title = _meta_content(soup, "og:title") or _title_from_soup(soup)
        full_text = _extract_article_like_text(soup)
        return FullTextArticle(
            url=response.url or url,
            title=title,
            source=_meta_content(soup, "og:site_name") or _source_from_url(response.url or url),
            full_text=full_text,
        )

    def _scrape_yahoo_finance(self, url: str) -> FullTextArticle:
        try:
            from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
            from playwright.sync_api import sync_playwright
        except ImportError as exc:
            raise RuntimeError(
                "Yahoo Finance full-text scraping requires playwright. "
                "Install requirements and run `python -m playwright install chromium`."
            ) from exc

        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(
                headless=True,
                args=[
                    "--disable-blink-features=AutomationControlled",
                    "--disable-dev-shm-usage",
                    "--no-sandbox",
                ],
            )
            context = browser.new_context(
                user_agent=self._user_agent(),
                locale="en-US",
                viewport={"width": 1365, "height": 900},
            )
            page = context.new_page()
            try:
                page.goto(
                    url,
                    wait_until="domcontentloaded",
                    timeout=self.browser_timeout_ms,
                )
                page.wait_for_selector("div.caas-body", timeout=self.browser_timeout_ms)
                title = _normalize_text(
                    page.locator("h1").first.text_content(timeout=3_000) or ""
                )
                source = self._yahoo_source(page) or "Yahoo Finance"
                paragraphs = page.locator("div.caas-body p").all_text_contents()
                full_text = _normalize_multiline_text("\n".join(paragraphs))
                if not full_text:
                    raise RuntimeError("Yahoo Finance article body was empty.")
                return FullTextArticle(
                    url=page.url or url,
                    title=title,
                    source=source,
                    full_text=full_text,
                )
            except PlaywrightTimeoutError as exc:
                raise TimeoutError(f"Yahoo Finance article body did not load: {url}") from exc
            finally:
                context.close()
                browser.close()

    def _yahoo_source(self, page: object) -> str:
        selectors = (
            "div.caas-attr-provider",
            "span.caas-attr-provider",
            "meta[property='og:site_name']",
        )
        for selector in selectors:
            locator = page.locator(selector).first
            try:
                if selector.startswith("meta"):
                    value = locator.get_attribute("content", timeout=1_000)
                else:
                    value = locator.text_content(timeout=1_000)
            except Exception:
                value = None
            normalized = _normalize_text(value or "")
            if normalized:
                return normalized
        return ""

    def _headers(self, accept_html: bool = False) -> dict[str, str]:
        headers = {
            "User-Agent": self._user_agent(),
            "Accept-Language": "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7",
            "Cache-Control": "no-cache",
        }
        if accept_html:
            headers["Accept"] = (
                "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
            )
        return headers

    def _user_agent(self) -> str:
        return random.choice(self.user_agents)


def scrape_article_full_text(url: str) -> dict[str, str]:
    return FullTextScraper().scrape(url)


def scrape_articles_full_text(urls: Iterable[str]) -> list[dict[str, str]]:
    return FullTextScraper().scrape_many(urls)


def _normalize_url(url: str) -> str:
    normalized = url.strip()
    if not normalized:
        raise ValueError("url is required.")
    parsed = urlparse(normalized)
    if not parsed.scheme:
        normalized = f"https://{normalized}"
        parsed = urlparse(normalized)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError(f"unsupported url: {url}")
    return normalized


def _domain(url: str) -> str:
    return urlparse(url).netloc.lower().removeprefix("www.")


def _is_google_news_domain(domain: str) -> bool:
    return domain == "news.google.com" or domain.endswith(".news.google.com")


def _is_yahoo_finance_domain(domain: str) -> bool:
    return domain == "finance.yahoo.com" or domain.endswith(".finance.yahoo.com")


def _extract_meta_refresh_url(html: str, base_url: str) -> str | None:
    BeautifulSoup = _import_beautifulsoup()
    soup = BeautifulSoup(html, "html.parser")
    refresh = soup.find("meta", attrs={"http-equiv": re.compile("^refresh$", re.I)})
    if not refresh:
        return None
    content = refresh.get("content") or ""
    match = re.search(r"url\s*=\s*([^;]+)$", content, flags=re.I)
    if not match:
        return None
    return urljoin(base_url, unescape(match.group(1).strip(" '\"")))


def _extract_first_external_link(html: str, base_url: str) -> str | None:
    BeautifulSoup = _import_beautifulsoup()
    soup = BeautifulSoup(html, "html.parser")
    base_domain = _domain(base_url)
    for anchor in soup.find_all("a", href=True):
        href = urljoin(base_url, anchor["href"])
        parsed = urlparse(href)
        if parsed.scheme not in {"http", "https"}:
            continue
        domain = _domain(href)
        if domain and domain != base_domain and not domain.endswith("google.com"):
            return href
    return None


def _extract_article_like_text(soup: object) -> str:
    candidates = []
    for selector in ("article", "main", "[role='main']", "body"):
        for node in soup.select(selector):
            paragraphs = [
                _normalize_text(paragraph.get_text(" ", strip=True))
                for paragraph in node.find_all("p")
            ]
            paragraphs = [paragraph for paragraph in paragraphs if len(paragraph) >= 40]
            if paragraphs:
                candidates.append(paragraphs)
    if not candidates:
        return ""
    best = max(candidates, key=lambda paragraphs: sum(len(item) for item in paragraphs))
    return _normalize_multiline_text("\n".join(best))


def _meta_content(soup: object, property_name: str) -> str:
    node = soup.find("meta", attrs={"property": property_name}) or soup.find(
        "meta",
        attrs={"name": property_name},
    )
    return _normalize_text(node.get("content", "")) if node else ""


def _title_from_soup(soup: object) -> str:
    if soup.title and soup.title.string:
        return _normalize_text(soup.title.string)
    heading = soup.find("h1")
    return _normalize_text(heading.get_text(" ", strip=True)) if heading else ""


def _source_from_url(url: str) -> str:
    domain = _domain(url)
    if not domain:
        return ""
    parts = domain.split(".")
    if len(parts) >= 2 and parts[-2] not in {"co", "com", "net", "org"}:
        return parts[-2].replace("-", " ").title()
    if len(parts) >= 3:
        return parts[-3].replace("-", " ").title()
    return parts[0].replace("-", " ").title()


def _normalize_text(value: str) -> str:
    return " ".join(unescape(value or "").replace("\u200b", "").split())


def _normalize_multiline_text(value: str) -> str:
    lines = [_normalize_text(line) for line in (value or "").splitlines()]
    return "\n".join(line for line in lines if line)


def _import_requests() -> object:
    try:
        import requests
    except ImportError as exc:
        raise RuntimeError("requests is required for full-text scraping.") from exc
    return requests


def _import_beautifulsoup() -> object:
    try:
        from bs4 import BeautifulSoup
    except ImportError as exc:
        raise RuntimeError("beautifulsoup4 is required for full-text scraping.") from exc
    return BeautifulSoup


def main() -> None:
    parser = argparse.ArgumentParser(description="Scrape full text from news URLs.")
    parser.add_argument("urls", nargs="+")
    args = parser.parse_args()

    results = scrape_articles_full_text(args.urls)
    print(json.dumps(results, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
