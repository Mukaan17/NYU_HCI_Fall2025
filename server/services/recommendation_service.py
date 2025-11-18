# server/services/recommendation_service.py
from typing import List, Dict, Any
import google.generativeai as genai
import os

from services.weather_service import current_weather
from services.places_service import nearby_places, build_photo_url
from services.vibes import classify_vibe, vibe_to_place_types
from services.directions_service import get_walking_directions, walking_minutes

# NYU Tandon coordinates
TANDON_LAT = 40.6942
TANDON_LNG = -73.9866

# Memory for CHAT ONLY
RECENT_PLACES: List[str] = []
RECENT_LIMIT = 10


# -------------------------------------------------------------
# BUSYNESS PLACEHOLDER
# -------------------------------------------------------------
def estimate_busyness(place: Dict[str, Any]) -> Dict[str, Any]:
    return {"busyness_label": "unknown", "busyness_score": 0.0}


# -------------------------------------------------------------
# CHAT SCORING (unchanged)
# -------------------------------------------------------------
def score_place(place: Dict[str, Any], recent_names: List[str]) -> float:
    rating = place.get("rating", 0) or 0
    duration_text = place.get("walk_time")
    mins = walking_minutes(duration_text) if duration_text else 999

    base = (rating * 2.0) - (mins / 5.0)

    name = (place.get("name") or "").lower()
    recency_penalty = -2.0 if name in [n.lower() for n in recent_names] else 0.0

    busy_score = -estimate_busyness(place)["busyness_score"]

    return base + recency_penalty + busy_score


def update_recent_places(chosen: List[Dict[str, Any]]):
    global RECENT_PLACES
    for p in chosen:
        name = p.get("name")
        if name and name not in RECENT_PLACES:
            RECENT_PLACES.append(name)

    if len(RECENT_PLACES) > RECENT_LIMIT:
        RECENT_PLACES = RECENT_PLACES[-RECENT_LIMIT:]


# -------------------------------------------------------------
# CHAT RECOMMENDATIONS (NOW WITH PHOTOS)
# -------------------------------------------------------------
def build_chat_response(user_message: str, memory) -> Dict[str, Any]:

    memory.add_message("user", user_message)

    followup_request = any(
        phrase in user_message.lower()
        for phrase in ["something else", "anything else", "more places", "new place", "new places"]
    )

    try:
        weather = current_weather("Brooklyn,US")
    except Exception:
        weather = None

    vibe = classify_vibe(user_message)
    place_types, radius = vibe_to_place_types(vibe)

    # ------------------- GOOGLE PLACES SEARCH -------------------
    raw = []
    for p_type in place_types:
        try:
            raw.extend(
                nearby_places(
                    lat=TANDON_LAT, lng=TANDON_LNG,
                    place_type=p_type, radius=radius
                )
            )
        except Exception as e:
            print("Places error:", e)

    dedup = { (p.get("place_id") or p.get("name")): p for p in raw }
    candidates = list(dedup.values())

    if not candidates:
        fallback = "I'm having trouble finding places right now."
        memory.add_message("assistant", fallback)
        return {"reply": fallback, "places": []}

    # ------------------- ENRICH: directions + photo -------------------
    enriched = []
    for p in candidates:
        geom = p.get("geometry", {}).get("location", {})
        lat, lng = geom.get("lat"), geom.get("lng")
        if not lat or not lng:
            continue

        d = get_walking_directions(TANDON_LAT, TANDON_LNG, lat, lng)

        # PHOTO SUPPORT
        photos = p.get("photos", [])
        ref = photos[0].get("photo_reference") if photos else None
        photo_url = build_photo_url(ref)

        enriched.append({
            "name": p.get("name"),
            "rating": p.get("rating", 0),
            "address": p.get("vicinity"),
            "location": {"lat": lat, "lng": lng},
            "walk_time": d["duration_text"] if d else None,
            "distance": d["distance_text"] if d else None,
            "maps_link": d["maps_link"] if d else None,
            "photo_url": p.get("photo_url"),
        })

    # ------------------- SCORING -------------------
    recent_lower = [x.lower() for x in RECENT_PLACES]

    for p in enriched:
        p["score"] = score_place(p, recent_lower)

    enriched.sort(key=lambda x: x["score"], reverse=True)

    if followup_request:
        enriched = enriched[3:] + enriched[:3]

    top = enriched[:3]
    update_recent_places(top)

    # ------------------- AI MESSAGE -------------------
    places_context = "\n".join(
        f"{i+1}. {p['name']} — {p['distance']} ({p['walk_time']})"
        for i, p in enumerate(top)
    )

    prompt = f"""
You are VioletVibes. Use ONLY these places:

{places_context}

User said: "{user_message}"
"""

    model = genai.GenerativeModel("models/gemini-2.5-flash")
    response = model.generate_content(prompt)
    reply_text = getattr(response, "text", "Here's something nearby!")

    memory.add_message("assistant", reply_text)

    return {
        "reply": reply_text,
        "places": top,
        "vibe": vibe,
        "weather": weather,
    }


