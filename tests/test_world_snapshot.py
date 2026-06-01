from __future__ import annotations

import unittest

from dailynews_backend.world_snapshot import (
    TranslationClient,
    classify_world_sector,
    _strip_source_suffix,
)


class WorldSnapshotTest(unittest.TestCase):
    def test_ai_keyword_requires_word_boundary(self) -> None:
        self.assertEqual(
            classify_world_sector("EUR/USD currency pair moves as dollar rises"),
            "외환",
        )

    def test_ai_sector_detects_explicit_ai_theme(self) -> None:
        self.assertEqual(
            classify_world_sector("Nvidia and AI chips lift Nasdaq futures"),
            "AI",
        )

    def test_strip_source_suffix_removes_google_news_publisher_suffix(self) -> None:
        self.assertEqual(
            _strip_source_suffix("Oil prices rise today - Reuters", "Reuters"),
            "Oil prices rise today",
        )

    def test_translation_client_can_be_disabled(self) -> None:
        translator = TranslationClient(enabled=False)

        self.assertEqual(translator.to_korean("Global markets rise"), "Global markets rise")


if __name__ == "__main__":
    unittest.main()
