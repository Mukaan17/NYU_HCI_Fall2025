import os
import requests

GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY")

def build_photo_url(photo_reference: str | None, max_width: int = 400) -> str | None:
    if not photo_reference:
        return None

    key = os.getenv("GOOGLE_API_KEY")
    if not key:
        return None

    return (
        "https://maps.googleapis.com/maps/api/place/photo"
        f"?maxwidth={max_width}"
        f"&photoreference={photo_reference}"
        f"&key={key}"
    )


def nearby_places(lat, lng, place_type="bar", radius=1500, min_rating=3.8, limit=10):
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    params = {
        "location": f"{lat},{lng}",
        "radius": radius,
        "type": place_type,
        "opennow": True,
        "key": GOOGLE_API_KEY,
    }

    r = requests.get(url, params=params, timeout=10)
    r.raise_for_status()

    raw = r.json().get("results", [])
    filtered = [p for p in raw if p.get("rating", 0) >= min_rating]

    filtered.sort(key=lambda x: x.get("rating", 0), reverse=True)

    # Attach photo URLs
    for p in filtered:
        photos = p.get("photos", [])
        photo_ref = photos[0].get("photo_reference") if photos else None
        p["photo_url"] = build_photo_url(photo_ref)

    return filtered[:limit]

