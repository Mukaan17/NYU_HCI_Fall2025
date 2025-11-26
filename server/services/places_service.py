# services/places_service.py
import os
import requests

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


def nearby_places(lat, lng, place_type="cafe", radius=1500, min_rating=3.8, limit=10):
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

    params = {
        "location": f"{lat},{lng}",
        "radius": radius,
        "type": place_type,
        "opennow": True,
        "key": GOOGLE_API_KEY,
    }

    # ★ STUDY FIX: keyword=coffee improves Google accuracy
    if place_type == "cafe":
        params["keyword"] = "coffee"

    resp = requests.get(url, params=params, timeout=10)
    resp.raise_for_status()

    raw = resp.json().get("results", [])
    if not raw:
        return []

    # basic quality filter
    filtered = [p for p in raw if p.get("rating", 0) >= min_rating]

    # attach photo URL
    for p in filtered:
        photos = p.get("photos", [])
        if photos:
            p["photo_url"] = build_photo_url(photos[0].get("photo_reference"))

    return filtered[:limit]
