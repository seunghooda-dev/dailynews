from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()


@dataclass(frozen=True)
class PipelineConfig:
    llm_api_key: str = field(default_factory=lambda: os.getenv("LLM_API_KEY", ""))
    llm_base_url: str = field(
        default_factory=lambda: os.getenv("LLM_BASE_URL", "https://api.openai.com/v1")
    )
    llm_model: str = field(default_factory=lambda: os.getenv("LLM_MODEL", "gpt-4o-mini"))
    firebase_credentials_path: str = field(
        default_factory=lambda: os.getenv(
            "FIREBASE_CREDENTIALS_PATH",
            str(Path("serviceAccountKey.json").resolve()),
        )
    )
    article_limit_per_source: int = field(
        default_factory=lambda: int(os.getenv("ARTICLE_LIMIT_PER_SOURCE", "8"))
    )
    request_timeout_seconds: int = field(
        default_factory=lambda: int(os.getenv("REQUEST_TIMEOUT_SECONDS", "20"))
    )
    llm_timeout_seconds: int = field(
        default_factory=lambda: int(os.getenv("LLM_TIMEOUT_SECONDS", "60"))
    )
    max_llm_retries: int = field(default_factory=lambda: int(os.getenv("MAX_LLM_RETRIES", "4")))
    firestore_collection: str = "korea_economy_news"

    def validate(self) -> None:
        if not self.llm_api_key:
            raise ValueError("LLM_API_KEY is required.")
        if not Path(self.firebase_credentials_path).exists():
            raise FileNotFoundError(
                f"Firebase credential file not found: {self.firebase_credentials_path}"
            )
