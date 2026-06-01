from __future__ import annotations

import unittest

from dailynews_backend.ai_engine import AIEngine
from dailynews_backend.config import PipelineConfig
from dailynews_backend.models import RawArticle


class AIEngineTest(unittest.TestCase):
    def setUp(self) -> None:
        self.engine = AIEngine(
            PipelineConfig(
                llm_api_key="test-key",
                firebase_credentials_path="serviceAccountKey.json",
            )
        )

    def test_payload_enforces_deep_market_analysis_rules(self) -> None:
        article = RawArticle(
            title="삼성전자 2분기 영업이익 12조원 전망",
            url="https://example.com/news",
            source="테스트경제",
            published_at="2026-06-01",
            content=(
                "삼성전자 2분기 영업이익 컨센서스가 12조원으로 한 달 전보다 24% 상향됐다. "
                "HBM 공급 확대와 D램 가격 상승이 원인으로 제시됐다. "
                "외국인은 최근 5거래일 동안 반도체 업종을 3조원 순매수했다."
            ),
        )

        payload = self.engine._build_payload(article)
        messages = "\n".join(message["content"] for message in payload["messages"])

        self.assertEqual(payload["response_format"], {"type": "json_object"})
        self.assertIn("sector, what_happened, context, implication", messages)
        self.assertIn("인과관계", messages)
        self.assertIn("원인 -> 전이 경로 -> 시장/종목 결과", messages)
        self.assertIn("하나의 \"핵심 요약\" 블록", messages)
        self.assertIn("하나의 완성된 요약문", messages)
        self.assertIn("수혜 또는 타격", messages)
        self.assertIn("12조원", messages)
        self.assertIn("24%", messages)
        self.assertIn("5거래일", messages)
        self.assertIn("3조원", messages)

    def test_validate_summary_rejects_extra_keys(self) -> None:
        with self.assertRaisesRegex(ValueError, "unexpected keys"):
            self.engine._validate_summary(
                {
                    "sector": "HBM 메모리 공급망",
                    "what_happened": "영업이익 전망이 12조원으로 상향됐다.",
                    "context": "HBM 공급 확대가 배경이다.",
                    "implication": "반도체 밸류체인 수급에 긍정적이다.",
                    "extra": "not allowed",
                }
            )

    def test_validate_summary_rejects_non_object(self) -> None:
        with self.assertRaisesRegex(ValueError, "JSON object"):
            self.engine._validate_summary(["not", "an", "object"])  # type: ignore[arg-type]

    def test_validate_summary_rejects_empty_values(self) -> None:
        with self.assertRaisesRegex(ValueError, "empty or non-string"):
            self.engine._validate_summary(
                {
                    "sector": " ",
                    "what_happened": "영업이익 전망이 12조원으로 상향됐다.",
                    "context": "HBM 공급 확대가 배경이다.",
                    "implication": "반도체 밸류체인 수급에 긍정적이다.",
                }
            )


if __name__ == "__main__":
    unittest.main()
