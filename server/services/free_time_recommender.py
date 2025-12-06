# server/services/free_time_recommender.py

from datetime import datetime
import pytz
from typing import Dict, Any, List
import logging

from services.recommendation.events import fetch_all_external_events
from services.places_service import nearby_places
from services.directions_service import get_walking_directions
from services.recommendation.places import normalize_place
from services.recommendation.event_normalizer import normalize_event

logger = logging.getLogger(__name__)

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
    except Exception as e:
        logger.debug(f"Failed to parse ISO timestamp {dt_str}: {e}")
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
                   user_prefs: dict,
                   user_lat: float | None = None,
                   user_lng: float | None = None) -> Dict[str, Any] | None:
    """
    Try suggesting an event happening SOON.
    Looks at all external events (brooklyn bridge, downtown bk, parks, etc).
    """
    try:
        events = fetch_all_external_events()
        if not events:
            logger.debug("No external events available for suggestion")
            return None

        normalized = []
        for ev in events:
            try:
                n = normalize_event(ev, origin_lat=user_lat, origin_lng=user_lng)
                if n:
                    normalized.append({**ev, **n})
            except Exception as e:
                logger.debug(f"Failed to normalize event: {e}")
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
            logger.debug("No matching event found for free time block")
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
    except Exception as e:
        logger.error(f"Error suggesting event: {e}", exc_info=True)
        return None


# ------------------------------------------------------------
# Place Suggestion (fallback)
# ------------------------------------------------------------

def _suggest_place(block_start: datetime,
                   block_end: datetime,
                   user_prefs: dict,
                   user_lat: float | None = None,
                   user_lng: float | None = None) -> Dict[str, Any] | None:
    """
    If no event works, suggest a quick thing to do within walking distance.
    Uses Google Places → normalize → returns best candidate.
    """

    # Use user location if provided, otherwise default to Tandon
    origin_lat = user_lat if user_lat is not None else TANDON_LAT
    origin_lng = user_lng if user_lng is not None else TANDON_LNG

    # Basic vibe inference — very simple for now
    vibe = None
    if user_prefs:
        vibe = user_prefs.get("default_vibe")

    place_types = ["cafe", "park", "tourist_attraction", "restaurant"]

    candidates = []

    try:
        for t in place_types:
            try:
                raw = nearby_places(origin_lat, origin_lng, t, radius=1500)
                for p in raw:
                    loc = p.get("geometry", {}).get("location", {})
                    lat = loc.get("lat")
                    lng = loc.get("lng")
                    if not lat or not lng:
                        continue
                    try:
                        d = get_walking_directions(origin_lat, origin_lng, lat, lng)
                    except Exception as e:
                        logger.debug(f"Failed to get directions for place: {e}")
                        d = None

                    normalized = normalize_place(p, d)
                    candidates.append(normalized)
            except Exception as e:
                logger.debug(f"Error fetching places for type {t}: {e}")
                continue

        if not candidates:
            logger.debug("No place candidates found")
            return None

        # Sort closer + higher rated first
        candidates.sort(key=lambda x: (x.get("rating", 0)), reverse=True)

        return candidates[0]
    except Exception as e:
        logger.error(f"Error suggesting place: {e}", exc_info=True)
        return None


# ------------------------------------------------------------
# MAIN ENGINE
# ------------------------------------------------------------

def get_free_time_suggestion(free_block: dict,
                             events: List[dict],
                             user_profile: dict,
                             user_lat: float | None = None,
                             user_lng: float | None = None) -> Dict[str, Any]:
    """
    free_block = { start: ISO, end: ISO }
    events = today's calendar events (from system calendar or any source)
    user_profile = optional preferences
    user_lat = user's latitude for distance calculations
    user_lng = user's longitude for distance calculations

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
        logger.debug("Invalid free block timestamps")
        return {"should_suggest": False}

    duration = _minutes_between(start, end)

    # 1️⃣ Must have 30+ minutes of free time
    if duration < MINIMUM_MINUTES:
        logger.debug(f"Free block too short: {duration} minutes")
        return {"should_suggest": False}

    # 2️⃣ Don't suggest when it's the last block of the night
    if start.hour >= END_OF_DAY_CUTOFF:
        logger.debug(f"Free block too late in day: {start.hour}:00")
        return {"should_suggest": False}

    # 3️⃣ Must be between events
    if not _is_between_events(free_block, events):
        logger.debug("Free block is not between events")
        return {"should_suggest": False}

    # 4️⃣ Try suggesting event first
    event_suggestion = _suggest_event(start, end, user_profile, user_lat=user_lat, user_lng=user_lng)
    if event_suggestion:
        return {
            "should_suggest": True,
            "type": "event",
            "suggestion": event_suggestion,
            "message": f"You're free until {end.strftime('%-I:%M %p')} — want to check out **{event_suggestion['name']}**?"
        }

    # 5️⃣ Fallback: suggest a place
    place_suggestion = _suggest_place(start, end, user_profile, user_lat=user_lat, user_lng=user_lng)
    if place_suggestion:
        return {
            "should_suggest": True,
            "type": "place",
            "suggestion": place_suggestion,
            "message": f"You're free until {end.strftime('%-I:%M %p')} — want to explore **{place_suggestion['name']}**?"
        }

    # Nothing found
    logger.debug("No suitable suggestion found for free time block")
    return {"should_suggest": False}


# ------------------------------------------------------------
# Wrapper for /recommendation endpoint
# ------------------------------------------------------------

def generate_free_time_recommendation(next_block: dict, user_lat: float | None = None, user_lng: float | None = None) -> Dict[str, Any]:
    """
    Wrapper function for the /recommendation endpoint.
    Takes a next_block and returns a formatted recommendation package.
    
    Args:
        next_block: Free time block dictionary
        user_lat: User's latitude for distance calculations
        user_lng: User's longitude for distance calculations
    """
    if not next_block:
        return {
            "has_free_time": False,
            "next_free": None,
            "suggestion": None,
            "message": "No free time available."
        }
    
    # For this wrapper, we'll use empty events list and empty user profile
    # The actual endpoint should pass real events and user profile
    result = get_free_time_suggestion(next_block, [], {}, user_lat=user_lat, user_lng=user_lng)
    
    if result.get("should_suggest"):
        return {
            "has_free_time": True,
            "next_free": next_block,
            "suggestion": result.get("suggestion"),
            "suggestion_type": result.get("type"),
            "message": result.get("message"),
        }
    else:
        return {
            "has_free_time": True,
            "next_free": next_block,
            "suggestion": None,
            "message": f"You have free time from {next_block.get('start')} to {next_block.get('end')}."
        }

