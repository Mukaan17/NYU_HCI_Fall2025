# server/services/recommendation/quick_recommendations.py

from __future__ import annotations
from typing import List, Dict, Any
from datetime import datetime

from services.places_service import nearby_places, build_photo_url
from services.directions_service import get_walking_directions, walking_minutes
from services.popularity_service import get_busyness

# Event scrapers
from services.scrapers.brooklyn_bridge_park_scraper import fetch_brooklyn_bridge_park_events
from services.scrapers.downtown_brooklyn_scraper import fetch_downtown_bk_events
from services.scrapers.nyc_parks_scraper import fetch_nyc_parks_events
from services.scrapers.engage_events_service import fetch_engage_events


# -----------------------------------------------------------
# CONFIG
# -----------------------------------------------------------

TANDON_LAT = 40.6942
TANDON_LNG = -73.9866

# 🔄 Use chill_cafes as canonical name
QUICK_CATEGORIES = ["quick_bites", "chill_cafes", "events", "explore"]

CATEGORY_CONFIG = {
    "quick_bites": {
        "types": ["restaurant", "meal_takeaway"],
        "radius": 800,
    },
    # 🔄 Key is now chill_cafes
    "chill_cafes": {
        "types": ["cafe"],
        "radius": 1200,
    },
    "explore": {
        "types": ["tourist_attraction", "park", "shopping_mall", "museum"],
        "radius": 2500,
    },
}

EVENT_SOURCES = [
    fetch_brooklyn_bridge_park_events,
    fetch_downtown_bk_events,
    fetch_nyc_parks_events,
]


# -----------------------------------------------------------
# UTILS — normalizers
# -----------------------------------------------------------

def _normalize_distance_minutes(mins: float | None, max_minutes: float = 25.0) -> float:
    if mins is None:
        return 0.5
    return max(0.0, 1.0 - (mins / max_minutes))


def _normalize_rating(r: float | None) -> float:
    if not r:
        return 0.5
    return min(max(r / 5.0, 0.0), 1.0)


def _normalize_event_time(start_str: str | None) -> float:
    if not start_str:
        return 0.3

    try:
        event_time = datetime.fromisoformat(start_str)
        now = datetime.now()
        delta = (event_time - now).total_seconds()

        if delta < 0:
            return 0.2

        return max(0.0, min(1.0, 1 - (delta / (48 * 3600))))
    except Exception:
        return 0.3


# -----------------------------------------------------------
# QUICK SCORES — UPDATED WITH REAL BUSYNESS
# -----------------------------------------------------------

def _score_quick_bite(place: Dict[str, Any]) -> float:
    mins = walking_minutes(place.get("walk_time"))
    dist = _normalize_distance_minutes(mins)
    rating = _normalize_rating(place.get("rating"))

    busy = place.get("busyness") or 0.5
    busy_score = 1.0 - busy  # less busy = better for grabbing food fast

    return 0.55 * dist + 0.30 * busy_score + 0.15 * rating


def _score_cozy_cafe(place: Dict[str, Any]) -> float:
    mins = walking_minutes(place.get("walk_time"))
    dist = _normalize_distance_minutes(mins)
    rating = _normalize_rating(place.get("rating"))

    quiet_score = 1.0 - (place.get("busyness") or 0.5)

    return 0.45 * dist + 0.40 * quiet_score + 0.15 * rating


def _score_explore(place: Dict[str, Any]) -> float:
    mins = walking_minutes(place.get("walk_time"))
    dist = _normalize_distance_minutes(mins)
    rating = _normalize_rating(place.get("rating"))

    busy = place.get("busyness") or 0.5  # busier = more lively for exploring

    return 0.50 * dist + 0.20 * rating + 0.30 * busy


def _score_event(ev: Dict[str, Any]) -> float:
    return _normalize_event_time(ev.get("start"))


# -----------------------------------------------------------
# HELPERS
# -----------------------------------------------------------

def _search_places_for_category(category: str) -> List[Dict[str, Any]]:
    cfg = CATEGORY_CONFIG.get(category)
    if not cfg:
        return []

    raw: List[Dict[str, Any]] = []

    for t in cfg["types"]:
        try:
            raw.extend(nearby_places(TANDON_LAT, TANDON_LNG, t, cfg["radius"]))
        except Exception as e:
            print(f"QuickRecs {category} error:", e)

    dedup: Dict[str, Dict[str, Any]] = {}

    for p in raw:
        place_id = p.get("place_id")
        name = p.get("name")

        # Fallback to coordinates if no place_id or name
        geom = p.get("geometry", {}).get("location", {})
        lat = geom.get("lat")
        lng = geom.get("lng")

        unique_key = place_id or name or f"coord-{lat},{lng}"

        # If all three are missing, create a guaranteed unique key
        if not unique_key:
            unique_key = f"unknown-{id(p)}"

        dedup[unique_key] = p

    candidates = list(dedup.values())

    enriched: List[Dict[str, Any]] = []

    for p in candidates:
        geom = p.get("geometry", {}).get("location", {})
        lat = geom.get("lat")
        lng = geom.get("lng")
        if not lat or not lng:
            continue

        d = get_walking_directions(TANDON_LAT, TANDON_LNG, lat, lng)

        photos = p.get("photos", [])
        ref = photos[0].get("photo_reference") if photos else None
        photo_url = build_photo_url(ref)

        # 🔥 Call busyness service
        busy_data = get_busyness(
            p.get("place_id"),
            {
                "rating": p.get("rating"),
                "user_ratings_total": p.get("user_ratings_total")
            }
        )

        item = {
            "name": p.get("name"),
            "rating": p.get("rating", 0),
            "address": p.get("vicinity"),
            "location": {"lat": lat, "lng": lng},
            "walk_time": d["duration_text"] if d else None,
            "distance": d["distance_text"] if d else None,
            "maps_link": d["maps_link"] if d else None,
            "photo_url": photo_url,
            "type": "place",
            "source": "google_places",
            # keep original place types for preference/vibe logic
            "types": p.get("types", []),

            # busyness
            "busyness": busy_data.get("busyness"),
            "busyness_label": busy_data.get("label"),
        }

        enriched.append(item)

    return enriched


