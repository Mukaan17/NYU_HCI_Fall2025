# services/recommendation/scoring.py

from __future__ import annotations
from typing import Dict, Any, List, Optional
import math

import google.generativeai as genai

from services.directions_service import walking_minutes
from services.recommendation.embeddings import get_embedding, cosine_similarity


def _distance_score(walk_time: Optional[str]) -> float:
    if not walk_time:
        return 0.5
    mins = walking_minutes(walk_time)
    if mins is None:
        return 0.5
    return max(0.0, min(1.0, 1.0 - (mins / 30.0)))


def _semantic_tag_adjustment(item, vibe_text):
    """Adjust score based on semantic meaning, not hardcoding."""
    if not vibe_text:
        return 0.0

    vibe_emb = get_embedding(vibe_text)
    if not vibe_emb:
        return 0.0

    adjustment = 0.0
    name = (item.get("name") or "").lower()

    # auto-detected tags
    tags = []
    if "cafe" in name or "coffee" in name or "espresso" in name:
        tags.append("coffee shop")
    if "library" in name:
        tags.append("library")
    if "bar" in name:
        tags.append("bar")
    if "club" in name:
        tags.append("nightclub")

    for tag in tags:
        tag_emb = get_embedding(tag)
        if not tag_emb:
            continue

        sim = cosine_similarity(vibe_emb, tag_emb)
        # + for good match, - for mismatch
        adjustment += (sim - 0.5) * 0.3  # mild but effective

    return adjustment


def score_items_with_embeddings(
    query_text: str,
    items: List[Dict[str, Any]],
    user_profile_text: Optional[str] = None,
    vibe_text: Optional[str] = None,
) -> None:

    query_emb = get_embedding(query_text) if query_text else []
    profile_emb = get_embedding(user_profile_text) if user_profile_text else []

    for item in items:
        item_text = (
            (item.get("name") or "") + " "
            + (item.get("address") or "") + " "
            + (item.get("description") or "")
        )

        item_emb = get_embedding(item_text)

        sim_query = cosine_similarity(query_emb, item_emb)
        sim_profile = cosine_similarity(profile_emb, item_emb)
        dist = _distance_score(item.get("walk_time"))

        semantic_adj = _semantic_tag_adjustment(item, vibe_text)

        score = (
            0.65 * sim_query +
            0.20 * sim_profile +
            0.10 * dist +
            0.05 * semantic_adj
        )

        item["score"] = float(score)
