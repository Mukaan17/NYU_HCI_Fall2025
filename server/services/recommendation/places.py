# server/services/recommendation/places.py

from typing import List, Dict, Any

from services.places_service import nearby_places, build_photo_url
from services.directions_service import get_walking_directions
from services.vibes import vibe_to_place_types

TANDON_LAT = 40.6942
TANDON_LNG = -73.9866


def normalize_place(p: Dict[str, Any], directions: Dict[str, Any] | None) -> Dict[str, Any]:
    """
    Convert a Google Places result into our unified card structure.
    """

    return {
        "type": "place",
        "source": "google_places",

        "name": p.get("name"),
        "description": None,

        "start": None,
        "end": None,

        "address": p.get("vicinity"),
        "location": {
            "lat": p.get("geometry", {}).get("location", {}).get("lat"),
            "lng": p.get("geometry", {}).get("location", {}).get("lng"),
        },

        "walk_time": directions["duration_text"] if directions else None,
        "distance": directions["distance_text"] if directions else None,
        "maps_link": directions["maps_link"] if directions else None,

        "photo_url": build_photo_url(
            p.get("photos", [{}])[0].get("photo_reference")
            if p.get("photos") else None
        ),

        "rating": p.get("rating", 0),
    }


def fetch_places_for_vibe(vibe: str, limit: int = 8) -> List[Dict[str, Any]]:
    """
    FAST MODE:
    - Only queries the FIRST place_type from vibe_to_place_types
    - Limit total places to `limit`
    """

    place_types, radius = vibe_to_place_types(vibe)

    if not place_types:
        return []

    raw_results: List[Dict[str, Any]] = []

    for t in place_types[:1]:  # Only the first type → fewer API calls
        try:
            raw_results.extend(
                nearby_places(
                    TANDON_LAT,
                    TANDON_LNG,
                    place_type=t,
                    radius=radius,
                    limit=limit * 2,
                )
            )
        except Exception as ex:
            print("Google Places error:", ex)

    if not raw_results:
        return []

    dedup = {(p.get("place_id") or p.get("name")): p for p in raw_results}
    uniques = list(dedup.values())[:limit]

    enriched: List[Dict[str, Any]] = []
    for p in uniques:
        geom = p.get("geometry", {}).get("location", {})
        lat, lng = geom.get("lat"), geom.get("lng")
        if not lat or not lng:
            continue

        directions = get_walking_directions(TANDON_LAT, TANDON_LNG, lat, lng)

        enriched.append(normalize_place(p, directions))

    return enriched