# -------------------------------------------------------------
# QUICK ACTION RECOMMENDATIONS (NOW WITH PHOTOS)
# -------------------------------------------------------------
QUICK_CATEGORY_CONFIG = {
    "quick_bites": {"types": ["restaurant", "meal_takeaway"], "radius": 800},
    "chill_cafes": {"types": ["cafe"], "radius": 900},
    "events": {"types": ["bar", "movie_theater"], "radius": 1500},
    "explore": {"types": ["tourist_attraction", "park"], "radius": 1500},
}

QUICK_WEIGHTS = {
    "quick_bites": {"distance": 0.5, "busyness": 0.35, "rating": 0.15},
    "chill_cafes": {"distance": 0.45, "busyness": 0.4, "rating": 0.15},
    "events": {"distance": 0.6, "busyness": 0.25, "rating": 0.15},
    "explore": {"distance": 0.6, "busyness": 0.2, "rating": 0.2},
}
DEFAULT_QUICK_WEIGHTS = {"distance": 0.55, "busyness": 0.3, "rating": 0.15}


def _normalize_distance_minutes(mins: float, max_minutes: float = 20.0) -> float:
    if mins is None:
        return 0.0
    return max(0.0, 1.0 - (mins / max_minutes))


def _quick_score_place(place: Dict[str, Any], category: str) -> float:
    weights = QUICK_WEIGHTS.get(category, DEFAULT_QUICK_WEIGHTS)
    w_dist, w_busy, w_rating = weights["distance"], weights["busyness"], weights["rating"]

    mins = walking_minutes(place.get("walk_time")) if place.get("walk_time") else None
    dist_score = _normalize_distance_minutes(mins)

    rating = place.get("rating") or 0
    rating_score = min(max(rating / 5.0, 0.0), 1.0)

    busy_score = ( -estimate_busyness(place)["busyness_score"] + 1.0 ) / 2.0

    return w_dist * dist_score + w_busy * busy_score + w_rating * rating_score


def get_quick_recommendations(category: str, limit: int = 10) -> Dict[str, Any]:
    cfg = QUICK_CATEGORY_CONFIG.get(category, QUICK_CATEGORY_CONFIG["explore"])

    raw = []
    for t in cfg["types"]:
        raw.extend(
            nearby_places(
                lat=TANDON_LAT, lng=TANDON_LNG,
                place_type=t, radius=cfg["radius"]
            )
        )

    dedup = { (p.get("place_id") or p.get("name")): p for p in raw }
    candidates = list(dedup.values())

    enriched = []
    for p in candidates:
        geom = p.get("geometry", {}).get("location", {})
        lat, lng = geom.get("lat"), geom.get("lng")
        if not lat or not lng:
            continue

        d = get_walking_directions(TANDON_LAT, TANDON_LNG, lat, lng)

        # PHOTO SUPPORT
        photos = p.get("photos", [])
        ref = photos[0].get("photo_reference") if photos else None
        photo_url = build_photo_url(ref)

        enriched.append({
            "name": p.get("name"),
            "rating": p.get("rating", 0),
            "address": p.get("vicinity"),
            "location": {"lat": lat, "lng": lng},
            "walk_time": d["duration_text"] if d else None,
            "distance": d["distance_text"] if d else None,
            "maps_link": d["maps_link"] if d else None,
            "photo_url": p.get("photo_url"),
        })

    for p in enriched:
        p["score"] = _quick_score_place(p, category)

    enriched.sort(key=lambda x: x["score"], reverse=True)
    top = enriched[:limit]

    return {"category": category, "places": top}
