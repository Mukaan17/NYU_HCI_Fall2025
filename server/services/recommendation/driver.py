# server/services/recommendation/driver.py
from __future__ import annotations
import time
import logging
from typing import List, Dict, Any, Optional

import google.generativeai as genai

from services.vibes import classify_vibe, vibe_to_place_types
from services.recommendation.scoring import score_items_with_embeddings
from services.recommendation.event_filter import filter_events
from services.recommendation.events import fetch_all_external_events
from services.recommendation.context import ConversationContext
from services.recommendation.places import normalize_place
from services.recommendation.event_normalizer import normalize_event

from services.places_service import nearby_places
from services.directions_service import get_walking_directions
from services.weather_service import current_weather
from services.popularity_service import get_busyness

from services.recommendation.intent import (
    classify_intent_llm,
    is_on_campus_query,
)
from services.recommendation.llm_reply import generate_list_reply

logger = logging.getLogger(__name__)

TANDON_LAT = 40.6942
TANDON_LNG = -73.9866


# ---------------------------------------------------------------------
# MAIN ENTRY
# ---------------------------------------------------------------------
def build_chat_response(
    message: str,
    memory: ConversationContext,
    user_profile=None,
):
    """
    Main router for /api/chat.

    - Classifies intent (general_chat, recommendation, new_recommendation, followup_place)
    - Uses vibe + embeddings to score items when we’re actually recommending
    - Uses Gemini for:
        * list-style recommendation replies
        * follow-up explanations about a specific place
    """
    user_profile = user_profile or {}
    t0 = time.time()

    # 1) Intent + vibe
    intent = classify_intent_llm(message, memory)
    vibe = classify_vibe(message)
    on_campus_only = is_on_campus_query(message)

    logger.info(f"[CHAT] intent={intent}, vibe={vibe}, on_campus_only={on_campus_only}")

    # Branch on intent
    if intent == "general_chat":
        reply = _build_general_chat_reply(message, vibe)
        return _build_response(
            reply=reply,
            places=[],
            vibe=vibe,
            intent=intent,
            latency_start=t0,
        )

    if intent == "followup_place":
        reply = _handle_followup_place(message, memory, vibe)
        # follow-up is *about* existing items; no need to send new cards
        return _build_response(
            reply=reply,
            places=[],
            vibe=vibe,
            intent=intent,
            latency_start=t0,
        )

    # Both of these are “give me recs” flows
    if intent in ("recommendation", "new_recommendation"):
        exclude_ids: Optional[set[str]] = None
        if intent == "new_recommendation":
            # Don’t repeat what we just showed
            last = memory.last_places or []
            exclude_ids = {
                (p.get("id") or p.get("place_id") or p.get("name") or "").lower()
                for p in last
                if isinstance(p, dict)
            }

        items = _build_and_score_items(
            message=message,
            user_profile=user_profile,
            vibe=vibe,
            on_campus_only=on_campus_only,
            exclude_ids=exclude_ids,
        )

        if not items:
            reply = (
                "I couldn’t find anything nearby that fits that right now. "
                "Want to try a different vibe, like coffee, chill bar, or study spot?"
            )
            return _build_response(
                reply=reply,
                places=[],
                vibe=vibe,
                intent=intent,
                latency_start=t0,
            )

        # Top 3 → memory + cards
        top_items = items[:3]
        memory.set_places(top_items)
        memory.set_results(items)

        # Use Gemini to describe ONLY these top items
        reply = generate_list_reply(message, top_items)

        return _build_response(
            reply=reply,
            places=top_items,
            vibe=vibe,
            intent=intent,
            latency_start=t0,
        )

    # Fallback: treat anything weird as “recommendation”
    items = _build_and_score_items(
        message=message,
        user_profile=user_profile,
        vibe=vibe,
        on_campus_only=on_campus_only,
        exclude_ids=None,
    )
    if not items:
        reply = "I’m not seeing anything nearby right now, but we can try a different vibe or time."
        return _build_response(
            reply=reply,
            places=[],
            vibe=vibe,
            intent="fallback_recommendation",
            latency_start=t0,
        )

    top_items = items[:3]
    memory.set_places(top_items)
    memory.set_results(items)
    reply = generate_list_reply(message, top_items)

    return _build_response(
        reply=reply,
        places=top_items,
        vibe=vibe,
        intent="fallback_recommendation",
        latency_start=t0,
    )


