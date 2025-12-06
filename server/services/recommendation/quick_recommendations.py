# server/services/recommendation/quick_recommendations.py

from __future__ import annotations
from typing import List, Dict, Any
from datetime import datetime

from services.places_service import nearby_places, build_photo_url
from services.directions_service import get_walking_directions, walking_minutes

# Event scrapers
from services.scrapers.brooklyn_bridge_park_scraper import fetch_brooklyn_bridge_park_events
from services.scrapers.downtown_brooklyn_scraper import fetch_downtown_bk_events
from services.scrapers.nyc_parks_scraper import fetch_nyc_parks_events
from services.scrapers.engage_events_service import fetch_engage_events


# -----------------------------------------------------------
# CONFIG
# -----------------------------------------------------------

# NYU Campus Locations
TANDON_LAT = 40.6942
TANDON_LNG = -73.9866
WASHINGTON_SQUARE_LAT = 40.7298
WASHINGTON_SQUARE_LNG = -73.9973

QUICK_CATEGORIES = ["quick_bites", "cozy_cafes", "events", "explore"]

CATEGORY_CONFIG = {
    "quick_bites": {
        "types": ["restaurant", "meal_takeaway"],
        "radius": 800,
    },
    "cozy_cafes": {
        "types": ["cafe", "library"],  # can tweak
        "radius": 1200,
    },
    "explore": {
        "types": ["tourist_attraction", "park", "shopping_mall", "museum"],
        "radius": 2500,
    },
}

# These will be merged with Engage events automatically
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


# For events: the sooner the better
def _normalize_event_time(start_str: str | None) -> float:
    if not start_str:
        return 0.3

    try:
        event_time = datetime.fromisoformat(start_str)
        now = datetime.now()
        delta = (event_time - now).total_seconds()

        if delta < 0:
            return 0.2  # already happened

        # 0 sec → 1.0, 48h → ~0.0
        return max(0.0, min(1.0, 1 - (delta / (48 * 3600))))
    except Exception:
        return 0.3


# -----------------------------------------------------------
# QUICK SCORES
# -----------------------------------------------------------

def _score_quick_bite(place: Dict[str, Any]) -> float:
    mins = walking_minutes(place.get("walk_time"))
    dist = _normalize_distance_minutes(mins)
    rating = _normalize_rating(place.get("rating"))
    busy = 1.0  # temporary placeholder
    return 0.55 * dist + 0.30 * busy + 0.15 * rating


def _score_cozy_cafe(place: Dict[str, Any]) -> float:
    mins = walking_minutes(place.get("walk_time"))
    dist = _normalize_distance_minutes(mins)
    rating = _normalize_rating(place.get("rating"))
    quiet = 1.0  # TODO: noise/busyness later
    return 0.45 * dist + 0.40 * quiet + 0.15 * rating


def _score_explore(place: Dict[str, Any]) -> float:
    mins = walking_minutes(place.get("walk_time"))
    dist = _normalize_distance_minutes(mins)
    rating = _normalize_rating(place.get("rating"))
    landmark = 1.0  # later: weight museums/parks higher
    return 0.50 * dist + 0.20 * rating + 0.30 * landmark


def _score_event(ev: Dict[str, Any]) -> float:
    time_score = _normalize_event_time(ev.get("start"))
    return time_score


# -----------------------------------------------------------
# HELPERS
# -----------------------------------------------------------

