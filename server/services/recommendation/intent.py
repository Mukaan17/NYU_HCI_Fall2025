# server/services/recommendation/intent.py

from __future__ import annotations
from typing import List, Dict, Any


# -----------------------------------------------------------
# INTENT CLASSIFICATION
# -----------------------------------------------------------

def classify_intent_llm(message: str, memory) -> str:
    """
    Improved intent classifier that better detects follow-up questions.
    Determines:
      - followup_place: User asking about a previously recommended place
      - followup_general: General follow-up question (what, how, why, etc.)
      - recommendation: New recommendation request
      - new_recommendation: Request for alternatives/more options
      - general_chat: Greetings, thanks, etc.
    """
    last_places = memory.last_places or []
    has_history = memory.history and len(memory.history) > 0
    msg = message.lower().strip()

    # 0. No history → fresh recommendation or general chat
    if not has_history and not last_places:
        if any(k in msg for k in ["hi", "hello", "hey", "thanks", "thank you"]):
            return "general_chat"
        return "recommendation"

    # 1. Alternative requests → new_recommendation
    alt_keywords = [
        "alternative", "similar", "something else", "other options",
        "other places", "another place", "else instead", "instead of",
        "different place", "different spot", "more options", "more places",
        "else to go", "give me alternatives", "show me more", "what else",
    ]
    if any(k in msg for k in alt_keywords):
        return "new_recommendation"

    # 1.5. Location/where questions → return recommendation cards for navigation
    location_keywords = [
        "where is", "where's", "where are", "location of", "location",
        "where can i find", "where to find", "show me where", "where is it",
        "where is that", "where are they", "directions to", "how to get to",
        "navigate to", "take me to", "go to"
    ]
    if any(k in msg for k in location_keywords):
        # If asking about location, return recommendations so user can navigate
        return "recommendation"
    
    # 2. Follow-up: user mentions a place shown earlier
    # More flexible - check if any place name appears in message
    detail_keywords = [
        "tell me", "what can you tell me", "info on", "information on",
        "what is", "what's", "vibe at", "vibe like", "how is", "how's",
        "details about", "can you describe", "about", "more about",
        "is it", "is that", "does it", "does that", "tell me about",
    ]
    
    # Check if message mentions any previous place
    for p in last_places:
        name = (p.get("name") or "").lower()
        if name:
            # Extract key words from place name (e.g., "Bern Dibner Library" -> ["bern", "dibner", "library"])
            name_words = [w for w in name.split() if len(w) > 3]  # Filter out short words like "the", "of"
            # Check if any significant word from place name appears in message
            if any(word in msg for word in name_words):
                # If asking about location specifically, return recommendations
                if any(k in msg for k in location_keywords):
                    return "recommendation"
                # If it's a question or detail request, it's a follow-up
                if any(k in msg for k in detail_keywords) or msg.endswith("?"):
                    return "followup_place"
                # Or if message is very short and mentions the place, likely a follow-up
                if len(msg.split()) <= 5:
                    return "followup_place"

    # 3. General follow-up questions (what, how, why, when, where)
    # These indicate the user is asking about something from previous context
    followup_question_words = ["what", "how", "why", "when", "where", "which", "who"]
    if has_history and any(msg.startswith(word) for word in followup_question_words):
        # If it's a short question, likely a follow-up
        if len(msg.split()) <= 8 or msg.endswith("?"):
            return "followup_general"

    # 4. General chat
    if any(k in msg for k in ["hi", "hello", "hey", "thanks", "thank you", "bye", "goodbye"]):
        return "general_chat"

    # 5. More / another (without "alternative" keyword)
    if any(k in msg for k in ["another", "more options", "more places", "show me more"]):
        return "new_recommendation"

    # 6. If there's history and message is short/question-like, treat as follow-up
    if has_history and (msg.endswith("?") or len(msg.split()) <= 4):
        return "followup_general"

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