# ---------------------------------------------------------------------
# BUILD + SCORE ITEMS
# ---------------------------------------------------------------------
def _build_and_score_items(
    message: str,
    user_profile: Dict[str, Any],
    vibe: str,
    on_campus_only: bool,
    exclude_ids: Optional[set[str]] = None,
) -> List[Dict[str, Any]]:
    """
    Fetch external events + nearby places, normalize them, and score with embeddings.
    `exclude_ids` is used when user asks for “something else / more options”.
    """
    exclude_ids = exclude_ids or set()
    place_types, radius = vibe_to_place_types(vibe)

    # 1) Load static / external events
    events_raw = fetch_all_external_events()
    filtered_events = filter_events(vibe, message, events_raw)

    normalized_events: List[Dict[str, Any]] = []
    for e in filtered_events:
        try:
            normalized_events.append(normalize_event(e))
        except Exception as ex:
            logger.warning(f"EVENT NORMALIZATION ERROR: {ex}")

    # 2) If user explicitly wants ON-CAMPUS → only surface events
    if on_campus_only:
        items = normalized_events
    else:
        # 2a) Query nearby places (Google Places etc.)
        raw_places: List[Dict[str, Any]] = []
        for t in place_types:
            try:
                raw_places.extend(
                    nearby_places(
                        lat=TANDON_LAT,
                        lng=TANDON_LNG,
                        place_type=t,
                        radius=radius,
                        open_now=True,
                    )
                )
            except Exception as e:
                logger.warning(f"Error fetching nearby places for type {t}: {e}")

        # 2b) Normalize + add walking directions + busyness
        seen = set()
        final_places: List[Dict[str, Any]] = []

        for p in raw_places:
            key = p.get("place_id") or p.get("name")
            if not key or key in seen:
                continue
            seen.add(key)

            loc = p.get("geometry", {}).get("location", {})
            lat = loc.get("lat")
            lng = loc.get("lng")
            if lat is None or lng is None:
                continue

            try:
                directions = get_walking_directions(TANDON_LAT, TANDON_LNG, lat, lng)
            except Exception:
                directions = None

            normalized = normalize_place(p, directions)

            # Add busyness signal
            normalized["busyness"] = get_busyness(
                p.get("place_id"),
                {
                    "rating": p.get("rating"),
                    "user_ratings_total": p.get("user_ratings_total"),
                },
            )

            final_places.append(normalized)

        # 2c) Combine
        items = final_places + normalized_events

    # 3) Exclude previously-shown items (for “something else / more options”)
    if exclude_ids:
        filtered = []
        for it in items:
            iid = (
                (it.get("id") or it.get("place_id") or it.get("name") or "")
                .lower()
            )
            if iid and iid in exclude_ids:
                continue
            filtered.append(it)
        items = filtered

    if not items:
        return []

    # 4) Score with embeddings
    score_items_with_embeddings(
        query_text=message,
        items=items,
        profile=user_profile,
    )

    # 5) Sort descending by score
    items.sort(key=lambda x: x.get("score", 0), reverse=True)
    return items


# ---------------------------------------------------------------------
# FOLLOW-UP ABOUT A SPECIFIC PLACE
# ---------------------------------------------------------------------
def _handle_followup_place(
    message: str,
    memory: ConversationContext,
    vibe: str,
) -> str:
    """
    User asks: “What’s the vibe at Superfine?” or “Tell me more about Brooklyn Heights Promenade.”
    We look in memory.last_places, find the matching place, and let Gemini
    write a friendly, focused description of THAT place only.
    """
    last_places = memory.last_places or []
    if not last_places:
        # No history → fall back to generic recommendation flow text
        return (
            "I don't have a specific place in mind from earlier. "
            "Tell me what you’re in the mood for and I’ll suggest some options nearby."
        )

    msg = message.lower()
    target: Optional[Dict[str, Any]] = None

    for p in last_places:
        name = (p.get("name") or "").lower()
        if name and name in msg:
            target = p
            break

    # If we can’t find by name, just pick the first recent place as a fallback
    if target is None:
        target = last_places[0]

    return _generate_place_followup_reply(message, target, vibe)