def _search_places_for_category(category: str, origin_lat: float = TANDON_LAT, origin_lng: float = TANDON_LNG) -> List[Dict[str, Any]]:
    cfg = CATEGORY_CONFIG.get(category)
    if not cfg:
        return []

    print(f"🔍 _search_places_for_category({category}): Searching near lat={origin_lat}, lng={origin_lng}, radius={cfg['radius']}m")
    raw: List[Dict[str, Any]] = []

    for t in cfg["types"]:
        try:
            places = nearby_places(origin_lat, origin_lng, t, cfg["radius"])
            raw.extend(places)
            print(f"  Found {len(places)} places for type {t}")
        except Exception as e:
            print(f"QuickRecs {category} error:", e)

    # Deduplicate by place_id or name
    dedup = {(p.get("place_id") or p.get("name")): p for p in raw}
    candidates = list(dedup.values())

    enriched: List[Dict[str, Any]] = []
    for p in candidates:
        geom = p.get("geometry", {}).get("location", {})
        lat = geom.get("lat")
        lng = geom.get("lng")
        if not lat or not lng:
            continue

        d = get_walking_directions(origin_lat, origin_lng, lat, lng)
        photos = p.get("photos", [])
        ref = photos[0].get("photo_reference") if photos else None
        photo_url = build_photo_url(ref)

        enriched.append({
            "place_id": p.get("place_id"),  # Include place_id for unique identification
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
        })

    return enriched


def _load_events() -> List[Dict[str, Any]]:
    events = []

    # External scrapers
    for fn in EVENT_SOURCES:
        try:
            events.extend(fn(limit=30))
        except Exception as e:
            print("QuickRecs event scraper error:", e)

    # Engage events (only future ones)
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
# MAIN API
# -----------------------------------------------------------

def get_quick_recommendations(category: str, limit: int = 10, vibe: str | None = None, user_lat: float | None = None, user_lng: float | None = None) -> Dict[str, Any]:
    """
    Returns:
      {
        "category": str,
        "places": [ ... ]  # or events
      }
    """

    category = category.lower()
    
    # Events don't require location (they're scraped, not location-based)
    if category == "events":
        events = _load_events()
        for ev in events:
            ev["score"] = _score_event(ev)
        events.sort(key=lambda x: x["score"], reverse=True)
        return {"category": category, "places": events[:limit]}
    
    # Location-based categories require user location - don't default to Tandon
    if user_lat is None or user_lng is None:
        return {"category": category, "places": [], "error": "No location available"}
    
    origin_lat = user_lat
    origin_lng = user_lng

    # ----------- Quick Bites -----------
    if category == "quick_bites":
        places = _search_places_for_category("quick_bites", origin_lat=origin_lat, origin_lng=origin_lng)
        for p in places:
            p["score"] = _score_quick_bite(p)
        places.sort(key=lambda x: x["score"], reverse=True)
        return {"category": category, "places": places[:limit]}

    # ----------- Cozy Cafes -----------
    if category == "cozy_cafes":
        places = _search_places_for_category("cozy_cafes", origin_lat=origin_lat, origin_lng=origin_lng)
        for p in places:
            p["score"] = _score_cozy_cafe(p)
        places.sort(key=lambda x: x["score"], reverse=True)
        return {"category": category, "places": places[:limit]}

    # ----------- Explore -----------
    if category == "explore":
        places = _search_places_for_category("explore", origin_lat=origin_lat, origin_lng=origin_lng)
        for p in places:
            p["score"] = _score_explore(p)
            # Apply vibe-based scoring if vibe is provided
            if vibe:
                p["score"] = _apply_vibe_scoring(p, vibe, p["score"])
        places.sort(key=lambda x: x["score"], reverse=True)
        return {"category": category, "places": places[:limit]}

    # ----------- Unknown category -----------
    return {"category": category, "places": []}


# -----------------------------------------------------------
# VIBE-BASED SCORING
# -----------------------------------------------------------

