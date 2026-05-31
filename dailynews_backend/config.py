from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()


def _env_int(name: str, default: int, minimum: int = 1) -> int:
    raw_value = os.getenv(name)
    if raw_value is None or raw_value.strip() == "":
        return default
    try:
        value = int(raw_value)
    except ValueError as exc:
        raise ValueError(f"{name} must be an integer.") from exc
    if value < minimum:
        raise ValueError(f"{name} must be greater than or equal to {minimum}.")
    return value


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
        default_factory=lambda: _env_int("ARTICLE_LIMIT_PER_SOURCE", 8)
    )
    request_timeout_seconds: int = field(
        default_factory=lambda: _env_int("REQUEST_TIMEOUT_SECONDS", 20)
    )
    llm_timeout_seconds: int = field(
        default_factory=lambda: _env_int("LLM_TIMEOUT_SECONDS", 60)
    )
    max_llm_retries: int = field(default_factory=lambda: _env_int("MAX_LLM_RETRIES", 4))
    firestore_collection: str = "korea_economy_news"

    def validate(self) -> None:
        if not self.llm_api_key:
            raise ValueError("LLM_API_KEY is required.")
        if not Path(self.firebase_credentials_path).exists():
            raise FileNotFoundError(
                f"Firebase credential file not found: {self.firebase_credentials_path}"
            )
