# server/services/recommendation/events.py
import json
from pathlib import Path
import os

# Get the server root directory (parent of services/recommendation)
SERVER_ROOT = Path(__file__).parent.parent.parent
EVENTS_FILE = SERVER_ROOT / "static" / "events.json"

def fetch_all_external_events():
    """
    Returns raw JSON list of events from your static file.
    If the file doesn't exist, returns an empty list (no error).
    """
    if not EVENTS_FILE.exists():
        # File doesn't exist - this is OK, just return empty list
        return []
    
    try:
        with open(EVENTS_FILE, "r") as f:
            data = json.load(f)
            return data.get("events", [])
    except Exception as ex:
        # Log the error but don't crash - return empty list
        print(f"EVENT LOAD ERROR: {ex}")
        return []
