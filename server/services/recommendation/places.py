# services/recommendation/places.py
from typing import Dict, Any
from services.places_service import build_photo_url


def normalize_place(p: Dict[str, Any], directions: Dict[str, Any] | None):
    """
    Convert raw Google Places JSON into a clean, uniform card.
    """

    loc = p.get("geometry", {}).get("location", {})
    photo_ref = None
    if p.get("photos"):
        photo_ref = p["photos"][0].get("photo_reference")

    return {
        "type": "place",
        "source": "google_places",

        "name": p.get("name"),
        "description": None,

        "address": p.get("vicinity"),
        "location": {
            "lat": loc.get("lat"),
            "lng": loc.get("lng"),
        },

        "walk_time": directions["duration_text"] if directions else None,
        "distance": directions["distance_text"] if directions else None,
        "maps_link": directions["maps_link"] if directions else None,

        "photo_url": build_photo_url(photo_ref),

        "rating": p.get("rating", 0),
        "start": None,
        "end": None,
    }