def _generate_place_followup_reply(
    user_message: str,
    place: Dict[str, Any],
    vibe: str,
) -> str:
    """
    Use Gemini to answer FOLLOW-UP questions about a single known place,
    with clearer category descriptions (bar, restaurant, cafe, park, etc.).
    """

    name = place.get("name", "this place")
    address = place.get("address") or place.get("description") or ""
    distance = place.get("distance") or place.get("distance_text") or ""
    walk = place.get("walk_time") or place.get("duration_text") or ""
    rating = place.get("rating")
    place_type = place.get("type") or place.get("source") or ""

    busyness_info = place.get("busyness")
    if isinstance(busyness_info, dict):
        busyness_label = busyness_info.get("label")
    else:
        busyness_label = None

    # -------------------------------------------
    # NEW: human-friendly category descriptions
    # -------------------------------------------
    CATEGORY_HINTS = {
        "bar": "a casual spot for drinks and socializing",
        "restaurant": "a sit-down place for meals",
        "cafe": "a relaxed coffee shop that’s good for studying or hanging out",
        "meal_takeaway": "a quick take-out spot",
        "night_club": "a lively spot with late-night energy",
        "park": "an outdoor green space with a calm, open vibe",
        "tourist_attraction": "a popular place people visit for the experience or view",
        "museum": "an indoor cultural place with exhibits",
        "shopping_mall": "a retail area with multiple shops",
    }

    # Pick a readable category tag
    readable_type = CATEGORY_HINTS.get(place_type, "")
    category_line = (
        f"Category: {place_type.replace('_', ' ')} — {readable_type}"
        if readable_type
        else f"Category: {place_type.replace('_', ' ')}"
        if place_type
        else "Category: (not provided)"
    )

    # Format summary to feed Gemini
    summary_lines = [
        f"Name: {name}",
        f"Address: {address}" if address else "Address: (not provided)",
        f"Distance from Tandon: {distance}" if distance else "Distance from Tandon: (unknown)",
        f"Walking time: {walk}" if walk else "Walking time: (unknown)",
        f"Rating: {rating:.1f}" if rating is not None else "Rating: (unknown)",
        category_line,
    ]

    if busyness_label:
        summary_lines.append(f"Typical busyness: {busyness_label}")

    if vibe:
        summary_lines.append(f"Conversation vibe: {vibe}")

    place_summary = "\n".join(summary_lines)

    # --------------------------------------------------
    # Updated prompt — now includes the category meaning
    # --------------------------------------------------
    prompt = f"""
You are VioletVibes, the NYU Tandon student concierge.

The user is asking about ONE specific place and wants to understand
what kind of place it is and what the vibe is like.

Use ONLY the structured information below. You may use very general,
widely-known interpretations of categories such as:
- “bar” → casual drinks, social, louder atmosphere
- “restaurant” → sit-down meals
- “cafe” → coffee, chill, good for studying
- “park” → open-air, scenic, relaxed
Do NOT invent specific details like menus, prices, or events.

Place info:
{place_summary}

User question:
\"\"\"{user_message}\"\"\"


Write 2–4 friendly sentences that explain:
- what *kind* of place this is (using the category meaning)
- what the general vibe would feel like
- how convenient it is based on distance/walking time
"""

    try:
        model = genai.GenerativeModel("models/gemini-2.5-flash")
        resp = model.generate_content(prompt, request_options={"timeout": 10})
        text = getattr(resp, "text", None)
        if not text:
            raise RuntimeError("Empty text from Gemini")
        return text.strip()

    except Exception as e:
        logger.error(f"Place follow-up LLM error: {e}", exc_info=True)

        # Simple deterministic fallback
        fallback = f"{name} is a nearby spot"
        if readable_type:
            fallback += f" — it's {readable_type}"
        if rating is not None:
            fallback += f" with a rating around {rating:.1f}"
        if busyness_label:
            fallback += f" and tends to be {busyness_label.lower()}"
        return fallback + "."

# ---------------------------------------------------------------------
# GENERAL CHAT (no new recommendations)
# ---------------------------------------------------------------------
def _build_general_chat_reply(message: str, vibe: str) -> str:
    """
    Lightweight rule-based smalltalk so we don’t always jump into recommendations.
    This keeps hi/hello/thanks feeling human without extra API calls.
    """
    msg = message.lower().strip()

    greetings = ["hi", "hey", "hello", "yo", "sup", "what's up", "whats up"]
    thanks = ["thanks", "thank you", "thx", "appreciate it", "ty"]

    if any(msg.startswith(g) for g in greetings):
        return (
            "Hey! I’m VioletVibes 🟣\n\n"
            "Tell me what you’re in the mood for — coffee, drinks, something chill outside, "
            "or a quick bite near Tandon."
        )

    if any(t in msg for t in thanks):
        return "You’re welcome! If you tell me your vibe again, I can suggest more places or events."

    # If they mention boredom / vibe without being explicit
    if "bored" in msg or "nothing to do" in msg:
        return (
            "I’ve got you. Tell me if you want something low-key, social, or more of a night-out vibe, "
            "and I’ll pull a few nearby ideas."
        )

    if "tired" in msg or "exhausted" in msg:
        return (
            "Long day? I can find something cozy and low-effort nearby — "
            "like a chill cafe or a short walk spot with a nice view. What sounds good?"
        )

    # Default generic chat fallback
    return (
        "Gotcha. If you tell me a bit more about what you’re feeling — "
        "coffee, food, drinks, study, or outside — I’ll recommend a few nearby options."
    )


# ---------------------------------------------------------------------
# RESPONSE WRAPPER
# ---------------------------------------------------------------------
def _build_response(
    reply: str,
    places: List[Dict[str, Any]],
    vibe: str,
    intent: str,
    latency_start: float,
) -> Dict[str, Any]:
    """
    Standard envelope for /api/chat responses.
    Matches what the iOS client expects: reply, places, weather, plus debug fields.
    """
    latency = round(time.time() - latency_start, 2)
    return {
        "debug_vibe": vibe,
        "debug_intent": intent,
        "latency": latency,
        "places": places,
        "reply": reply,
        "weather": current_weather(),
        "vibe": vibe,
    }
