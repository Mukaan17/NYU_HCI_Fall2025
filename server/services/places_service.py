# services/places_service.py
import os
import logging
import requests
from utils.retry import retry_api_call
from services.popularity_service import get_busyness

logger = logging.getLogger(__name__)

# Use ONE key name consistently everywhere
GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY")


def build_photo_url(photo_reference: str | None, max_width: int = 400) -> str | None:
    if not photo_reference:
        return None

    return (
        "https://maps.googleapis.com/maps/api/place/photo"
        f"?maxwidth={max_width}"
        f"&photoreference={photo_reference}"
        f"&key={GOOGLE_API_KEY}"
    )


@retry_api_call(max_attempts=3, min_wait=1, max_wait=5)
def nearby_places(
    lat,
    lng,
    place_type: str = "cafe",
    radius: int = 1500,
    open_now: bool = False,
    min_rating: float = 3.8,
    limit: int = 10,
):
    """
    Fetch nearby places from Google Places API with retry logic and timeout.

    This version:
    - Supports `open_now` flag
    - Applies a basic min_rating filter
    - Limits number of results
    - Attaches `photo_url` when possible
    """
    if not GOOGLE_API_KEY:
        logger.warning("GOOGLE_API_KEY not set, cannot fetch places")
        return []

    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

    params = {
        "location": f"{lat},{lng}",
        "radius": radius,
        "type": place_type,
        "key": GOOGLE_API_KEY,
    }

    if open_now:
        params["opennow"] = "true"

    # Small tweak: for cafes, bias to coffee terms
    if place_type == "cafe":
        params["keyword"] = "coffee"

    try:
        resp = requests.get(url, params=params, timeout=10)
        resp.raise_for_status()

        raw = resp.json().get("results", [])
        if not raw:
            logger.debug(f"No places found for {place_type} at {lat},{lng}")
            return []

        # basic quality filter
        filtered = [p for p in raw if p.get("rating", 0) >= min_rating]

        # attach photo URL
        for p in filtered:
            photos = p.get("photos", [])
            if photos:
                ref = photos[0].get("photo_reference")
                p["photo_url"] = build_photo_url(ref)

            # 🔥 Add live/heuristic busyness score
            p["busyness"] = get_busyness(p.get("place_id"), {
                "rating": p.get("rating"),
                "user_ratings_total": p.get("user_ratings_total")
            })

        logger.debug(f"Found {len(filtered)} places for {place_type}")
        return filtered[:limit]

    except requests.Timeout:
        logger.error(f"Timeout fetching places for {place_type}")
        raise
    except requests.RequestException as e:
        logger.error(f"Error fetching places: {e}")
        raise
