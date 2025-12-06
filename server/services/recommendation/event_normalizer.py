# server/services/recommendation/event_normalizer.py
from typing import Dict, Any, Optional
from datetime import datetime
from services.directions_service import get_walking_directions
from services.places_service import build_photo_url

TANDON_LAT = 40.6942
TANDON_LNG = -73.9866


def normalize_event(ev: Dict[str, Any], origin_lat: float | None = None, origin_lng: float | None = None) -> Dict[str, Any]:
    """
    Convert your raw event record into a unified place/event card.
    Works for all events (NYU Engage, external events, scraped events).
    
    Args:
        ev: Event dictionary
        origin_lat: Origin latitude for distance calculation (defaults to Tandon if not provided)
        origin_lng: Origin longitude for distance calculation (defaults to Tandon if not provided)
    """

    # Extract fields safely
    name = ev.get("name")
    desc = ev.get("description") or ev.get("summary") or None
    start = parse_date(ev.get("start"))
    end = parse_date(ev.get("end"))

    # Location fields
    address = ev.get("address") or ev.get("location") or None
    lat = ev.get("lat")
    lng = ev.get("lng")

    # Use provided origin or default to Tandon
    origin_lat = origin_lat if origin_lat is not None else TANDON_LAT
    origin_lng = origin_lng if origin_lng is not None else TANDON_LNG

    # Compute walking info (only if event has coordinates)
    directions = None
    if lat and lng:
        try:
            directions = get_walking_directions(
                origin_lat, origin_lng, lat, lng
            )
        except Exception:
            directions = None

    return {
        "type": "event",
        "source": "external_event",

        "name": name,
        "description": desc,
        "address": address,

        "location": {
            "lat": lat,
            "lng": lng,
        },

        "start": start,
        "end": end,

        "walk_time": directions["duration_text"] if directions else None,
        "distance": directions["distance_text"] if directions else None,
        "maps_link": directions["maps_link"] if directions else None,

        "photo_url": build_photo_url(ev.get("photo_reference")),
        "rating": 0.0,  # events don't have ratings → neutral
    }


def parse_date(value: Optional[str]):
    """
    Parse ISO date safely. Returns datetime or None.
    """
    if not value:
        return None

    try:
        return datetime.fromisoformat(value.replace("Z", ""))
    except Exception:
        return None