def _load_events() -> List[Dict[str, Any]]:
    events: List[Dict[str, Any]] = []

    for fn in EVENT_SOURCES:
        try:
            events.extend(fn(limit=30))
        except Exception as e:
            print("QuickRecs event scraper error:", e)

    try:
        engage = fetch_engage_events(days_ahead=7, limit=50)
        for e in engage:
            events.append({
                "name": e.get("name"),
                "address": e.get("location"),
                "location": None,
                "maps_link": e.get("url"),
                "photo_url": e.get("image"),
                "description": e.get("description"),
                "start": e.get("start"),
                "end": e.get("end"),
                "type": "nyu_engage_event",
                "source": "nyu_engage",
            })
    except Exception as e:
        print("QuickRecs Engage error:", e)

    return events


# -----------------------------------------------------------
# MAIN API — QUICK RECS
# -----------------------------------------------------------

def get_quick_recommendations(category: str, limit: int = 10) -> Dict[str, Any]:
    category = category.lower()

    if category == "quick_bites":
        places = _search_places_for_category("quick_bites")
        for p in places:
            p["score"] = _score_quick_bite(p)
        places.sort(key=lambda x: x["score"], reverse=True)
        return {"category": "quick_bites", "places": places[:limit]}

    # 🔄 Chill Cafes
    if category in ("chill_cafes", "cozy_cafes"):  # accept old name just in case
        places = _search_places_for_category("chill_cafes")
        for p in places:
            p["score"] = _score_cozy_cafe(p)
        places.sort(key=lambda x: x["score"], reverse=True)
        return {"category": "chill_cafes", "places": places[:limit]}

    if category == "explore":
        places = _search_places_for_category("explore")
        for p in places:
            p["score"] = _score_explore(p)
        places.sort(key=lambda x: x["score"], reverse=True)
        return {"category": "explore", "places": places[:limit]}

    if category == "events":
        events = _load_events()
        for ev in events:
            ev["score"] = _score_event(ev)
        events.sort(key=lambda x: x["score"], reverse=True)
        return {"category": "events", "places": events[:limit]}

    return {"category": category, "places": []}


# -----------------------------------------------------------
# TOP RECOMMENDATIONS — PREFS + CONTEXT AWARE
# -----------------------------------------------------------

def _preference_match_score(place: Dict[str, Any],
                            prefs: Dict[str, Any] | None,
                            context: Dict[str, Any] | None = None) -> float:
    """
    Score how well this place matches the user's saved preferences.
    0.0–1.0, where 1.0 is a perfect match.
    Tolerant of missing keys — falls back to neutral ~0.6.
    """
    if not prefs:
        return 0.6  # neutral-ish if we know nothing

    prefs = prefs or {}
    context = context or {}

    score = 0.0
    weight_sum = 0.0

    # Normalize helpers
    name = (place.get("name") or "").lower()
    types = [t.lower() for t in place.get("types", [])]
    all_text = " ".join([name] + types)

    # ----- Diet preferences -----
    diet = (prefs.get("diet") or prefs.get("dietary") or "").lower()
    if diet:
        weight_sum += 1.0
        is_vegan_friendly = any(k in all_text for k in ["vegan", "plant-based"])
        is_veg_friendly = is_vegan_friendly or any(k in all_text for k in ["vegetarian", "veggie"])

        if diet in ["vegan"]:
            score += 1.0 if is_vegan_friendly else 0.2
        elif diet in ["vegetarian", "veggie"]:
            score += 1.0 if is_veg_friendly else 0.3
        else:
            # other diets you might add later
            score += 0.6

    # ----- Budget / price -----
    budget = (prefs.get("budget") or prefs.get("price") or "").lower()
    price_level = place.get("price_level")  # Google Places: 0–4
    if budget and price_level is not None:
        weight_sum += 1.0
        # simple mapping: cheap → 0–1, mid → 1–2, bougie → 3–4
        if budget in ["cheap", "student", "low"]:
            if price_level <= 1:
                score += 1.0
            elif price_level == 2:
                score += 0.7
            else:
                score += 0.2
        elif budget in ["mid", "medium"]:
            if price_level == 1 or price_level == 2:
                score += 1.0
            else:
                score += 0.5
        elif budget in ["bougie", "high", "fancy"]:
            if price_level >= 3:
                score += 1.0
            else:
                score += 0.4
        else:
            score += 0.6

    # ----- Vibes -----
    # prefs["vibes"] might be a list or comma-separated string
    vibes_raw = prefs.get("vibes") or prefs.get("vibe") or ""
    if isinstance(vibes_raw, str):
        vibes = [v.strip().lower() for v in vibes_raw.split(",") if v.strip()]
    else:
        vibes = [str(v).lower() for v in (vibes_raw or [])]

    if vibes:
        weight_sum += 1.0
        place_tags = all_text
        vibe_score = 0.5  # neutral
        for vibe in vibes:
            if vibe in ["chill", "cozy", "low-key"]:
                # prefer less busy places
                busy = place.get("busyness") or 0.5
                vibe_score = max(vibe_score, 1.0 - busy)
            elif vibe in ["social", "lively", "party"]:
                busy = place.get("busyness") or 0.5
                vibe_score = max(vibe_score, busy)
            elif vibe in ["coffee", "study", "cafe"]:
                if any(k in place_tags for k in ["cafe", "coffee"]):
                    vibe_score = max(vibe_score, 1.0)
            elif vibe in ["outdoors", "park", "sunset"]:
                if any(k in place_tags for k in ["park", "pier", "waterfront", "outdoor"]):
                    vibe_score = max(vibe_score, 1.0)
        score += vibe_score

    if weight_sum == 0:
        return 0.6

    return max(0.0, min(1.0, score / weight_sum))


