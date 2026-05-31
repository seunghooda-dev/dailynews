from __future__ import annotations

from bs4 import BeautifulSoup

from dailynews_backend.crawlers.base import BaseCrawler
from dailynews_backend.models import RawArticle


class HankyungCrawler(BaseCrawler):
    source_name = "한국경제"
    base_url = "https://www.hankyung.com"
    list_urls = (
        "https://www.hankyung.com/koreamarket/news/all-news",
        "https://www.hankyung.com/koreamarket/news/markets",
        "https://www.hankyung.com/koreamarket/news/equities",
    )

    def parse_list(self, soup: BeautifulSoup) -> list[RawArticle]:
        articles: list[RawArticle] = []
        for anchor in soup.select("a[href*='hankyung.com/article'], a[href^='/article']"):
            title = self.clean_text(anchor.get_text(" ", strip=True))
            href = anchor.get("href")
            if len(title) >= 8 and href:
                articles.append(
                    RawArticle(
                        title=title,
                        url=self.absolute_url(href),
                        source=self.source_name,
                    )
                )
        return articles

    def parse_content(self, soup: BeautifulSoup) -> str:
        selectors = (
            "#articletxt",
            ".article-body",
            "div.article-body-wrap",
            "div[itemprop='articleBody']",
        )
        for selector in selectors:
            body = soup.select_one(selector)
            if body:
                return self.clean_text(body.get_text(" ", strip=True))
        return self.clean_text(soup.get_text(" ", strip=True))

    def parse_published_at(self, soup: BeautifulSoup) -> str | None:
        node = soup.select_one("time, .txt-date, .article-info .date")
        return self.clean_text(node.get_text(" ", strip=True)) if node else None
