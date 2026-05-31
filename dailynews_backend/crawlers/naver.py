from __future__ import annotations

from bs4 import BeautifulSoup

from dailynews_backend.crawlers.base import BaseCrawler
from dailynews_backend.models import RawArticle


class NaverFinanceCrawler(BaseCrawler):
    source_name = "네이버페이 증권"
    base_url = "https://finance.naver.com"
    list_urls = (
        "https://finance.naver.com/news/mainnews.naver",
        "https://finance.naver.com/news/news_list.naver?mode=LSS2D&section_id=101&section_id2=258",
    )

    def parse_list(self, soup: BeautifulSoup) -> list[RawArticle]:
        articles: list[RawArticle] = []
        for anchor in soup.select("dd.articleSubject a, li.newsList.top a, ul.newsList a"):
            title = self.clean_text(anchor.get_text(" ", strip=True))
            href = anchor.get("href")
            if title and href:
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
            "#dic_area",
            "#newsct_article",
            "._article_content",
            "#news_read",
            "#content",
            "div.articleCont",
            "div#articeBody",
        )
        for selector in selectors:
            body = soup.select_one(selector)
            if body:
                return self.clean_text(body.get_text(" ", strip=True))
        return self.clean_text(soup.get_text(" ", strip=True))

    def fetch_article(self, article: RawArticle) -> RawArticle:
        soup = self._get_soup(article.url)
        return RawArticle(
            title=article.title,
            url=article.url,
            source=self.parse_source(soup) or article.source,
            published_at=article.published_at or self.parse_published_at(soup),
            content=self.parse_content(soup),
        )

    def parse_published_at(self, soup: BeautifulSoup) -> str | None:
        node = soup.select_one(
            ".article_info .wdate, span.wdate, .media_end_head_info_datestamp_time, ._ARTICLE_DATE_TIME"
        )
        return self.clean_text(node.get_text(" ", strip=True)) if node else None

    def parse_source(self, soup: BeautifulSoup) -> str | None:
        logo = soup.select_one(".media_end_head_top_logo img")
        if logo and logo.get("alt"):
            return self.clean_text(logo["alt"])
        meta = soup.select_one("meta[property='og:article:author'], meta[name='twitter:creator']")
        if meta and meta.get("content"):
            return self.clean_text(meta["content"].replace("| 네이버", ""))
        return None
