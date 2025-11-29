import os
import logging
import requests
import math

logger = logging.getLogger(__name__)
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

def haversine(lat1, lng1, lat2, lng2):
    """
    Return distance in meters between two lat/lng points.
    """
    R = 6371000  # Earth radius

    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)

    a = (math.sin(dphi/2)**2 +
         math.cos(phi1) * math.cos(phi2) * math.sin(dlambda/2)**2)

    return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1 - a))


# ---------------------------------------------------------
# NYU Address Normalization (critical for Engage events)
# ---------------------------------------------------------

def normalize_engage_location(raw: str) -> str:
    """
    Convert NYU Engage room codes into real addresses Google can geocode.
    """
    if not raw:
        return None

    text = raw.strip().lower()

    # --- Tandon / Brooklyn shortcuts ---
    if "dibner" in text:
        return "Bern Dibner Library, 5 MetroTech Center, Brooklyn, NY"

    if "tandon" in text or "370 jay" in text:
        return "370 Jay Street, Brooklyn, NY"

    # MTC / MetroTech variations
    if "mtc" in text or "metrotech" in text:
        return "5 MetroTech Center, Brooklyn, NY"

    # Paulson Center Manhattan
    if "paulson" in text:
        return "Paulson Center, 181 Mercer St, New York, NY"

    # Fall back to raw—with “NYU” added to increase accuracy
    return f"{raw}, New York University, NY"


# ---------------------------------------------------------
# Google Geocoding API
# ---------------------------------------------------------

def geocode_address(address: str):
    """
    Convert a human-readable address into lat/lng using Google Geocoding.
    """
    if not address:
        return None

    if not GOOGLE_API_KEY:
        logger.warning("[GEOCODE] Missing GOOGLE_API_KEY")
        return None

    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {
        "address": address,
        "key": GOOGLE_API_KEY
    }

    try:
        r = requests.get(url, params=params, timeout=10)
        r.raise_for_status()
        data = r.json()

        if data.get("status") != "OK":
            logger.warning(f"[GEOCODE] Failed: {data.get('status')}")
            return None

        loc = data["results"][0]["geometry"]["location"]
        return {
            "lat": loc["lat"],
            "lng": loc["lng"]
        }

    except Exception as e:
        logger.error(f"[GEOCODE ERROR] {e}", exc_info=True)
        return None