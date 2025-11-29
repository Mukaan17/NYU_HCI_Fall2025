# server/services/recommendation/events.py
import json
from pathlib import Path

EVENTS_FILE = Path("static/events.json")

def fetch_all_external_events():
    """
    Returns raw JSON list of events from your static file.
    """
    try:
        with open(EVENTS_FILE, "r") as f:
            data = json.load(f)
            return data.get("events", [])
    except Exception as ex:
        print("EVENT LOAD ERROR:", ex)
        return []
