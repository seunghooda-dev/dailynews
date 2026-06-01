from __future__ import annotations

import unittest

from bs4 import BeautifulSoup

from dailynews_backend.crawlers.maeil import MaeilCrawler


class MaeilCrawlerTest(unittest.TestCase):
    def test_parse_list_ignores_news_category_urls(self) -> None:
        soup = BeautifulSoup(
            """
            <a href="/news/company">기업 카테고리 페이지</a>
            <a href="/news/bond">채권 카테고리 페이지</a>
            <a href="/news/stock/12062251">삼성전자 시총 2000조 돌파 관련 기사</a>
            """,
            "html.parser",
        )

        articles = MaeilCrawler().parse_list(soup, "https://www.mk.co.kr/news/stock/")

        self.assertEqual(len(articles), 1)
        self.assertEqual(
            articles[0].url,
            "https://www.mk.co.kr/news/stock/12062251",
        )


if __name__ == "__main__":
    unittest.main()
