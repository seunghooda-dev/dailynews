from __future__ import annotations

import argparse
import json
from pathlib import Path

from dailynews_backend.ai_engine import AIEngine
from dailynews_backend.config import PipelineConfig
from dailynews_backend.crawlers import HankyungCrawler, MaeilCrawler, NaverFinanceCrawler
from dailynews_backend.filters import ArticleFilter
from dailynews_backend.firestore_client import FirestoreClient
from dailynews_backend.models import StructuredArticle


class NewsPipeline:
    def __init__(self, config: PipelineConfig, article_filter: ArticleFilter) -> None:
        self.config = config
        self.article_filter = article_filter
        self.crawlers = (
            NaverFinanceCrawler(config.request_timeout_seconds),
            MaeilCrawler(config.request_timeout_seconds),
            HankyungCrawler(config.request_timeout_seconds),
        )
        self.ai_engine = AIEngine(config)
        self.firestore = FirestoreClient(config)

    def run(self) -> int:
        raw_articles = []
        for crawler in self.crawlers:
            raw_articles.extend(crawler.crawl(limit=self.config.article_limit_per_source))

        candidates = self.article_filter.apply(raw_articles)
        structured_articles: list[StructuredArticle] = []
        for raw_article in candidates:
            summary = self.ai_engine.summarize(raw_article)
            structured_articles.append(StructuredArticle.from_raw_and_summary(raw_article, summary))

        self.firestore.upsert_daily_articles(structured_articles)
        return len(structured_articles)


def load_keywords(path: str | None) -> tuple[list[str], list[str]]:
    if not path:
        return [], []
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    return data.get("include_keywords", []), data.get("exclude_keywords", [])


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Collect and summarize Korean economy news.")
    parser.add_argument("--filter-config", help="JSON file with include_keywords/exclude_keywords.")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    config = PipelineConfig()
    config.validate()
    include_keywords, exclude_keywords = load_keywords(args.filter_config)
    article_filter = ArticleFilter(include_keywords, exclude_keywords)
    count = NewsPipeline(config, article_filter).run()
    print(f"Stored {count} structured articles.")
