from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from typing import Any


@dataclass(frozen=True)
class RawArticle:
    title: str
    url: str
    source: str
    published_at: str | None = None
    content: str | None = None
    is_headline: bool = False
    cluster_count: int = 1
    issue_keyword: str = ""

    def to_prompt_payload(self) -> str:
        content = self.content or ""
        return (
            f"source: {self.source}\n"
            f"title: {self.title}\n"
            f"url: {self.url}\n"
            f"published_at: {self.published_at or 'unknown'}\n\n"
            f"article_body:\n{content}"
        )


@dataclass(frozen=True)
class StructuredArticle:
    title: str
    url: str
    source: str
    sector: str
    what_happened: str
    context: str
    implication: str
    published_at: str | None = None
    collected_at: str = ""
    is_headline: bool = False
    cluster_count: int = 1
    issue_keyword: str = ""

    @classmethod
    def from_raw_and_summary(
        cls,
        raw: RawArticle,
        summary: dict[str, Any],
    ) -> "StructuredArticle":
        return cls(
            title=raw.title,
            url=raw.url,
            source=raw.source,
            published_at=raw.published_at,
            collected_at=datetime.now(timezone.utc).isoformat(),
            is_headline=raw.is_headline,
            cluster_count=raw.cluster_count,
            issue_keyword=raw.issue_keyword,
            sector=str(summary["sector"]),
            what_happened=str(summary["what_happened"]),
            context=str(summary["context"]),
            implication=str(summary["implication"]),
        )

    def to_firestore_map(self) -> dict[str, Any]:
        return asdict(self)
