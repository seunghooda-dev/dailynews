from __future__ import annotations

import re
from collections import Counter, defaultdict
from dataclasses import replace
from difflib import SequenceMatcher
from typing import Iterable

from dailynews_backend.models import RawArticle

STOPWORDS = {
    "단독",
    "속보",
    "종합",
    "기자",
    "뉴스",
    "증시",
    "국내",
    "해외",
    "시장",
    "주식",
    "투자",
    "관련",
    "오늘",
    "내일",
    "올해",
    "지난",
    "이번",
    "이후",
    "전망",
    "분석",
    "마켓",
    "시그널",
    "서학",
    "망원경",
    "경제",
    "코스피",
    "코스닥",
    "반도체",
    "금융",
}


def enrich_article_importance(articles: Iterable[RawArticle]) -> list[RawArticle]:
    article_list = list(articles)
    if not article_list:
        return []

    tokens_by_index = [_title_tokens(article.title) for article in article_list]
    normalized_titles = [_normalize_title(article.title) for article in article_list]
    parent = list(range(len(article_list)))

    def find(index: int) -> int:
        while parent[index] != index:
            parent[index] = parent[parent[index]]
            index = parent[index]
        return index

    def union(left: int, right: int) -> None:
        left_root = find(left)
        right_root = find(right)
        if left_root != right_root:
            parent[right_root] = left_root

    for left in range(len(article_list)):
        for right in range(left + 1, len(article_list)):
            if _is_same_issue(
                normalized_titles[left],
                normalized_titles[right],
                tokens_by_index[left],
                tokens_by_index[right],
            ):
                union(left, right)

    groups: dict[int, list[int]] = defaultdict(list)
    for index in range(len(article_list)):
        groups[find(index)].append(index)

    enriched = list(article_list)
    for indices in groups.values():
        sources = {article_list[index].source for index in indices}
        if len(indices) >= 3 and len(sources) >= 3:
            issue_keyword = _issue_keyword([tokens_by_index[index] for index in indices])
            cluster_count = len(indices)
            for index in indices:
                enriched[index] = replace(
                    enriched[index],
                    cluster_count=cluster_count,
                    issue_keyword=issue_keyword,
                )
        else:
            for index in indices:
                enriched[index] = replace(
                    enriched[index],
                    cluster_count=1,
                    issue_keyword="",
                )
    return enriched


def _normalize_title(title: str) -> str:
    text = re.sub(r"\[[^\]]+\]|\([^)]*\)", " ", title)
    text = re.sub(r"[\"'‘’“”·…:;,.!?/\\|~]", " ", text)
    return " ".join(text.lower().split())


def _title_tokens(title: str) -> set[str]:
    normalized = _normalize_title(title)
    tokens = {
        token
        for token in re.findall(r"[가-힣A-Za-z0-9]+", normalized)
        if len(token) >= 2 and token not in STOPWORDS
    }
    return tokens


def _is_same_issue(
    left_title: str,
    right_title: str,
    left_tokens: set[str],
    right_tokens: set[str],
) -> bool:
    common_tokens = left_tokens & right_tokens
    if not common_tokens:
        return False

    sequence_ratio = SequenceMatcher(None, left_title, right_title).ratio()
    union_count = len(left_tokens | right_tokens)
    jaccard = len(common_tokens) / union_count if union_count else 0
    has_specific_overlap = any(_is_specific_token(token) for token in common_tokens)

    return (
        sequence_ratio >= 0.58
        or (len(common_tokens) >= 2 and jaccard >= 0.24)
        or (has_specific_overlap and jaccard >= 0.18)
    )


def _is_specific_token(token: str) -> bool:
    return bool(re.search(r"\d", token)) or len(token) >= 4


def _issue_keyword(token_groups: Iterable[set[str]]) -> str:
    counter: Counter[str] = Counter()
    for tokens in token_groups:
        counter.update(tokens)

    candidates = [
        token
        for token, _ in counter.most_common()
        if token not in STOPWORDS and _is_specific_token(token)
    ]
    if not candidates:
        candidates = [token for token, _ in counter.most_common() if token not in STOPWORDS]
    return " ".join(candidates[:2]) if candidates else "공통 이슈"
