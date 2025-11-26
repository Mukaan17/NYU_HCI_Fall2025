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

TANDON_LAT = 40.6942
TANDON_LNG = -73.9866

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

        d = get_walking_directions(TANDON_LAT, TANDON_LNG, lat, lng)
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

def get_quick_recommendations(category: str, limit: int = 10) -> Dict[str, Any]:
    """
    Returns:
      {
        "category": str,
        "places": [ ... ]  # or events
      }
    """

    category = category.lower()

    # ----------- Quick Bites -----------
    if category == "quick_bites":
        places = _search_places_for_category("quick_bites")
        for p in places:
            p["score"] = _score_quick_bite(p)
        places.sort(key=lambda x: x["score"], reverse=True)
        return {"category": category, "places": places[:limit]}

    # ----------- Cozy Cafes -----------
    if category == "cozy_cafes":
        places = _search_places_for_category("cozy_cafes")
        for p in places:
            p["score"] = _score_cozy_cafe(p)
        places.sort(key=lambda x: x["score"], reverse=True)
        return {"category": category, "places": places[:limit]}

    # ----------- Explore -----------
    if category == "explore":
        places = _search_places_for_category("explore")
        for p in places:
            p["score"] = _score_explore(p)
        places.sort(key=lambda x: x["score"], reverse=True)
        return {"category": category, "places": places[:limit]}

    # ----------- Events -----------
    if category == "events":
        events = _load_events()
        for ev in events:
            ev["score"] = _score_event(ev)
        events.sort(key=lambda x: x["score"], reverse=True)
        return {"category": category, "places": events[:limit]}

    # ----------- Unknown category -----------
    return {"category": category, "places": []}
