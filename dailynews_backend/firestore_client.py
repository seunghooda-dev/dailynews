from __future__ import annotations

from datetime import datetime
from pathlib import Path
from typing import Iterable

import firebase_admin
from firebase_admin import credentials, firestore

from dailynews_backend.config import PipelineConfig
from dailynews_backend.models import StructuredArticle


class FirestoreClient:
    def __init__(self, config: PipelineConfig) -> None:
        self.config = config
        if not firebase_admin._apps:
            cred = credentials.Certificate(str(Path(config.firebase_credentials_path)))
            firebase_admin.initialize_app(cred)
        self.db = firestore.client()

    def upsert_daily_articles(
        self,
        articles: Iterable[StructuredArticle],
        date_id: str | None = None,
    ) -> None:
        doc_id = date_id or datetime.now().strftime("%Y-%m-%d")
        doc_ref = self.db.collection(self.config.firestore_collection).document(doc_id)
        incoming = [article.to_firestore_map() for article in articles]
        if not incoming:
            return

        @firestore.transactional
        def update_in_transaction(transaction: firestore.Transaction) -> None:
            snapshot = doc_ref.get(transaction=transaction)
            current = snapshot.to_dict() if snapshot.exists else {}
            existing_articles = current.get("articles", [])
            existing_urls = {item.get("url") for item in existing_articles}
            merged_articles = existing_articles + [
                item for item in incoming if item.get("url") not in existing_urls
            ]
            transaction.set(
                doc_ref,
                {
                    "date": doc_id,
                    "updated_at": firestore.SERVER_TIMESTAMP,
                    "articles": merged_articles,
                },
                merge=True,
            )

        update_in_transaction(self.db.transaction())
