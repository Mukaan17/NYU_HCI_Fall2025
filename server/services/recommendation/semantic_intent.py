# server/services/recommendation/semantic_intent.py

from __future__ import annotations
from typing import Dict, Any, Optional
import json
import re

import google.generativeai as genai


def _extract_group_size_fallback(message: str) -> Optional[int]:
    """
    Simple fallback: extract '4 people', 'group of 3', etc. without LLM.
    """
    msg = message.lower()
    m = re.search(r"\b(\d+)\s*(people|friends|of us|guys|girls)?\b", msg)
    if m:
        try:
            return int(m.group(1))
        except ValueError:
            return None
    return None


def _parse_llm_json(text: str) -> Optional[Dict[str, Any]]:
    """
    Extract a JSON object from LLM text. Handles cases where the model
    wraps JSON in markdown fences.
    """
    if not text:
        return None

    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end <= start:
        return None

    try:
        return json.loads(text[start:end + 1])
    except Exception:
        return None


def extract_semantic_intent(message: str) -> Dict[str, Any]:
    """
    Use Gemini Flash to extract a structured semantic intent for the user query.

    Returns a dict like:
    {
      "intent_type": "study" | "coffee" | "eat" | "nightlife" | "events" | "other",
      "normalized_query": "quiet cafe or library good for studying with 4 people",
      "group_size": 4 or null,
      "vibes": ["quiet", "chill"],
      "indoor_outdoor": "indoor" | "outdoor" | "either"
    }

    On failure, returns a safe fallback structure.
    """
    message = (message or "").strip()
    if not message:
        return {
            "intent_type": "other",
            "normalized_query": "",
            "group_size": None,
            "vibes": [],
            "indoor_outdoor": "either",
        }

    prompt = f"""
You are a semantic parser for a student concierge app called VioletVibes.

Your job is to analyze the user's request and output a SHORT JSON object
with these keys:

- "intent_type": one of ["study", "coffee", "eat", "nightlife", "events", "outdoors", "date", "other"]
- "normalized_query": a short natural language reformulation of the request
   that would work well as a search query for places and events.
- "group_size": integer number of people if specified, otherwise null.
- "vibes": a list of adjectives like ["quiet", "chill", "lively", "cozy"].
- "indoor_outdoor": "indoor", "outdoor", or "either".

User request:
\"\"\"{message}\"\"\"


Now respond with ONLY a JSON object and nothing else.
"""

    # Default fallback (used if LLM fails)
    fallback = {
        "intent_type": "other",
        "normalized_query": message,
        "group_size": _extract_group_size_fallback(message),
        "vibes": [],
        "indoor_outdoor": "either",
    }

    try:
        model = genai.GenerativeModel("models/gemini-2.5-flash")
        resp = model.generate_content(prompt)
        text = getattr(resp, "text", "") or ""
        data = _parse_llm_json(text)
        if not data:
            print("SEMANTIC_INTENT: JSON parse failed, using fallback")
            return fallback

        # Normalize fields
        intent_type = (data.get("intent_type") or "other").lower()
        if intent_type not in ["study", "coffee", "eat", "nightlife", "events", "outdoors", "date", "other"]:
            intent_type = "other"

        normalized_query = data.get("normalized_query") or message
        group_size = data.get("group_size")
        try:
            group_size = int(group_size) if group_size is not None else None
        except Exception:
            group_size = _extract_group_size_fallback(message)

        vibes = data.get("vibes") or []
        if not isinstance(vibes, list):
            vibes = []

        io = (data.get("indoor_outdoor") or "either").lower()
        if io not in ["indoor", "outdoor", "either"]:
            io = "either"

        return {
            "intent_type": intent_type,
            "normalized_query": normalized_query,
            "group_size": group_size,
            "vibes": vibes,
            "indoor_outdoor": io,
        }

    except Exception as ex:
        print("SEMANTIC_INTENT ERROR:", ex)
        return fallback
