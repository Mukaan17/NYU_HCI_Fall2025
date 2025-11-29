# services/recommendation/scoring.py
from __future__ import annotations
from typing import Dict, Any, List, Optional

import google.generativeai as genai

from services.directions_service import walking_minutes
from services.recommendation.embeddings import get_embedding, cosine_similarity
from services.recommendation.profile_boosts import apply_profile_boosts
from services.vibes import classify_vibe


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
        adjustment += (sim - 0.5) * 0.3  # mild boost

    return adjustment


# --------------------------------------------------------------
# NEW FINAL VERSION: embedding score + preference boosts
# --------------------------------------------------------------
def score_items_with_embeddings(
    query_text: str,
    items: List[Dict[str, Any]],
    profile: Optional[dict] = None,
) -> None:

    query_emb = get_embedding(query_text) if query_text else []
    vibe = classify_vibe(query_text)

    # -------------------------------
    # 1. Embedding-based scoring
    # -------------------------------
    for item in items:
        item_text = (
            (item.get("name") or "") + " "
            + (item.get("address") or "") + " "
            + (item.get("description") or "")
        )

        item_emb = get_embedding(item_text)
        sim_query = cosine_similarity(query_emb, item_emb)
        dist = _distance_score(item.get("walk_time"))
        semantic_adj = _semantic_tag_adjustment(item, vibe)

        score = (
            0.75 * sim_query +   # increased emphasis
            0.15 * dist +
            0.10 * semantic_adj
        )

        item["score"] = float(score)

    # -------------------------------
    # 2. Preference boosts
    # -------------------------------
    if profile:
        apply_profile_boosts(items, vibe, profile)