def _context_match_score(place: Dict[str, Any],
                         context: Dict[str, Any] | None = None) -> float:
    """
    Simple time-of-day / weather adjustment.
    0.0–1.0, where 1.0 means "perfect for right now".
    """
    if not context:
        return 0.7  # mildly positive default

    hour = context.get("hour")

    # ---- FIX: weather may be a dict OR str ----
    weather_raw = context.get("weather")
    if isinstance(weather_raw, dict):
        weather = (weather_raw.get("raw") or weather_raw.get("label") or "").lower()
    else:
        weather = str(weather_raw or "").lower()

    types = [t.lower() for t in place.get("types", [])]

    score = 0.7

    # Late night: avoid parks
    if hour is not None and (hour >= 22 or hour < 7):
        if any(k in types for k in ["park", "tourist_attraction"]) or "park" in (place.get("name") or "").lower():
            score -= 0.3
        else:
            score += 0.1

    # Rainy weather: avoid outdoors
    if weather in ["rain", "rainy", "storm", "snow"]:
        if any(k in types for k in ["park", "tourist_attraction"]) or "park" in (place.get("name") or "").lower():
            score -= 0.3
        else:
            score += 0.1

    return max(0.0, min(1.0, score))
# -----------------------------------------------------------
# TOP RECOMMENDATIONS — PREFS + CONTEXT AWARE
# -----------------------------------------------------------

def get_top_recommendations_for_user(
    prefs: Dict[str, Any] | None = None,
    context: Dict[str, Any] | None = None,
    limit: int = 3,
) -> Dict[str, Any]:
    """
    Combine multiple buckets (quick bites, chill cafes, explore),
    score them using prefs + context, and return top N.
    """
    prefs = prefs or {}
    context = context or {}

    buckets = [
        ("quick_bites", "quick_bite"),
        ("chill_cafes", "chill_cafe"),
        ("explore", "explore"),
    ]

    all_candidates: List[Dict[str, Any]] = []

    for category_key, label in buckets:
        places = _search_places_for_category(category_key)
        for p in places:
            # Base category score
            if label == "quick_bite":
                base_score = _score_quick_bite(p)
            elif label == "chill_cafe":
                base_score = _score_cozy_cafe(p)
            else:
                base_score = _score_explore(p)

            # Extra signals
            mins = walking_minutes(p.get("walk_time"))
            distance_score = _normalize_distance_minutes(mins)
            rating_score = _normalize_rating(p.get("rating"))
            pref_score = _preference_match_score(p, prefs, context)
            ctx_score = _context_match_score(p, context)

            # Weighted ranking
            final_score = (
                0.45 * pref_score +
                0.20 * base_score +
                0.15 * rating_score +
                0.10 * distance_score +
                0.10 * ctx_score
            )

            candidate = dict(p)
            candidate["score"] = final_score
            candidate["top_category"] = label
            all_candidates.append(candidate)

    # Deduplicate by place_id or name
    dedup: Dict[str, Dict[str, Any]] = {}
    for p in all_candidates:
        key = p.get("place_id") or p.get("name")
        if not key:
            key = f"unknown-{id(p)}"
        existing = dedup.get(key)
        if not existing or p["score"] > existing.get("score", 0):
            dedup[key] = p

    sorted_places = sorted(dedup.values(), key=lambda x: x["score"], reverse=True)
    top = sorted_places[:limit]

    return {
        "category": "top",
        "places": top
    }
