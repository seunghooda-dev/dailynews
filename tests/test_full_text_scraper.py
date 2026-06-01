from __future__ import annotations

import unittest

from dailynews_backend.full_text_scraper import (
    FullTextArticle,
    FullTextScraper,
    _normalize_url,
    _source_from_url,
)


class RoutingScraper(FullTextScraper):
    def __init__(self) -> None:
        super().__init__(user_agents=("test-agent",))
        self.calls: list[tuple[str, str]] = []

    def _resolve_google_news_url(self, url: str) -> str:
        self.calls.append(("resolve_google", url))
        return "https://finance.yahoo.com/news/example-article.html"

    def _scrape_yahoo_finance(self, url: str) -> FullTextArticle:
        self.calls.append(("scrape_yahoo", url))
        return FullTextArticle(
            url=url,
            title="Yahoo title",
            source="Yahoo Finance",
            full_text="Yahoo full text",
        )

    def _scrape_generic_article(self, url: str) -> FullTextArticle:
        self.calls.append(("scrape_generic", url))
        return FullTextArticle(
            url=url,
            title="Generic title",
            source="Reuters",
            full_text="Generic full text",
        )


class FullTextScraperTest(unittest.TestCase):
    def test_google_news_url_resolves_before_routing_to_yahoo(self) -> None:
        scraper = RoutingScraper()

        result = scraper.scrape("https://news.google.com/rss/articles/abc")

        self.assertEqual(result["source"], "Yahoo Finance")
        self.assertEqual(
            scraper.calls,
            [
                ("resolve_google", "https://news.google.com/rss/articles/abc"),
                ("scrape_yahoo", "https://finance.yahoo.com/news/example-article.html"),
            ],
        )

    def test_yahoo_finance_url_routes_to_browser_scraper(self) -> None:
        scraper = RoutingScraper()

        result = scraper.scrape("https://finance.yahoo.com/news/example.html")

        self.assertEqual(result["title"], "Yahoo title")
        self.assertEqual(
            scraper.calls,
            [("scrape_yahoo", "https://finance.yahoo.com/news/example.html")],
        )

    def test_generic_url_routes_to_newspaper_scraper(self) -> None:
        scraper = RoutingScraper()

        result = scraper.scrape("https://www.reuters.com/markets/example/")

        self.assertEqual(result["source"], "Reuters")
        self.assertEqual(
            scraper.calls,
            [("scrape_generic", "https://www.reuters.com/markets/example/")],
        )

    def test_normalize_url_adds_https_scheme(self) -> None:
        self.assertEqual(
            _normalize_url("finance.yahoo.com/news/example.html"),
            "https://finance.yahoo.com/news/example.html",
        )

    def test_source_from_url_uses_domain_label(self) -> None:
        self.assertEqual(_source_from_url("https://www.reuters.com/world/"), "Reuters")


if __name__ == "__main__":
    unittest.main()
