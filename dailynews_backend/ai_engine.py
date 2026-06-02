from __future__ import annotations

import json
import re
import time
from typing import Any

import requests

from dailynews_backend.config import PipelineConfig
from dailynews_backend.models import RawArticle


class AIEngine:
    REQUIRED_KEYS = {"sector", "what_happened", "context", "implication"}
    SYSTEM_PROMPT = """\
당신은 여의도 대형 증권사의 리서치 센터장이다.
목표는 단순 기사 요약이 아니라 "이 기사가 오늘 한국 주식시장과 내 계좌에 어떤 실질적 영향을 주는가"를 구조화하는 것이다.

출력 규칙:
- 반드시 JSON object 하나만 반환한다. Markdown, 코드블록, 주석, 추가 설명은 금지한다.
- JSON key는 정확히 sector, what_happened, context, implication 네 개만 사용한다.
- 모든 값은 한국어 문자열이어야 하며 빈 문자열은 금지한다.
- 미사여구, 수식어, 일반론, "관심이 쏠린다" 같은 느슨한 문장은 제거한다.
- 기사에 없는 사실은 만들지 않는다. 추론은 기사에 제시된 팩트와 수치에서 이어지는 범위로 제한한다.
- what_happened와 context는 화면에서 하나의 "핵심 요약" 블록으로 합쳐진다. 두 필드가 따로 노는 문단이 아니라, 팩트 -> 원인/배경 -> 시장 의미로 자연스럽게 이어지도록 작성한다.
- 문체는 증권사 애널리스트가 상사에게 올리는 업무 보고서 톤으로 쓴다. 짧은 결론, 근거 수치, 배경, 투자 판단의 연결이 명확해야 한다.

분석 원칙:
- 기사 내부의 숫자, 퍼센트, 금액, 계약 규모, 실적, 가이던스, 주가/지수, 금리, 환율, 수급, 기간, 순위는 절대 생략하지 않는다.
- 단순 사실 나열을 금지한다. 원인 -> 전이 경로 -> 시장/종목 결과의 인과관계를 명시한다.
- sector는 "IT", "금융" 같은 큰 분류가 아니라 "HBM 메모리 공급망", "증권사 가상자산 수탁", "거시 매크로 금리"처럼 구체적인 테마로 쓴다.
- implication은 주가 방향 예측이 아니라 "시장 영향 및 체크포인트"로 쓴다. 한국 증시, 관련 섹터, 밸류체인 기업, 외국인/기관/개인 수급, 밸류에이션 리스크, 다음 확인 지표 중 기사와 연결되는 항목만 정리한다.
"""
    USER_INSTRUCTIONS = """\
아래 기사를 증권사 애널리스트 보고서 스타일로 구조화하라.

필드별 작성 규칙:
- sector: 기사가 다루는 구체적인 테마/산업군을 한 줄로 쓴다. 가능한 경우 기업명보다 투자 테마와 밸류체인을 우선한다.
- what_happened: 상사에게 먼저 보고할 결론 문장처럼 쓴다. 핵심 사건, 정량 팩트, 시장에서 확인된 의미를 2~3문장 안에 압축한다.
- context: what_happened 바로 뒤에 붙어도 어색하지 않게 쓴다. "시장 맥락상" 뒤에 이어질 수 있는 문장으로 작성하고, 과거 지표 대비 변화, 전방 산업 수요, 경쟁사/정책/매크로 변수 중 기사와 직접 연결되는 배경만 정리한다.
- implication: 주가가 오른다/내린다 같은 방향성 예측을 쓰지 않는다. 한국 시장에 생길 수혜/부담, 관련 밸류체인, 수급 변화, 리스크, 다음 확인 지표를 업무 보고용 체크포인트로 정리한다.

품질 기준:
- "좋을 것으로 보인다" 같은 결론만 쓰지 말고, 팩트가 배경을 거쳐 시장 의미로 이어지는 경로를 쓴다.
- 기사에 수치가 있으면 최소한 what_happened에는 핵심 수치를 포함한다.
- 기사에 직접 근거가 없는 기업명이나 숫자는 추가하지 않는다.
- what_happened와 context를 이어 붙였을 때 하나의 완성된 업무 보고 문단처럼 읽혀야 한다. 같은 제목, 같은 출처명, 같은 수치를 불필요하게 반복하지 않는다.
- context에 "OO에 올라온 기사입니다" 같은 출처 설명을 쓰지 않는다. 배경과 해석만 쓴다.
- implication에 목표가, 매수/매도 권유, 막연한 주가 전망을 쓰지 않는다. 투자 판단에 필요한 확인 항목만 남긴다.
- 최종 출력은 아래 JSON 스키마와 정확히 일치해야 한다.
{
  "sector": "구체적인 테마/산업군",
  "what_happened": "정량적 팩트 중심 분석",
  "context": "사건의 전후 맥락과 원인",
  "implication": "시장 영향 및 체크포인트"
}
"""
    QUANTITATIVE_PATTERN = re.compile(
        r"(?<![A-Za-z0-9])"
        r"(?:\d{1,3}(?:,\d{3})+|\d+)"
        r"(?:\.\d+)?"
        r"\s?"
        r"(?:%|％|조원|억원|만원|원|달러|엔|위안|유로|bp|bps|포인트|p|배|"
        r"명|개|건|대|주|위|년|월|일|분기|개월|거래일|조|억|만|천)?"
    )

    def __init__(self, config: PipelineConfig) -> None:
        self.config = config

    def summarize(self, article: RawArticle) -> dict[str, Any]:
        payload = self._build_payload(article)

        last_error: Exception | None = None
        for attempt in range(self.config.max_llm_retries):
            try:
                response = requests.post(
                    f"{self.config.llm_base_url.rstrip('/')}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.config.llm_api_key}",
                        "Content-Type": "application/json",
                    },
                    json=payload,
                    timeout=self.config.llm_timeout_seconds,
                )
                response.raise_for_status()
                content = response.json()["choices"][0]["message"]["content"]
                summary = json.loads(content)
                self._validate_summary(summary)
                return summary
            except (requests.RequestException, KeyError, ValueError, json.JSONDecodeError) as exc:
                last_error = exc
                if attempt == self.config.max_llm_retries - 1:
                    break
                time.sleep(min(2**attempt, 16))
        raise RuntimeError(f"LLM summarization failed for {article.url}: {last_error}")

    def _build_payload(self, article: RawArticle) -> dict[str, Any]:
        quantitative_markers = self._extract_quantitative_markers(article)
        marker_text = (
            ", ".join(quantitative_markers)
            if quantitative_markers
            else "기사 본문에서 명확한 숫자 후보가 감지되지 않음"
        )

        return {
            "model": self.config.llm_model,
            "response_format": {"type": "json_object"},
            "messages": [
                {
                    "role": "system",
                    "content": self.SYSTEM_PROMPT,
                },
                {
                    "role": "user",
                    "content": (
                        f"{self.USER_INSTRUCTIONS}\n\n"
                        f"기사에서 감지된 정량 후보(누락 검토용): {marker_text}\n\n"
                        f"{article.to_prompt_payload()}"
                    ),
                },
            ],
        }

    def _extract_quantitative_markers(self, article: RawArticle) -> list[str]:
        text = f"{article.title}\n{article.content or ''}"
        markers: list[str] = []
        seen: set[str] = set()
        for match in self.QUANTITATIVE_PATTERN.finditer(text):
            marker = " ".join(match.group(0).split())
            if not marker or marker in seen:
                continue
            seen.add(marker)
            markers.append(marker)
            if len(markers) >= 40:
                break
        return markers

    def _validate_summary(self, summary: dict[str, Any]) -> None:
        if not isinstance(summary, dict):
            raise ValueError("Structured output must be a JSON object.")
        missing = self.REQUIRED_KEYS.difference(summary)
        if missing:
            raise ValueError(f"Structured output is missing keys: {sorted(missing)}")
        extra = set(summary).difference(self.REQUIRED_KEYS)
        if extra:
            raise ValueError(f"Structured output has unexpected keys: {sorted(extra)}")
        invalid = [
            key
            for key in self.REQUIRED_KEYS
            if not isinstance(summary[key], str) or not summary[key].strip()
        ]
        if invalid:
            raise ValueError(f"Structured output has empty or non-string values: {sorted(invalid)}")
