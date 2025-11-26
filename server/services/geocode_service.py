import requests
import os

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

# Simple in-memory cache so we don't geocode the same event repeatedly
_GEOCODE_CACHE = {}

def geocode(address: str):
    """
    Convert a textual NYU Engage event location into lat/lng.
    Returns None if not found.
    """
    if not address:
        return None

    if address in _GEOCODE_CACHE:
        return _GEOCODE_CACHE[address]

    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {
        "address": address,
        "key": GOOGLE_API_KEY
    }

    try:
        r = requests.get(url, params=params, timeout=10)
        data = r.json()

        if data.get("status") != "OK":
            return None

        loc = data["results"][0]["geometry"]["location"]
        coords = {"lat": loc["lat"], "lng": loc["lng"]}

        _GEOCODE_CACHE[address] = coords
        return coords

    except Exception as e:
        print("GEOCODE ERROR:", e)
        return None
