from __future__ import annotations

import unittest

from bs4 import BeautifulSoup

from dailynews_backend.crawlers.base import BaseCrawler
from dailynews_backend.importance import enrich_article_importance
from dailynews_backend.models import RawArticle


class DummyCrawler(BaseCrawler):
    source_name = "테스트"
    base_url = "https://example.com"
    list_urls = ()
    headline_list_url_fragments = ("https://example.com/main",)

    def parse_list(self, soup: BeautifulSoup, list_url: str | None = None) -> list[RawArticle]:
        return []

    def parse_content(self, soup: BeautifulSoup) -> str:
        return ""


class ImportanceTest(unittest.TestCase):
    def test_headline_anchor_detects_main_container(self) -> None:
        soup = BeautifulSoup(
            "<section class='top headline'><a href='/a'>삼성전자 실적 전망</a></section>",
            "html.parser",
        )
        anchor = soup.select_one("a")
        assert anchor is not None

        self.assertTrue(DummyCrawler().is_headline_anchor(anchor))

    def test_headline_anchor_detects_first_items_on_headline_url(self) -> None:
        soup = BeautifulSoup("<ul><li><a href='/a'>첫 기사</a></li></ul>", "html.parser")
        anchor = soup.select_one("a")
        assert anchor is not None

        self.assertTrue(
            DummyCrawler().is_headline_anchor(anchor, "https://example.com/main", 0)
        )

    def test_cluster_requires_three_distinct_sources(self) -> None:
        articles = [
            RawArticle("삼성전자 HBM 공급 확대 기대", "https://a.test/1", "A"),
            RawArticle("삼성전자 HBM 공급망 수혜 전망", "https://b.test/1", "B"),
            RawArticle("삼성전자 HBM 공급 확대에 장비주 강세", "https://c.test/1", "C"),
            RawArticle("금값 반등에 투자자 엇갈려", "https://d.test/1", "D"),
        ]

        enriched = enrich_article_importance(articles)

        clustered = [article for article in enriched if "HBM" in article.title]
        self.assertEqual({article.cluster_count for article in clustered}, {3})
        self.assertTrue(all(article.issue_keyword for article in clustered))
        self.assertEqual(enriched[-1].cluster_count, 1)
        self.assertEqual(enriched[-1].issue_keyword, "")

    def test_cluster_does_not_promote_two_source_issue(self) -> None:
        articles = [
            RawArticle("삼성전자 HBM 공급 확대 기대", "https://a.test/1", "A"),
            RawArticle("삼성전자 HBM 공급망 수혜 전망", "https://b.test/1", "B"),
        ]

        enriched = enrich_article_importance(articles)

        self.assertEqual([article.cluster_count for article in enriched], [1, 1])


if __name__ == "__main__":
    unittest.main()
