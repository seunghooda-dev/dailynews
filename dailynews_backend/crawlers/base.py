from __future__ import annotations

import random
import re
from abc import ABC, abstractmethod
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup, Tag

from dailynews_backend.models import RawArticle


class BaseCrawler(ABC):
    source_name: str
    base_url: str
    list_urls: tuple[str, ...]
    user_agents = (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/125.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 "
        "(KHTML, like Gecko) Version/17.5 Safari/605.1.15",
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/124.0 Safari/537.36",
    )
    headline_container_tokens = (
        "headline",
        "head-line",
        "lead",
        "leading",
        "major",
        "highlight",
        "editor",
        "pick",
        "featured",
        "important",
        "주요",
        "헤드라인",
        "톱",
        "탑",
    )
    headline_list_url_fragments: tuple[str, ...] = ()
    headline_anchor_limit = 6

    def __init__(self, timeout_seconds: int = 20) -> None:
        self.timeout_seconds = timeout_seconds
        self.session = requests.Session()

    def crawl(self, limit: int) -> list[RawArticle]:
        articles: list[RawArticle] = []
        seen_urls: set[str] = set()
        for list_url in self.list_urls:
            soup = self._get_soup(list_url)
            for article in self.parse_list(soup, list_url):
                if article.url in seen_urls:
                    continue
                seen_urls.add(article.url)
                enriched = self.fetch_article(article)
                articles.append(enriched)
                if len(articles) >= limit:
                    return articles
        return articles

    def fetch_article(self, article: RawArticle) -> RawArticle:
        soup = self._get_soup(article.url)
        return RawArticle(
            title=article.title,
            url=article.url,
            source=article.source,
            published_at=article.published_at or self.parse_published_at(soup),
            content=self.parse_content(soup),
            is_headline=article.is_headline,
            cluster_count=article.cluster_count,
            issue_keyword=article.issue_keyword,
            related_sources=article.related_sources,
        )

    def _get_soup(self, url: str) -> BeautifulSoup:
        response = self.session.get(
            url,
            headers=self._headers(),
            timeout=self.timeout_seconds,
        )
        response.raise_for_status()
        response.encoding = response.apparent_encoding or response.encoding
        redirected_url = self._script_redirect_url(response.text)
        if redirected_url:
            return self._get_soup(redirected_url)
        return BeautifulSoup(response.text, "html.parser")

    def _headers(self) -> dict[str, str]:
        return {
            "User-Agent": random.choice(self.user_agents),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7",
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        }

    def _script_redirect_url(self, html: str) -> str | None:
        match = re.search(r"top\.location\.href=['\"]([^'\"]+)['\"]", html)
        return match.group(1) if match else None

    def absolute_url(self, href: str) -> str:
        return urljoin(self.base_url, href)

    def is_headline_anchor(
        self,
        anchor: Tag,
        list_url: str | None = None,
        index: int | None = None,
    ) -> bool:
        if (
            list_url
            and index is not None
            and index < self.headline_anchor_limit
            and self.is_headline_list_url(list_url)
        ):
            return True

        current: Tag | None = anchor
        depth = 0
        while current is not None and depth < 6:
            attributes = " ".join(
                str(value)
                for value in (
                    current.get("id", ""),
                    " ".join(current.get("class", [])),
                    current.get("role", ""),
                    current.get("aria-label", ""),
                    current.get("data-area", ""),
                    current.get("data-section", ""),
                )
                if value
            ).lower()
            if any(token in attributes for token in self.headline_container_tokens):
                return True
            parent = current.parent
            current = parent if isinstance(parent, Tag) else None
            depth += 1
        return False

    def is_headline_list_url(self, url: str) -> bool:
        return any(fragment in url for fragment in self.headline_list_url_fragments)

    @abstractmethod
    def parse_list(self, soup: BeautifulSoup, list_url: str | None = None) -> list[RawArticle]:
        raise NotImplementedError

    @abstractmethod
    def parse_content(self, soup: BeautifulSoup) -> str:
        raise NotImplementedError

    def parse_published_at(self, soup: BeautifulSoup) -> str | None:
        return None

    @staticmethod
    def clean_text(text: str) -> str:
        return " ".join(text.split())