def _apply_vibe_scoring(place: Dict[str, Any], vibe: str, base_score: float) -> float:
    """
    Adjust score based on vibe to better match user's current mood.
    """
    name = (place.get("name") or "").lower()
    description = (place.get("description") or "").lower()
    place_type = place.get("type", "").lower()
    
    vibe_boost = 0.0
    
    if vibe == "study":
        # Boost libraries, cafes, quiet places
        if any(k in name for k in ["library", "cafe", "coffee", "study", "quiet"]):
            vibe_boost = 0.3
        elif place_type in ["cafe", "library"]:
            vibe_boost = 0.2
    
    elif vibe == "party":
        # Boost bars, clubs, nightlife
        if any(k in name for k in ["bar", "club", "lounge", "night", "party"]):
            vibe_boost = 0.3
        elif place_type in ["night_club", "bar"]:
            vibe_boost = 0.2
    
    elif vibe == "food_general":
        # Boost restaurants, food places
        if any(k in name for k in ["restaurant", "grill", "diner", "food", "kitchen"]):
            vibe_boost = 0.3
        elif place_type in ["restaurant", "food"]:
            vibe_boost = 0.2
    
    elif vibe == "chill_drinks":
        # Boost bars, cafes for drinks
        if any(k in name for k in ["bar", "pub", "cafe", "lounge", "drinks"]):
            vibe_boost = 0.3
        elif place_type in ["bar", "cafe"]:
            vibe_boost = 0.2
    
    elif vibe == "shopping":
        # Boost shopping places
        if any(k in name for k in ["shop", "store", "mall", "boutique", "market"]):
            vibe_boost = 0.3
        elif place_type in ["shopping_mall", "clothing_store", "department_store"]:
            vibe_boost = 0.2
    
    elif vibe == "fast_bite":
        # Boost fast food, quick service
        if any(k in name for k in ["fast", "quick", "express", "takeout", "grab"]):
            vibe_boost = 0.3
        elif place_type in ["meal_takeaway", "fast_food"]:
            vibe_boost = 0.2
    
    elif vibe == "explore":
        # Boost attractions, points of interest
        if any(k in name for k in ["park", "museum", "gallery", "attraction", "viewpoint"]):
            vibe_boost = 0.3
        elif place_type in ["tourist_attraction", "point_of_interest", "park"]:
            vibe_boost = 0.2
    
    # Apply boost to base score
    return base_score + vibe_boost


# -----------------------------------------------------------
# PREFERENCE MATCHING
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
    # Handle both string and dict values for diet
    diet_raw = prefs.get("diet") or prefs.get("dietary") or ""
    if isinstance(diet_raw, dict):
        diet = str(diet_raw.get("value", diet_raw.get("name", ""))).lower() if diet_raw else ""
    else:
        diet = str(diet_raw).lower() if diet_raw else ""
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
    # Handle both string and dict values for budget/price
    budget_raw = prefs.get("budget") or prefs.get("price") or ""
    if isinstance(budget_raw, dict):
        # If it's a dict, try to extract a string value (e.g., {"value": "cheap"})
        budget = str(budget_raw.get("value", budget_raw.get("name", ""))).lower() if budget_raw else ""
    else:
        budget = str(budget_raw).lower() if budget_raw else ""
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
    limit: int = 10,
    user_lat: float | None = None,
    user_lng: float | None = None,
) -> Dict[str, Any]:
    """
    Combine multiple buckets (quick bites, chill cafes, explore),
    score them using prefs + context, and return top N.
    Uses user location if provided, otherwise defaults to Tandon.
    """
    prefs = prefs or {}
    context = context or {}
    
    # Require user location - don't default to Tandon
    if user_lat is None or user_lng is None:
        print("⚠️ get_top_recommendations_for_user: No location provided")
        return {
            "category": "top",
            "places": [],
            "error": "No location available"
        }
    
    origin_lat = user_lat
    origin_lng = user_lng
    print(f"📍 get_top_recommendations_for_user: Using location lat={origin_lat}, lng={origin_lng}")

    buckets = [
        ("quick_bites", "quick_bite"),
        ("chill_cafes", "chill_cafe"),
        ("explore", "explore"),
    ]

    all_candidates: List[Dict[str, Any]] = []

    for category_key, label in buckets:
        places = _search_places_for_category(category_key, origin_lat=origin_lat, origin_lng=origin_lng)
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
            
            # Apply vibe-based scoring if vibe is provided in context
            vibe = context.get("vibe") if context else None
            base_final_score = (
                0.45 * pref_score +
                0.20 * base_score +
                0.15 * rating_score +
                0.10 * distance_score +
                0.10 * ctx_score
            )
            final_score = _apply_vibe_scoring(p, vibe, base_final_score) if vibe else base_final_score

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
