from __future__ import annotations

from collections.abc import Iterable

from dailynews_backend.models import RawArticle


class ArticleFilter:
    """Runtime-configurable filtering without hardcoded market keywords."""

    def __init__(
        self,
        include_keywords: Iterable[str] | None = None,
        exclude_keywords: Iterable[str] | None = None,
        min_content_length: int = 120,
    ) -> None:
        self.include_keywords = [keyword.lower() for keyword in include_keywords or []]
        self.exclude_keywords = [keyword.lower() for keyword in exclude_keywords or []]
        self.min_content_length = min_content_length

    def allow(self, article: RawArticle) -> bool:
        haystack = f"{article.title}\n{article.content or ''}".lower()
        if article.content and len(article.content.strip()) < self.min_content_length:
            return False
        if self.include_keywords and not any(keyword in haystack for keyword in self.include_keywords):
            return False
        return not any(keyword in haystack for keyword in self.exclude_keywords)

    def apply(self, articles: Iterable[RawArticle]) -> list[RawArticle]:
        seen_urls: set[str] = set()
        filtered: list[RawArticle] = []
        for article in articles:
            if article.url in seen_urls or not self.allow(article):
                continue
            seen_urls.add(article.url)
            filtered.append(article)
        return filtered
