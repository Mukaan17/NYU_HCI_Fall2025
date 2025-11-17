# server/services/directions_service.py
import os
from typing import Dict, Optional
from utils.helpers import decode_polyline
import requests

GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY")
 

def get_walking_directions(
    origin_lat: float,
    origin_lng: float,
    dest_lat: float,
    dest_lng: float,
) -> Optional[Dict[str, str]]:
    """
    Wrapper around Google Directions API (walking mode).
    Returns dict with 'distance_text', 'duration_text', 'maps_link' or None on error.
    """
    if not GOOGLE_API_KEY:
        print("WARNING: GOOGLE_API_KEY not set, skipping directions.")
        return None

    url = "https://maps.googleapis.com/maps/api/directions/json"
    params = {
        "origin": f"{origin_lat},{origin_lng}",
        "destination": f"{dest_lat},{dest_lng}",
        "mode": "walking",
        "key": GOOGLE_API_KEY,
    }

    try:
        resp = requests.get(url, params=params, timeout=10)
        data = resp.json()
        if data.get("status") != "OK":
            print("Directions API status:", data.get("status"))
            return None

        leg = data["routes"][0]["legs"][0]
        distance_text = leg["distance"]["text"]
        duration_text = leg["duration"]["text"]

        maps_link = (
            "https://www.google.com/maps/dir/?api=1"
            f"&origin={origin_lat},{origin_lng}"
            f"&destination={dest_lat},{dest_lng}"
            "&travelmode=walking"
        )

        overview_poly = data["routes"][0].get("overview_polyline", {}).get("points")
        
        return {
            "distance_text": distance_text,
            "duration_text": duration_text,
            "maps_link": maps_link,
            "polyline": decode_polyline(overview_poly)
        }
    
    except Exception as e:
        print("Directions error:", e)
        return None


def walking_minutes(duration_text: str) -> int:
    """
    Extract minutes from a string like:
      '7 min', '12 mins', '1 hour 5 mins'
    Very simple parser; fallback is a big number.
    """
    if not duration_text:
        return 999

    text = duration_text.lower()
    parts = text.split()
    total = 0

    try:
        for i, token in enumerate(parts):
            if token.startswith("hour"):
                hrs = int(parts[i - 1])
                total += hrs * 60
            if token.startswith("min"):
                mins = int(parts[i - 1])
                total += mins

        if total == 0:
            # fallback: grab the first integer we see
            for token in parts:
                if token.isdigit():
                    return int(token)
            return 999

        return total
    except Exception:
        return 999
