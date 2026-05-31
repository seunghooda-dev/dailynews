from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()


def _present(value: str | None) -> bool:
    return bool(value and value.strip())


def _mask(value: str | None) -> str:
    if not _present(value):
        return "missing"
    assert value is not None
    if len(value) <= 8:
        return "set"
    return f"{value[:4]}...{value[-4:]}"


def _load_json(value: str) -> tuple[dict[str, object] | None, str | None]:
    try:
        data = json.loads(value)
    except json.JSONDecodeError as exc:
        return None, f"invalid JSON: {exc}"
    if not isinstance(data, dict):
        return None, "JSON must be an object"
    return data, None


def _validate_service_account(data: dict[str, object]) -> list[str]:
    required = ("type", "project_id", "private_key", "client_email")
    missing = [key for key in required if not _present(str(data.get(key, "")))]
    errors: list[str] = []
    if missing:
        errors.append(f"missing fields: {', '.join(missing)}")
    if data.get("type") != "service_account":
        errors.append("type must be service_account")
    return errors


def _check_credentials_file(path_value: str) -> tuple[bool, str]:
    path = Path(path_value).expanduser()
    if not path.is_absolute():
        path = Path.cwd() / path
    if not path.exists():
        return False, f"missing file: {path}"
    data, error = _load_json(path.read_text(encoding="utf-8"))
    if error:
        return False, error
    assert data is not None
    errors = _validate_service_account(data)
    if errors:
        return False, "; ".join(errors)
    email = str(data.get("client_email", ""))
    return True, f"valid service account JSON ({email})"


def _check_credentials_json(value: str) -> tuple[bool, str]:
    data, error = _load_json(value)
    if error:
        return False, error
    assert data is not None
    errors = _validate_service_account(data)
    if errors:
        return False, "; ".join(errors)
    email = str(data.get("client_email", ""))
    return True, f"valid service account JSON ({email})"


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Dailynews environment variables.")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit with code 1 when required backend credentials are missing.",
    )
    args = parser.parse_args()

    failures: list[str] = []
    llm_key = os.getenv("LLM_API_KEY")
    print(f"LLM_API_KEY: {_mask(llm_key)}")
    if not _present(llm_key):
        failures.append("LLM_API_KEY is required for AI summaries.")

    print(f"LLM_MODEL: {os.getenv('LLM_MODEL', 'gpt-4o-mini')}")
    print(f"LLM_BASE_URL: {os.getenv('LLM_BASE_URL', 'https://api.openai.com/v1')}")

    credentials_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "serviceAccountKey.json")
    file_ok, file_message = _check_credentials_file(credentials_path)
    print(f"FIREBASE_CREDENTIALS_PATH: {file_message}")

    credentials_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
    if _present(credentials_json):
        json_ok, json_message = _check_credentials_json(credentials_json or "")
        print(f"FIREBASE_CREDENTIALS_JSON: {json_message}")
        if not json_ok:
            failures.append("FIREBASE_CREDENTIALS_JSON is invalid.")
    else:
        print("FIREBASE_CREDENTIALS_JSON: not set (needed only in GitHub Actions)")

    if not file_ok and not _present(credentials_json):
        failures.append("Firebase service account JSON is required for Firestore writes.")

    firebase_options = Path("lib/firebase_options.dart")
    if firebase_options.exists():
        print("Flutter Firebase client config: lib/firebase_options.dart found")
    else:
        print("Flutter Firebase client config: not configured (only needed with USE_FIREBASE=true)")

    if failures:
        print("\nMissing or invalid configuration:")
        for failure in failures:
            print(f"- {failure}")
        return 1 if args.strict else 0

    print("\nEnvironment check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
