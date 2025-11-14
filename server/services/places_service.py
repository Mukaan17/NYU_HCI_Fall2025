import os, requests
GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY")

def nearby_places(lat, lng, place_type="bar", radius=1500, min_rating=3.8, limit=10):
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    params = {
        "location": f"{lat},{lng}",
        "radius": radius,
        "type": place_type,
        "opennow": True,
        "key": GOOGLE_API_KEY
    }
    r = requests.get(url, params=params, timeout=10)
    r.raise_for_status()
    data = r.json().get("results", [])
    results = [p for p in data if p.get("rating", 0) >= min_rating]
    results.sort(key=lambda x: x.get("rating", 0), reverse=True)
    return results[:limit]
