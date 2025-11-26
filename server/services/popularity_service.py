# server/services/popularity_service.py

from typing import Dict, Any
from datetime import datetime

# Try to import the popular-times scraper
try:
    from populartimes import get_id
    POPULARTIMES_AVAILABLE = True
except Exception:
    POPULARTIMES_AVAILABLE = False


# --------------------------------------------------------------
# Fallback Heuristic Busyness (rating, reviews, time-of-day)
# --------------------------------------------------------------

def heuristic_busyness(place: Dict[str, Any]) -> Dict[str, Any]:
    """
    Estimate busyness heuristically using:
      - review count
      - rating
      - time of day

    Output:
      {
        "busyness": 0.0–1.0,
        "label": "quiet" | "moderate" | "busy",
        "source": "heuristic"
      }
    """

    reviews = place.get("user_ratings_total") or 0
    rating = place.get("rating") or 0.0

    # Normalize review count into 0.0–1.0 popularity
    try:
        reviews = int(reviews)
    except:
        reviews = 0

    base_popularity = min(1.0, reviews / 300.0)
    rating_factor = 0.5 + (float(rating) / 10.0)
    popularity = min(1.0, base_popularity * rating_factor)

    # Time-of-day bump
    hour = datetime.now().hour
    if 17 <= hour <= 21:
        popularity = min(1.0, popularity + 0.15)
    elif 11 <= hour <= 14:
        popularity = min(1.0, popularity + 0.10)

    # Labeling
    if popularity < 0.33:
        label = "quiet"
    elif popularity < 0.66:
        label = "moderate"
    else:
        label = "busy"

    return {
        "busyness": popularity,
        "label": label,
        "source": "heuristic"
    }


# --------------------------------------------------------------
# Google Popular Times Scraping
# --------------------------------------------------------------

def google_populartimes(place_id: str, api_key: str) -> Dict[str, Any]:
    """
    Try to fetch live popularity from Google using populartimes library.
    Returns:
      {
        "busyness": 0.0–1.0,
        "label": "...",
        "source": "google"
      }

    Raises exceptions if scraping fails.
    """

    if not POPULARTIMES_AVAILABLE:
        raise RuntimeError("populartimes is not installed")

    data = get_id(api_key, place_id)

    current = data.get("current_popularity")
    if current is None:
        raise RuntimeError("Google data missing current_popularity")

    # Normalize 0–100 → 0.0–1.0
    b = max(0.0, min(1.0, float(current) / 100.0))

    if b < 0.33:
        label = "quiet"
    elif b < 0.66:
        label = "moderate"
    else:
        label = "busy"

    return {
        "busyness": b,
        "label": label,
        "source": "google"
    }


# --------------------------------------------------------------
# Unified Busyness Fetcher (scraper + fallback)
# --------------------------------------------------------------

def get_busyness(place_id: str, place: Dict[str, Any]) -> Dict[str, Any]:
    """
    Try real Google live busyness first.
    If it fails → fallback heuristic.
    """

    api_key = place.get("api_key")  # optional — you can pass differently

    # Try scraper
    if POPULARTIMES_AVAILABLE and api_key and place_id:
        try:
            return google_populartimes(place_id, api_key)
        except Exception:
            pass  # fallback below

    # Fallback
    return heuristic_busyness(place)
