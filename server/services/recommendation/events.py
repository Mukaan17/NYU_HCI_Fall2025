# services/recommendation/events.py

from typing import List, Dict, Any

# Import scrapers
from services.scrapers.engage_events_service import fetch_engage_events
from services.scrapers.brooklyn_bridge_park_scraper import fetch_brooklyn_bridge_park_events
from services.scrapers.downtown_brooklyn_scraper import fetch_downtown_bk_events
from services.scrapers.nyc_parks_scraper import fetch_nyc_parks_events
from services.scrapers.donyc_scraper import fetch_donyc_popups


# ============================================================
# NORMALIZATION — all events must match this format
# ============================================================

def normalize_event(e: Dict[str, Any], source: str) -> Dict[str, Any]:
    """
    Convert all scraper outputs into the unified event card structure used by the app.
    """

    return {
        "type": "event",
        "source": source,

        "name": e.get("name"),
        "description": e.get("description"),

        # Times
        "start": e.get("start"),
        "end": e.get("end"),

        # Location / links
        "address": e.get("address") or e.get("location"),
        "location": None,        # No lat/lng for events
        "maps_link": e.get("url"),
        "photo_url": e.get("image"),

        # For compatibility with place cards
        "rating": None,
        "walk_time": None,
        "distance": None,
    }


# ============================================================
# FETCH ALL EXTERNAL EVENTS (except Engage-on-campus-only)
# ============================================================

def fetch_all_external_events(limit: int = 50) -> List[Dict[str, Any]]:
    results: List[Dict[str, Any]] = []

    # Downtown Brooklyn
    try:
        dt = fetch_downtown_bk_events(limit=limit)
        results += [normalize_event(e, "downtown_brooklyn") for e in dt]
    except Exception as ex:
        print("Downtown Brooklyn error:", ex)

    # Brooklyn Bridge Park
    try:
        bbp = fetch_brooklyn_bridge_park_events(limit=limit)
        results += [normalize_event(e, "brooklyn_bridge_park") for e in bbp]
    except Exception as ex:
        print("Brooklyn Bridge Park error:", ex)

    # NYC Parks
    try:
        parks = fetch_nyc_parks_events(limit=limit)
        results += [normalize_event(e, "nyc_parks") for e in parks]
    except Exception as ex:
        print("NYC Parks error:", ex)

    # DoNYC Popups
    try:
        dn = fetch_donyc_popups(limit=limit)
        results += [normalize_event(e, "donyc_popups") for e in dn]
    except Exception as ex:
        print("DoNYC error:", ex)

    return results


# ============================================================
# FETCH ONLY ENGAGE EVENTS (used for explicit ON-CAMPUS queries)
# ============================================================

def fetch_engage_only(limit: int = 50) -> List[Dict[str, Any]]:
    """
    Used ONLY when user explicitly asks for on-campus events.
    """
    try:
        ev = fetch_engage_events(days_ahead=7, limit=limit)
        return [normalize_event(e, "nyu_engage") for e in ev]
    except Exception as ex:
        print("Engage error:", ex)
        return []
