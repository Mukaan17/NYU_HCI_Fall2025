# server/services/recommendation/intent.py

from __future__ import annotations
from typing import List, Dict, Any


# -----------------------------------------------------------
# INTENT CLASSIFICATION
# -----------------------------------------------------------

def classify_intent_llm(message: str, memory) -> str:
    """
    Lightweight rule-based classifier.
    Determines:
      - followup_place
      - recommendation
      - new_recommendation
      - general_chat
    """
    last_places = memory.last_places or []
    msg = message.lower().strip()

    # 0. No history → fresh recommendation or general chat
    if not last_places:
        if any(k in msg for k in ["hi", "hello", "thanks", "thank you"]):
            return "general_chat"
        return "recommendation"

    # 1. Alternative requests → new_recommendation
    alt_keywords = [
        "alternative", "similar", "something else", "other options",
        "other places", "another place", "else instead", "instead of",
        "different place", "different spot", "more options", "more places",
        "else to go", "give me alternatives",
    ]
    if any(k in msg for k in alt_keywords):
        return "new_recommendation"

    # 2. Follow-up: user mentions a place shown earlier
    detail_keywords = [
        "tell me", "what can you tell me", "info on", "information on",
        "what is", "what's", "vibe at", "vibe like", "how is",
        "details about", "can you describe",
    ]

    for p in last_places:
        name = (p.get("name") or "").lower()
        if name and name in msg and any(k in msg for k in detail_keywords):
            return "followup_place"

    # 3. General chat
    if any(k in msg for k in ["hi", "hello", "thanks", "thank you"]):
        return "general_chat"

    # 4. More / another
    if any(k in msg for k in ["another", "more options", "more places"]):
        return "new_recommendation"

    return "recommendation"


# -----------------------------------------------------------
# CAMPUS QUERY DETECTION
# -----------------------------------------------------------

def is_on_campus_query(message: str) -> bool:
    """
    Detect if the user explicitly asks for ON-CAMPUS EVENTS ONLY.
    (This is used ONLY when user explicitly restricts search to campus.)
    """
    msg = message.lower()

    keywords = [
        "on campus",
        "on-campus",
        "at tandon",
        "tandon",
        "in makerspace",
        "makerspace",
        "maker space",
        "5 mtc",
        "6 mtc",
        "metrotech",
        "metro tech",
        "inside campus",
        "campus events",
        "events on campus",
    ]

    return any(k in msg for k in keywords)