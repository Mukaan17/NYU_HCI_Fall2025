# server/services/directions_service.py

import os
import logging
from typing import Optional, Dict, Any
import requests
import urllib.parse
from utils.retry import retry_api_call

logger = logging.getLogger(__name__)
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")


def _get_directions_for_mode(
    origin_lat: float,
    origin_lng: float,
    dest_lat: float,
    dest_lng: float,
    mode: str
) -> Optional[Dict[str, Any]]:
    """
    Get directions for a specific mode (walking or transit).
    Returns route data or None on failure.
    """
    if not GOOGLE_API_KEY:
        return None

    try:
        base_url = "https://maps.googleapis.com/maps/api/directions/json"
        params = {
            "origin": f"{origin_lat},{origin_lng}",
            "destination": f"{dest_lat},{dest_lng}",
            "mode": mode,
            "key": GOOGLE_API_KEY,
        }

        r = requests.get(base_url, params=params, timeout=5)
        r.raise_for_status()
        data = r.json()

        routes = data.get("routes", [])
        if not routes:
            return None

        route = routes[0]
        leg = route.get("legs", [{}])[0]
        duration_seconds = leg.get("duration", {}).get("value", 0)  # Duration in seconds for comparison
        duration_text = leg.get("duration", {}).get("text")
        distance_text = leg.get("distance", {}).get("text")

        # Extract polyline for route visualization
        polyline_points = []
        overview_polyline = route.get("overview_polyline", {}).get("points")
        
        if overview_polyline:
            # Decode Google's encoded polyline string to coordinates
            try:
                import polyline as polyline_lib
                decoded_coords = polyline_lib.decode(overview_polyline)
                # Convert to format expected by iOS: [[lat, lng], [lat, lng], ...]
                polyline_points = [[lat, lng] for lat, lng in decoded_coords]
            except ImportError:
                logger.warning("polyline library not installed, route visualization will not work")
                # Fallback: try to decode manually (simple implementation)
                polyline_points = _decode_polyline_fallback(overview_polyline)
            except Exception as e:
                logger.warning(f"Error decoding polyline: {e}")
                polyline_points = _decode_polyline_fallback(overview_polyline)

        q = urllib.parse.urlencode({
            "api": 1,
            "origin": f"{origin_lat},{origin_lng}",
            "destination": f"{dest_lat},{dest_lng}",
            "travelmode": mode
        })
        maps_link = f"https://www.google.com/maps/dir/?{q}"

        return {
            "duration_seconds": duration_seconds,
            "duration_text": duration_text,
            "distance_text": distance_text,
            "maps_link": maps_link,
            "polyline": polyline_points if polyline_points else None,
            "mode": mode,
        }

    except requests.Timeout:
        logger.debug(f"Timeout getting {mode} directions from {origin_lat},{origin_lng} to {dest_lat},{dest_lng}")
        return None
    except requests.RequestException as e:
        logger.debug(f"Error getting {mode} directions: {e}")
        return None
    except Exception as ex:
        logger.warning(f"{mode.capitalize()} directions error: {ex}")
        return None


@retry_api_call(max_attempts=2, min_wait=0.5, max_wait=2)
def get_walking_directions(
    origin_lat: float,
    origin_lng: float,
    dest_lat: float,
    dest_lng: float
) -> Optional[Dict[str, Any]]:
    """
    Get directions from Google Directions API.
    Automatically chooses between walking and transit, whichever is shorter/quicker.
    FAST MODE: short timeout, returns None on failure (UI can still show place).
    """

    if not GOOGLE_API_KEY:
        logger.warning("GOOGLE_API_KEY not set, cannot get directions")
        return None

    # Fetch both walking and transit directions in parallel
    from concurrent.futures import ThreadPoolExecutor
    
    walking_result = None
    transit_result = None
    
    # Use ThreadPoolExecutor to fetch both in parallel
    with ThreadPoolExecutor(max_workers=2) as executor:
        walking_future = executor.submit(
            _get_directions_for_mode, origin_lat, origin_lng, dest_lat, dest_lng, "walking"
        )
        transit_future = executor.submit(
            _get_directions_for_mode, origin_lat, origin_lng, dest_lat, dest_lng, "transit"
        )
        
        # Wait for both to complete (with timeout)
        try:
            walking_result = walking_future.result(timeout=4)
        except Exception as e:
            logger.debug(f"Error fetching walking directions: {e}")
        
        try:
            transit_result = transit_future.result(timeout=4)
        except Exception as e:
            logger.debug(f"Error fetching transit directions: {e}")

    # Choose the shorter/quicker route
    best_result = None
    
    if walking_result and transit_result:
        # Compare by duration_seconds
        if walking_result.get("duration_seconds", float('inf')) <= transit_result.get("duration_seconds", float('inf')):
            best_result = walking_result
        else:
            best_result = transit_result
    elif walking_result:
        best_result = walking_result
    elif transit_result:
        best_result = transit_result
    
    if not best_result:
        logger.debug(f"No routes found from {origin_lat},{origin_lng} to {dest_lat},{dest_lng}")
        return None
    
    # Remove internal duration_seconds field but keep mode for frontend
    best_result.pop("duration_seconds", None)
    # Keep "mode" field so frontend knows if it's walking or transit
    
    return best_result


def _decode_polyline_fallback(encoded: str) -> list:
    """
    Simple fallback polyline decoder if polyline library is not available.
    Decodes Google's encoded polyline format.
    """
    try:
        coords = []
        index = 0
        lat = 0
        lng = 0
        
        while index < len(encoded):
            # Decode latitude
            shift = 0
            result = 0
            while True:
                b = ord(encoded[index]) - 63
                index += 1
                result |= (b & 0x1f) << shift
                shift += 5
                if b < 0x20:
                    break
            dlat = ~(result >> 1) if (result & 1) else (result >> 1)
            lat += dlat
            
            # Decode longitude
            shift = 0
            result = 0
            while True:
                b = ord(encoded[index]) - 63
                index += 1
                result |= (b & 0x1f) << shift
                shift += 5
                if b < 0x20:
                    break
            dlng = ~(result >> 1) if (result & 1) else (result >> 1)
            lng += dlng
            
            coords.append([lat / 1e5, lng / 1e5])
        
        return coords
    except Exception as e:
        logger.warning(f"Fallback polyline decode error: {e}")
        return []


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
