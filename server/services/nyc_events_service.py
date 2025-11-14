import os, requests
from datetime import datetime

DATASET = "tvpp-9vvx"  # NYC Permitted Events dataset

def events_near_bbox(lat_min, lat_max, lng_min, lng_max, limit=5):
    now_iso = datetime.utcnow().isoformat()
    url = f"https://data.cityofnewyork.us/resource/{DATASET}.json"
    params = {
        "$where": f"event_start >= '{now_iso}' AND latitude between {lat_min} and {lat_max} AND longitude between {lng_min} and {lng_max}",
        "$limit": limit
    }
    token = os.environ.get("NYC_APP_TOKEN")
    headers = {"X-App-Token": token} if token else {}
    r = requests.get(url, params=params, headers=headers, timeout=10)
    r.raise_for_status()
    return r.json()
