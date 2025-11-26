# server/services/directions_service.py

import os
from typing import Optional, Dict, Any
import requests
import urllib.parse

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")


def get_walking_directions(
    origin_lat: float,
    origin_lng: float,
    dest_lat: float,
    dest_lng: float
) -> Optional[Dict[str, Any]]:
    """
    FAST MODE: very short timeout.
    If anything fails, return None (UI can still show place).
    """

    if not GOOGLE_API_KEY:
        return None

    try:
        base_url = "https://maps.googleapis.com/maps/api/directions/json"
        params = {
            "origin": f"{origin_lat},{origin_lng}",
            "destination": f"{dest_lat},{dest_lng}",
            "mode": "walking",
            "key": GOOGLE_API_KEY,
        }

        r = requests.get(base_url, params=params, timeout=2)
        r.raise_for_status()
        data = r.json()

        routes = data.get("routes", [])
        if not routes:
            return None

        leg = routes[0].get("legs", [{}])[0]
        duration_text = leg.get("duration", {}).get("text")
        distance_text = leg.get("distance", {}).get("text")

        q = urllib.parse.urlencode({
            "api": 1,
            "origin": f"{origin_lat},{origin_lng}",
            "destination": f"{dest_lat},{dest_lng}",
            "travelmode": "walking"
        })
        maps_link = f"https://www.google.com/maps/dir/?{q}"

        return {
            "duration_text": duration_text,
            "distance_text": distance_text,
            "maps_link": maps_link,
        }

    except Exception as ex:
        print("Directions error:", ex)
        return None


def walking_minutes(walk_time: Optional[str]) -> Optional[int]:
    """
    Convert strings like '14 mins' or '1 hour 5 mins' into total minutes.
    """

    if not walk_time:
        return None

    text = walk_time.lower()
    total = 0

    try:
        if "hour" in text:
            parts = text.split("hour")[0].strip().split()
            for p in parts:
                if p.isdigit():
                    total += int(p) * 60
                    break

        if "min" in text:
            parts = text.split("min")[0].strip().split()
            for p in reversed(parts):
                if p.isdigit():
                    total += int(p)
                    break

        return total if total > 0 else None
    except Exception:
        return None
