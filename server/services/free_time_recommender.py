# server/services/free_time_recommender.py

from datetime import datetime
import pytz
from typing import Dict, Any, List

from services.recommendation.events import fetch_all_external_events
from services.places_service import nearby_places
from services.directions_service import get_walking_directions
from services.recommendation.places import normalize_place
from services.recommendation.event_normalizer import normalize_event


TANDON_LAT = 40.6942
TANDON_LNG = -73.9866

MINIMUM_MINUTES = 30     # must have 30+ minutes to suggest something
END_OF_DAY_CUTOFF = 20   # do NOT suggest things after 8:00 PM


# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

def _parse_iso(dt_str: str):
    """Safely parse ISO timestamps."""
    try:
        return datetime.fromisoformat(dt_str)
    except:
        return None


def _minutes_between(start: datetime, end: datetime) -> int:
    return int((end - start).total_seconds() // 60)


def _is_between_events(block: dict, events: List[dict]) -> bool:
    """
    Returns True if the free block is between two events (not end-of-day).
    block = { start, end }
    events = [ {start, end}, ... ]
    """
    start = _parse_iso(block["start"])
    end = _parse_iso(block["end"])
    if not start or not end:
        return False

    # If it's the last block of the day → skip
    if end.hour >= END_OF_DAY_CUTOFF:
        return False

    return True


# ------------------------------------------------------------
# Event Suggestion (highest priority)
# ------------------------------------------------------------

def _suggest_event(block_start: datetime,
                   block_end: datetime,
                   user_prefs: dict) -> Dict[str, Any] | None:
    """
    Try suggesting an event happening SOON.
    Looks at all external events (brooklyn bridge, downtown bk, parks, etc).
    """
    events = fetch_all_external_events()
    if not events:
        return None

    normalized = []
    for ev in events:
        try:
            n = normalize_event(ev)
            if n:
                normalized.append({**ev, **n})
        except:
            continue

    next_event = None
    soonest = float("inf")

    for ev in normalized:
        start = ev.get("start")
        if not start:
            continue

        # Only future events
        if start <= block_start:
            continue

        delta = (start - block_start).total_seconds()
        if 0 < delta < soonest:
            soonest = delta
            next_event = ev

    if not next_event:
        return None

    return {
        "type": "event",
        "name": next_event.get("name"),
        "start": next_event.get("start").isoformat() if next_event.get("start") else None,
        "location": next_event.get("location"),
        "description": next_event.get("description"),
        "address": next_event.get("location"),
        "maps_link": next_event.get("url"),
        "photo_url": next_event.get("image"),
    }


# ------------------------------------------------------------
# Place Suggestion (fallback)
# ------------------------------------------------------------

def _suggest_place(block_start: datetime,
                   block_end: datetime,
                   user_prefs: dict) -> Dict[str, Any] | None:
    """
    If no event works, suggest a quick thing to do within walking distance.
    Uses Google Places → normalize → returns best candidate.
    """

    # Basic vibe inference — very simple for now
    vibe = None
    if user_prefs:
        vibe = user_prefs.get("default_vibe")

    place_types = ["cafe", "park", "tourist_attraction", "restaurant"]

    candidates = []

    for t in place_types:
        raw = nearby_places(TANDON_LAT, TANDON_LNG, t, radius=1500)
        for p in raw:
            loc = p.get("geometry", {}).get("location", {})
            lat = loc.get("lat")
            lng = loc.get("lng")
            if not lat or not lng:
                continue
            try:
                d = get_walking_directions(TANDON_LAT, TANDON_LNG, lat, lng)
            except:
                d = None

            normalized = normalize_place(p, d)
            candidates.append(normalized)

    if not candidates:
        return None

    # Sort closer + higher rated first
    candidates.sort(key=lambda x: (x.get("rating", 0)), reverse=True)

    return candidates[0]


# ------------------------------------------------------------
# MAIN ENGINE
# ------------------------------------------------------------

def get_free_time_suggestion(free_block: dict,
                             events: List[dict],
                             user_profile: dict) -> Dict[str, Any]:
    """
    free_block = { start: ISO, end: ISO }
    events = today's Google Calendar events
    user_profile = optional preferences

    Returns:
      {
        "should_suggest": bool,
        "suggestion": <card>,
        "type": "event" | "place",
        "message": str
      }
    """

    if not free_block:
        return {"should_suggest": False}

    tz = pytz.timezone("America/New_York")
    now = datetime.now(tz)

    start = _parse_iso(free_block["start"])
    end = _parse_iso(free_block["end"])

    if not start or not end:
        return {"should_suggest": False}

    duration = _minutes_between(start, end)

    # 1️⃣ Must have 30+ minutes of free time
    if duration < MINIMUM_MINUTES:
        return {"should_suggest": False}

    # 2️⃣ Don’t suggest when it's the last block of the night
    if start.hour >= END_OF_DAY_CUTOFF:
        return {"should_suggest": False}

    # 3️⃣ Must be between events
    if not _is_between_events(free_block, events):
        return {"should_suggest": False}

    # 4️⃣ Try suggesting event first
    event_suggestion = _suggest_event(start, end, user_profile)
    if event_suggestion:
        return {
            "should_suggest": True,
            "type": "event",
            "suggestion": event_suggestion,
            "message": f"You're free until {end.strftime('%-I:%M %p')} — want to check out **{event_suggestion['name']}**?"
        }

    # 5️⃣ Fallback: suggest a place
    place_suggestion = _suggest_place(start, end, user_profile)
    if place_suggestion:
        return {
            "should_suggest": True,
            "type": "place",
            "suggestion": place_suggestion,
            "message": f"You're free until {end.strftime('%-I:%M %p')} — want to explore **{place_suggestion['name']}**?"
        }

    # Nothing found
    return {"should_suggest": False}
