from __future__ import annotations

import argparse
import json
import re
from datetime import datetime
from pathlib import Path
from typing import Iterable

from dailynews_backend.crawlers import HankyungCrawler, MaeilCrawler, NaverFinanceCrawler
from dailynews_backend.importance import enrich_article_importance, select_representative_articles
from dailynews_backend.models import RawArticle, StructuredArticle


def collect_articles(limit: int, target_date: str | None) -> list[RawArticle]:
    naver = NaverFinanceCrawler(15)
    naver.list_urls = tuple(
        [
            f"https://finance.naver.com/news/mainnews.naver?page={page}"
            for page in range(1, 21)
        ]
        + [
            "https://finance.naver.com/news/news_list.naver"
            f"?mode=LSS2D&section_id=101&section_id2=258&page={page}"
            for page in range(1, 16)
        ]
    )
    crawlers = [
        naver,
        MaeilCrawler(15),
        HankyungCrawler(15),
    ]

    articles: list[RawArticle] = []
    seen_urls: set[str] = set()
    base_limit = max(1, limit // len(crawlers))
    extra_slots = limit % len(crawlers)
    for crawler_index, crawler in enumerate(crawlers):
        crawler_limit = base_limit + (1 if crawler_index < extra_slots else 0)
        crawler_count = 0
        for list_url in crawler.list_urls:
            if crawler_count >= crawler_limit:
                break
            try:
                soup = crawler._get_soup(list_url)
                candidates = crawler.parse_list(soup, list_url)
            except Exception as exc:
                print(f"skip list {list_url}: {exc}")
                continue
            for candidate in candidates:
                if crawler_count >= crawler_limit:
                    break
                clean_url = candidate.url.split("#", 1)[0]
                if clean_url in seen_urls:
                    continue
                seen_urls.add(clean_url)
                try:
                    article = crawler.fetch_article(candidate)
                except Exception as exc:
                    print(f"skip article {candidate.url}: {exc}")
                    continue
                if (
                    article.content
                    and len(article.content.strip()) >= 220
                    and is_target_date(article, target_date)
                ):
                    articles.append(article)
                    crawler_count += 1
    return articles


def build_snapshot(articles: Iterable[RawArticle], target_date: str) -> dict[str, object]:
    representative_articles = select_representative_articles(
        enrich_article_importance(articles)
    )
    structured = [structure_locally(article) for article in representative_articles]
    return {
        "date": target_date,
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "articles": [article.to_firestore_map() for article in structured],
    }


def is_target_date(article: RawArticle, target_date: str | None) -> bool:
    if not target_date:
        return True

    compact = target_date.replace("-", "")
    dotted = target_date.replace("-", ".")
    slashed = target_date.replace("-", "/")
    haystack = f"{article.published_at or ''} {article.url}"

    return (
        target_date in haystack
        or compact in haystack
        or dotted in haystack
        or slashed in haystack
    )


def structure_locally(article: RawArticle) -> StructuredArticle:
    content = article.content or ""
    sector = classify_sector(f"{article.title} {content}")
    return StructuredArticle(
        title=article.title,
        url=article.url,
        source=article.source,
        published_at=article.published_at,
        collected_at=datetime.now().isoformat(timespec="seconds"),
        is_headline=article.is_headline,
        cluster_count=article.cluster_count,
        issue_keyword=article.issue_keyword,
        related_sources=article.related_sources,
        sector=sector,
        what_happened=extract_summary(content, 0),
        context=extract_summary(content, 1),
        implication=build_implication(sector),
    )


def classify_sector(text: str) -> str:
    rules = [
        ("반도체", ("삼성전자", "SK하이닉스", "반도체", "HBM", "메모리", "마이크론")),
        ("AI", ("AI", "인공지능", "데이터센터", "서버", "엔비디아", "GPU")),
        ("금융", ("은행", "보험", "증권", "금리", "채권", "생명", "금융")),
        ("가상자산", ("비트코인", "코인", "가상자산", "암호화폐")),
        ("전력", ("전력", "변압기", "전력기기", "ESS", "원전")),
        ("자동차", ("현대차", "기아", "전기차", "자동차")),
        ("바이오", ("바이오", "제약", "신약", "임상")),
        ("중국", ("중국", "커촹반", "양쯔", "창신", "CXMT", "YMTC")),
        ("우주", ("스페이스X", "스타링크", "우주", "위성")),
        ("수출", ("수출", "무역", "관세", "통상")),
    ]
    for sector, keywords in rules:
        if any(keyword.lower() in text.lower() for keyword in keywords):
            return sector
    return "시장"


def extract_summary(content: str, offset: int) -> str:
    cleaned = " ".join(content.split())
    sentences = [
        sentence.strip()
        for sentence in re.split(r"(?<=[.!?。])\s+|(?<=다\.)\s+", cleaned)
        if len(sentence.strip()) > 20
    ]
    start = offset * 2
    selected = sentences[start : start + 2]
    if selected:
        return " ".join(selected)[:420]
    return cleaned[offset * 280 : (offset + 1) * 280] or cleaned[:280]


def build_implication(sector: str) -> str:
    implications = {
        "반도체": "국내 증시 영향은 삼성전자, SK하이닉스, 장비·소재 공급망으로 집중될 가능성이 큽니다. 단기 쏠림이 강하면 이벤트 이후 변동성 관리가 필요합니다.",
        "AI": "AI 인프라 투자는 반도체, 서버, 전력장비, 데이터센터 밸류체인에 우호적입니다. 수주와 실적 전환 여부가 주가 지속성을 가릅니다.",
        "금융": "금리와 자본정책 변화가 금융주 밸류에이션에 직접 영향을 줄 수 있습니다. 보험·증권은 인수합병과 시장 거래대금 변화를 함께 봐야 합니다.",
        "가상자산": "위험자산 선호와 거래대금 변화가 관련 플랫폼 기업의 실적 기대를 좌우합니다. 주식시장으로 유동성이 이동하면 단기 모멘텀은 약해질 수 있습니다.",
        "전력": "AI 데이터센터와 전력망 투자는 전력기기, 변압기, ESS, 원전 관련 기업에 구조적 수요를 만들 수 있습니다.",
        "자동차": "완성차와 부품주는 수출, 환율, 전기차 수요, 로봇·자율주행 투자 기대가 동시에 작용합니다.",
        "바이오": "임상 결과, 기술이전, 실적 가시성이 밸류에이션을 좌우합니다. 개별 이벤트 의존도가 높아 분산 접근이 필요합니다.",
        "중국": "중국의 자본시장 조달과 국산화 정책은 한국 공급망에 중장기 경쟁 압력입니다. 기술 격차와 고객 다변화가 핵심입니다.",
        "우주": "대형 우주기업 이벤트는 국내 위성, 통신, 방산 테마의 투자심리에 영향을 줄 수 있습니다. 실적 연결성은 개별 기업별 확인이 필요합니다.",
        "수출": "수출 호조는 반도체, 전력기기, 조선 등 주도 업종에 긍정적입니다. 업종별 회복 강도 차이가 커 선별이 필요합니다.",
    }
    return implications.get(
        sector,
        "시장 전반의 유동성, 실적 전망, 정책 변수에 따라 관련 종목별 차별화가 나타날 수 있습니다. 기사별 수치와 기업 노출도를 함께 확인해야 합니다.",
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Create a local news snapshot for Flutter web.")
    parser.add_argument("--limit", type=int, default=80)
    parser.add_argument("--output", default="web/news_snapshot.json")
    parser.add_argument(
        "--date",
        default=datetime.now().strftime("%Y-%m-%d"),
        help="Keep only articles matching this date. Format: YYYY-MM-DD.",
    )
    args = parser.parse_args()

    articles = collect_articles(args.limit, args.date)
    snapshot = build_snapshot(articles, args.date)
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(snapshot, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"wrote {len(snapshot['articles'])} articles to {output_path}")


if __name__ == "__main__":
    main()
