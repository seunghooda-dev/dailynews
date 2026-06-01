from __future__ import annotations

import argparse
import json
import re
import time
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from datetime import datetime
from email.utils import parsedate_to_datetime
from html import unescape
from pathlib import Path
from typing import Iterable
from urllib.parse import quote_plus

import requests
from bs4 import BeautifulSoup

from dailynews_backend.importance import enrich_article_importance, select_representative_articles
from dailynews_backend.models import RawArticle, StructuredArticle


USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/125.0 Safari/537.36"
)

SECTOR_LABELS = {
    "AI": "AI",
    "US Stocks": "미국 주식",
    "Rates": "금리",
    "Crypto": "가상자산",
    "Energy": "에너지",
    "FX": "외환",
    "China": "중국",
    "Europe": "유럽",
    "Commodities": "원자재",
    "Global Markets": "글로벌 시장",
}


@dataclass(frozen=True)
class FeedSource:
    name: str
    url: str


class TranslationClient:
    def __init__(self, enabled: bool = True, timeout_seconds: int = 12) -> None:
        self.enabled = enabled
        self.timeout_seconds = timeout_seconds
        self.session = requests.Session()
        self.cache: dict[str, str] = {}

    def to_korean(self, text: str) -> str:
        text = _normalize_text(text)
        if not text or _contains_hangul(text) or not self.enabled:
            return text
        if text in self.cache:
            return self.cache[text]

        translated = self._request_translation(text)
        self.cache[text] = translated
        return translated

    def _request_translation(self, text: str) -> str:
        last_error: Exception | None = None
        for attempt in range(3):
            try:
                response = self.session.get(
                    "https://translate.googleapis.com/translate_a/single",
                    params={
                        "client": "gtx",
                        "sl": "en",
                        "tl": "ko",
                        "dt": "t",
                        "q": text,
                    },
                    headers={
                        "User-Agent": USER_AGENT,
                        "Accept-Language": "ko-KR,ko;q=0.9,en-US;q=0.7,en;q=0.6",
                    },
                    timeout=self.timeout_seconds,
                )
                response.raise_for_status()
                data = response.json()
                translated = "".join(
                    segment[0]
                    for segment in data[0]
                    if isinstance(segment, list) and segment and segment[0]
                )
                translated = _normalize_text(translated)
                return translated or text
            except (requests.RequestException, ValueError, TypeError, IndexError) as exc:
                last_error = exc
                if attempt < 2:
                    time.sleep(0.4 * (attempt + 1))
        print(f"skip translation: {last_error}")
        return text


def build_feed_sources() -> tuple[FeedSource, ...]:
    google_query = quote_plus(
        "global markets OR stock market OR Federal Reserve OR Nvidia OR oil prices when:2d"
    )
    return (
        FeedSource(
            "Google News",
            "https://news.google.com/rss/search"
            f"?q={google_query}&hl=en-US&gl=US&ceid=US:en",
        ),
        FeedSource("Yahoo Finance", "https://finance.yahoo.com/news/rssindex"),
        FeedSource(
            "Yahoo Finance",
            "https://feeds.finance.yahoo.com/rss/2.0/headline"
            "?s=%5EGSPC,%5EIXIC,%5EDJI,GC%3DF,CL%3DF,BTC-USD,NVDA,AAPL,MSFT"
            "&region=US&lang=en-US",
        ),
    )


def collect_world_articles(limit: int) -> list[RawArticle]:
    articles: list[RawArticle] = []
    seen_urls: set[str] = set()
    seen_titles: set[str] = set()

    for source in build_feed_sources():
        if len(articles) >= limit:
            break
        for article in _read_feed(source):
            if len(articles) >= limit:
                break
            normalized_title = _normalize_text(article.title).lower()
            clean_url = article.url.split("#", 1)[0]
            if clean_url in seen_urls or normalized_title in seen_titles:
                continue
            seen_urls.add(clean_url)
            seen_titles.add(normalized_title)
            articles.append(article)

    return articles


