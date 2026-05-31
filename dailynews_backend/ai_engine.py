from __future__ import annotations

import json
import time
from typing import Any

import requests

from dailynews_backend.config import PipelineConfig
from dailynews_backend.models import RawArticle


class AIEngine:
    REQUIRED_KEYS = {"sector", "what_happened", "context", "implication"}

    def __init__(self, config: PipelineConfig) -> None:
        self.config = config

    def summarize(self, article: RawArticle) -> dict[str, Any]:
        payload = {
            "model": self.config.llm_model,
            "response_format": {"type": "json_object"},
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are a Korean equity market analyst. Return only a JSON object "
                        "with exactly these keys: sector, what_happened, context, implication. "
                        "Write in Korean, preserve quantitative figures, and do not invent facts."
                    ),
                },
                {
                    "role": "user",
                    "content": (
                        "아래 한국 경제/증권 기사를 구조화해 주세요. JSON 스키마를 엄격히 지키세요.\n\n"
                        f"{article.to_prompt_payload()}"
                    ),
                },
            ],
        }

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

    def _validate_summary(self, summary: dict[str, Any]) -> None:
        missing = self.REQUIRED_KEYS.difference(summary)
        if missing:
            raise ValueError(f"Structured output is missing keys: {sorted(missing)}")
