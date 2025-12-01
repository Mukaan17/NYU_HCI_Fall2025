# services/recommendation/driver.py
from __future__ import annotations
import time
import logging

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


logger = logging.getLogger(__name__)

TANDON_LAT = 40.6942
TANDON_LNG = -73.9866


# ---------------------------------------------------------------------
# MAIN RESPONSE ENTRY
# ---------------------------------------------------------------------
def build_chat_response(
    message: str,
    memory: ConversationContext,
    user_profile=None,
):
    user_profile = user_profile or {}
    t0 = time.time()

    # STEP 1 — classify user vibe
    vibe = classify_vibe(message)
    place_types, radius = vibe_to_place_types(vibe)

    # STEP 2 — Load static events (safe if file missing)
    events = fetch_all_external_events()

    # STEP 3 — Filter appropriate events based on vibe + message
    filtered_events = filter_events(vibe, message, events)

    # STEP 4 — Query nearby places (OPEN NOW)
    raw_places = []
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

    # STEP 5 — Normalize places into unified cards
    seen = set()
    final_places = []

    for p in raw_places:
        key = p.get("place_id") or p.get("name")
        if key in seen:
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

        # 🔥 Add busyness
        normalized["busyness"] = get_busyness(
            p.get("place_id"),
            {
                "rating": p.get("rating"),
                "user_ratings_total": p.get("user_ratings_total")
            }
        )

        final_places.append(normalized)


    # STEP 6 — Normalize events
    normalized_events = []
    for e in filtered_events:
        try:
            normalized_events.append(normalize_event(e))
        except Exception as ex:
            logger.warning(f"EVENT NORMALIZATION ERROR: {ex}")

    # STEP 7 — Combine places + events
    items = final_places + normalized_events

    if not items:
        return {
            "debug_vibe": vibe,
            "latency": round(time.time() - t0, 2),
            "places": [],
            "reply": "Sorry, I couldn't find anything nearby right now.",
            "weather": current_weather(),
        }

    # STEP 8 — Score with query + profile + vibe
    score_items_with_embeddings(
        query_text=message,
        items=items,
        profile=user_profile,
    )

    # STEP 9 — Sort
    items.sort(key=lambda x: x.get("score", 0), reverse=True)

    # Update memory with top results (for future follow-ups if needed)
    memory.set_places(items[:3])
    memory.set_results(items)

    # STEP 10 — Build surface reply
    reply = build_surface_reply(message, items)

    return {
        "debug_vibe": vibe,
        "latency": round(time.time() - t0, 2),
        "places": items[:3],
        "reply": reply,
        "weather": current_weather(),
    }


# ---------------------------------------------------------------------
# SURFACE REPLY
# ---------------------------------------------------------------------
def build_surface_reply(user_msg: str, items: list):
    if not items:
        return "Sorry, I couldn't find anything nearby right now."

    top = items[:2]

    lines = ["Hey there!"]
    for p in top:
        name = p.get("name", "Unknown")
        dist = p.get("distance") or ""
        walk = p.get("walk_time") or ""

        if dist and walk:
            lines.append(f"You might like **{name}** ({dist}, {walk}).")
        else:
            lines.append(f"You might like **{name}**.")

    return "\n".join(lines)
