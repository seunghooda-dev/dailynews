from __future__ import annotations

from bs4 import BeautifulSoup

from dailynews_backend.crawlers.base import BaseCrawler
from dailynews_backend.models import RawArticle


class MaeilCrawler(BaseCrawler):
    source_name = "매일경제"
    base_url = "https://www.mk.co.kr"
    list_urls = (
        "https://www.mk.co.kr/news/stock/",
        "https://stock.mk.co.kr/news",
        "https://stock.mk.co.kr/news/marketCondition",
    )

    def parse_list(self, soup: BeautifulSoup, list_url: str | None = None) -> list[RawArticle]:
        articles: list[RawArticle] = []
        for anchor in soup.select("a[href*='/news/'], a[href*='stock.mk.co.kr/news']"):
            title = self.clean_text(anchor.get_text(" ", strip=True))
            href = anchor.get("href")
            if len(title) >= 8 and href:
                article_index = len(articles)
                articles.append(
                    RawArticle(
                        title=title,
                        url=self.absolute_url(href),
                        source=self.source_name,
                        is_headline=self.is_headline_anchor(
                            anchor,
                            list_url,
                            article_index,
                        ),
                    )
                )
        return articles

    def parse_content(self, soup: BeautifulSoup) -> str:
        selectors = (
            ".news_cnt_detail_wrap",
            "#article_body",
            "div[itemprop='articleBody']",
            ".view_txt",
            ".art_txt",
        )
        for selector in selectors:
            body = soup.select_one(selector)
            if body:
                return self.clean_text(body.get_text(" ", strip=True))
        return self.clean_text(soup.get_text(" ", strip=True))

    def parse_published_at(self, soup: BeautifulSoup) -> str | None:
        node = soup.select_one("time, .time_area, .registration")
        return self.clean_text(node.get_text(" ", strip=True)) if node else None