def _read_feed(source: FeedSource) -> list[RawArticle]:
    try:
        response = requests.get(
            source.url,
            headers={
                "User-Agent": USER_AGENT,
                "Accept": "application/rss+xml, application/xml;q=0.9, */*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
            },
            timeout=20,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        print(f"skip world feed {source.url}: {exc}")
        return []

    try:
        root = ET.fromstring(response.content)
    except ET.ParseError as exc:
        print(f"skip world feed parse {source.url}: {exc}")
        return []

    articles: list[RawArticle] = []
    for item in root.findall(".//item"):
        title = _node_text(item, "title")
        url = _node_text(item, "link")
        if not title or not url:
            continue

        publisher = _publisher_from_item(item) or source.name
        title = _strip_source_suffix(title, publisher)
        summary = _summary_from_item(item)
        published_at = _format_published_at(_node_text(item, "pubDate"))
        content = _build_content(title, publisher, summary, published_at)
        articles.append(
            RawArticle(
                title=_normalize_text(title),
                url=url.strip(),
                source=publisher,
                published_at=published_at,
                content=content,
                is_headline=source.name == "Yahoo Finance" and len(articles) < 6,
            )
        )

    return articles


def build_world_snapshot(
    articles: Iterable[RawArticle],
    target_date: str,
    translator: TranslationClient | None = None,
) -> dict[str, object]:
    translator = translator or TranslationClient()
    representative_articles = select_representative_articles(
        enrich_article_importance(articles)
    )
    structured = [
        structure_world_article(article, translator)
        for article in representative_articles
    ]
    return {
        "date": target_date,
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "articles": [article.to_firestore_map() for article in structured],
    }


def structure_world_article(
    article: RawArticle,
    translator: TranslationClient | None = None,
) -> StructuredArticle:
    translator = translator or TranslationClient()
    content = article.content or article.title
    sector_key = classify_world_sector_key(f"{article.title} {content}")
    sector = SECTOR_LABELS[sector_key]
    title = translator.to_korean(article.title)
    issue_keyword = translator.to_korean(article.issue_keyword) if article.issue_keyword else ""
    what_happened = translator.to_korean(extract_world_summary(content))
    context = build_world_context(sector, article.source)
    implication = build_world_implication(sector)
    return StructuredArticle(
        title=title,
        url=article.url,
        source=article.source,
        published_at=article.published_at,
        collected_at=datetime.now().isoformat(timespec="seconds"),
        is_headline=article.is_headline,
        cluster_count=article.cluster_count,
        issue_keyword=issue_keyword,
        related_sources=article.related_sources,
        sector=sector,
        what_happened=what_happened,
        context=context,
        implication=implication,
    )


def classify_world_sector(text: str) -> str:
    return SECTOR_LABELS[classify_world_sector_key(text)]


def classify_world_sector_key(text: str) -> str:
    normalized = text.lower()
    rules = [
        ("AI", ("ai", "artificial intelligence", "nvidia", "gpu", "semiconductor")),
        ("US Stocks", ("s&p", "nasdaq", "dow", "wall street", "stocks", "equities")),
        ("Rates", ("federal reserve", "fed", "rate", "yield", "treasury", "inflation")),
        ("Crypto", ("bitcoin", "crypto", "ethereum", "coinbase")),
        ("Energy", ("oil", "opec", "crude", "energy", "gas")),
        ("FX", ("dollar", "euro", "yen", "currency", "forex")),
        ("China", ("china", "hong kong", "beijing", "shanghai")),
        ("Europe", ("europe", "ecb", "stoxx", "london", "germany", "france")),
        ("Commodities", ("gold", "copper", "commodity", "silver")),
    ]
    for sector, keywords in rules:
        if any(_contains_market_keyword(normalized, keyword) for keyword in keywords):
            return sector
    return "Global Markets"


def _contains_market_keyword(text: str, keyword: str) -> bool:
    if len(keyword) <= 3 and keyword.isascii():
        return bool(re.search(rf"\b{re.escape(keyword)}\b", text))
    return keyword in text


def extract_world_summary(content: str) -> str:
    cleaned = _normalize_text(content)
    sentences = [
        sentence.strip()
        for sentence in re.split(r"(?<=[.!?])\s+", cleaned)
        if len(sentence.strip()) >= 24
    ]
    if sentences:
        return " ".join(sentences[:2])[:420]
    return cleaned[:420]


def build_world_context(sector: str, source: str) -> str:
    return (
        f"{source}에 올라온 글로벌 시장 기사입니다. {sector} 흐름은 미국 금리, "
        "달러, 대형 기술주 실적, 원자재 가격, 지정학 변수와 함께 한국 시장의 "
        "외국인 수급과 위험자산 선호에 영향을 줄 수 있습니다."
    )


def build_world_implication(sector: str) -> str:
    implications = {
        "AI": "AI와 반도체 관련 뉴스는 국내 HBM, 메모리, 장비, 전력 인프라 밸류체인 투자심리에 직접 연결될 수 있습니다.",
        "US Stocks": "미국 지수 방향은 다음 한국 장의 외국인 선물·현물 수급과 성장주 밸류에이션에 영향을 줄 수 있습니다.",
        "Rates": "금리와 국채금리 변화는 원/달러 환율, 외국인 자금 흐름, 성장주 할인율에 동시에 영향을 줄 수 있습니다.",
        "Crypto": "가상자산 뉴스는 위험자산 선호와 거래대금, 국내 거래소·핀테크 관련 투자심리에 영향을 줄 수 있습니다.",
        "Energy": "유가와 에너지 가격 변화는 항공·화학·정유·조선 업종의 비용과 마진 전망을 흔들 수 있습니다.",
        "FX": "달러와 주요 통화 흐름은 수출주 환율 민감도, 외국인 자금 유입, 원화 자산 선호에 연결됩니다.",
        "China": "중국 경기와 정책 뉴스는 국내 화학, 철강, 화장품, 반도체 수요 전망에 영향을 줄 수 있습니다.",
        "Europe": "유럽 경기와 ECB 정책 변화는 글로벌 위험자산 선호와 달러 흐름을 통해 한국 증시에 간접 영향을 줍니다.",
        "Commodities": "금, 구리 등 원자재 가격은 인플레이션 기대와 소재·산업재 업종의 실적 전망을 바꿀 수 있습니다.",
    }
    return implications.get(
        sector,
        "글로벌 시장 뉴스는 한국 증시 개장 전 위험자산 선호, 환율, 외국인 수급, 대형 수출주의 투자심리를 점검하는 선행 지표로 활용할 수 있습니다.",
    )


def _node_text(item: ET.Element, tag: str) -> str:
    node = item.find(tag)
    return (node.text or "").strip() if node is not None else ""


def _publisher_from_item(item: ET.Element) -> str | None:
    source_node = item.find("source")
    if source_node is not None and source_node.text:
        return _normalize_text(source_node.text)
    creator_node = item.find("{http://purl.org/dc/elements/1.1/}creator")
    if creator_node is not None and creator_node.text:
        return _normalize_text(creator_node.text)
    return None


def _summary_from_item(item: ET.Element) -> str:
    for tag in ("description", "{http://search.yahoo.com/mrss/}description"):
        text = _node_text(item, tag)
        if text:
            return _html_to_text(text)
    return ""


def _build_content(
    title: str,
    publisher: str,
    summary: str,
    published_at: str | None,
) -> str:
    if summary and _normalize_text(summary).lower() != _normalize_text(title).lower():
        return summary
    return title


def _format_published_at(value: str) -> str | None:
    if not value:
        return None
    try:
        parsed = parsedate_to_datetime(value)
    except (TypeError, ValueError):
        return _normalize_text(value)
    return parsed.strftime("%Y.%m.%d %H:%M")


def _html_to_text(value: str) -> str:
    soup = BeautifulSoup(unescape(value), "html.parser")
    return _normalize_text(soup.get_text(" ", strip=True))


def _normalize_text(value: str) -> str:
    return " ".join(unescape(value).replace("\u200b", "").split())


def _contains_hangul(value: str) -> bool:
    return bool(re.search(r"[가-힣]", value))


def _strip_source_suffix(title: str, publisher: str) -> str:
    cleaned = _normalize_text(title)
    suffix = f" - {publisher}"
    if cleaned.endswith(suffix):
        return cleaned[: -len(suffix)].strip()
    return cleaned


def main() -> None:
    parser = argparse.ArgumentParser(description="Create a world market news snapshot.")
    parser.add_argument("--limit", type=int, default=80)
    parser.add_argument("--output", default="web/world_news_snapshot.json")
    parser.add_argument(
        "--no-translate",
        action="store_true",
        help="Keep English titles and summaries without machine translation.",
    )
    parser.add_argument(
        "--date",
        default=datetime.now().strftime("%Y-%m-%d"),
        help="Snapshot date label. Format: YYYY-MM-DD.",
    )
    args = parser.parse_args()

    articles = collect_world_articles(args.limit)
    snapshot = build_world_snapshot(
        articles,
        args.date,
        TranslationClient(enabled=not args.no_translate),
    )
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(snapshot, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"wrote {len(snapshot['articles'])} world articles to {output_path}")


if __name__ == "__main__":
    main()
