# server/services/directions_service.py

import os
import logging
from typing import Optional, Dict, Any
import requests
import urllib.parse
from utils.retry import retry_api_call

logger = logging.getLogger(__name__)
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")


def get_distance_matrix(
    origin_lat: float,
    origin_lng: float,
    dest_lat: float,
    dest_lng: float,
    mode: str = "walking"
) -> Optional[Dict[str, Any]]:
    """
    Get accurate distance and duration using Google Distance Matrix API.
    This provides more accurate results than Directions API for distance calculations.
    
    Args:
        origin_lat: Origin latitude
        origin_lng: Origin longitude
        dest_lat: Destination latitude
        dest_lng: Destination longitude
        mode: Travel mode (walking, transit, driving)
    
    Returns:
        Dict with distance_text, duration_text, distance_meters, duration_seconds
        or None on failure
    """
    if not GOOGLE_API_KEY:
        logger.warning("GOOGLE_API_KEY not set, cannot get distance matrix")
        return None
    
    try:
        url = "https://maps.googleapis.com/maps/api/distancematrix/json"
        params = {
            "origins": f"{origin_lat},{origin_lng}",
            "destinations": f"{dest_lat},{dest_lng}",
            "mode": mode,
            "key": GOOGLE_API_KEY,
            "units": "imperial",  # Get results in miles/feet
        }
        
        r = requests.get(url, params=params, timeout=5)
        r.raise_for_status()
        data = r.json()
        
        rows = data.get("rows", [])
        if not rows:
            return None
        
        elements = rows[0].get("elements", [])
        if not elements:
            return None
        
        element = elements[0]
        status = element.get("status")
        
        if status != "OK":
            logger.debug(f"Distance Matrix API returned status: {status}")
            return None
        
        distance = element.get("distance", {})
        duration = element.get("duration", {})
        
        return {
            "distance_text": distance.get("text"),
            "duration_text": duration.get("text"),
            "distance_meters": distance.get("value"),  # Distance in meters
            "duration_seconds": duration.get("value"),  # Duration in seconds
        }
        
    except requests.Timeout:
        logger.debug(f"Timeout getting distance matrix from {origin_lat},{origin_lng} to {dest_lat},{dest_lng}")
        return None
    except requests.RequestException as e:
        # Check if it's an I/O error on closed file (common with concurrent requests)
        error_str = str(e).lower()
        if "i/o operation on closed file" in error_str or "bad file descriptor" in error_str:
            logger.debug(f"Distance matrix: connection closed during request (likely timeout/cancellation)")
        else:
            logger.debug(f"Error getting distance matrix: {e}")
        return None
    except (OSError, IOError) as io_err:
        # Handle I/O errors specifically (file descriptor issues)
        error_str = str(io_err).lower()
        if "i/o operation on closed file" in error_str or "bad file descriptor" in error_str:
            logger.debug(f"Distance matrix: I/O error (connection closed)")
        else:
            logger.debug(f"Distance matrix I/O error: {io_err}")
        return None
    except Exception as e:
        # Check if it's an I/O error
        error_str = str(e).lower()
        if "i/o operation on closed file" in error_str or "bad file descriptor" in error_str:
            logger.debug(f"Distance matrix: connection closed during request")
        else:
            logger.debug(f"Distance matrix error: {e}")
        return None


def _get_directions_for_mode(
    origin_lat: float,
    origin_lng: float,
    dest_lat: float,
    dest_lng: float,
    mode: str
) -> Optional[Dict[str, Any]]:
    """
    Get directions for a specific mode (walking or transit).
    Uses Distance Matrix API for accurate distance/duration, then Directions API for route details.
    Returns route data or None on failure.
    """
    if not GOOGLE_API_KEY:
        return None

    try:
        # First, get accurate distance and duration from Distance Matrix API
        distance_matrix = get_distance_matrix(origin_lat, origin_lng, dest_lat, dest_lng, mode)
        
        # Then get route details from Directions API
        base_url = "https://maps.googleapis.com/maps/api/directions/json"
        params = {
            "origin": f"{origin_lat},{origin_lng}",
            "destination": f"{dest_lat},{dest_lng}",
            "mode": mode,
            "key": GOOGLE_API_KEY,
            "alternatives": "false",  # Get only the best route
        }

        r = requests.get(base_url, params=params, timeout=5)
        r.raise_for_status()
        data = r.json()

        routes = data.get("routes", [])
        if not routes:
            # If Directions API fails but Distance Matrix worked, return that
            if distance_matrix:
                q = urllib.parse.urlencode({
                    "api": 1,
                    "origin": f"{origin_lat},{origin_lng}",
                    "destination": f"{dest_lat},{dest_lng}",
                    "travelmode": mode
                })
                maps_link = f"https://www.google.com/maps/dir/?{q}"
                return {
                    "duration_seconds": distance_matrix.get("duration_seconds", 0),
                    "duration_text": distance_matrix.get("duration_text"),
                    "distance_text": distance_matrix.get("distance_text"),
                    "maps_link": maps_link,
                    "polyline": None,
                    "mode": mode,
                }
            return None

        route = routes[0]
        leg = route.get("legs", [{}])[0]
        
        # Use Distance Matrix results if available (more accurate), otherwise use Directions API
        if distance_matrix:
            duration_seconds = distance_matrix.get("duration_seconds", 0)
            duration_text = distance_matrix.get("duration_text")
            distance_text = distance_matrix.get("distance_text")
        else:
            duration_seconds = leg.get("duration", {}).get("value", 0)
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
        # Check if it's an I/O error on closed file (common with concurrent requests)
        error_str = str(e).lower()
        if "i/o operation on closed file" in error_str or "bad file descriptor" in error_str:
            logger.debug(f"{mode.capitalize()} directions: connection closed during request (likely timeout/cancellation)")
        else:
            logger.debug(f"Error getting {mode} directions: {e}")
        return None
    except (OSError, IOError) as io_err:
        # Handle I/O errors specifically (file descriptor issues)
        error_str = str(io_err).lower()
        if "i/o operation on closed file" in error_str or "bad file descriptor" in error_str:
            logger.debug(f"{mode.capitalize()} directions: I/O error (connection closed)")
        else:
            logger.warning(f"{mode.capitalize()} directions I/O error: {io_err}")
        return None
    except Exception as ex:
        # Check if it's an I/O error
        error_str = str(ex).lower()
        if "i/o operation on closed file" in error_str or "bad file descriptor" in error_str:
            logger.debug(f"{mode.capitalize()} directions: connection closed during request")
        else:
            logger.warning(f"{mode.capitalize()} directions error: {ex}")
        return None


@retry_api_call(max_attempts=2, min_wait=0.5, max_wait=2)
def get_walking_only_directions(
    origin_lat: float,
    origin_lng: float,
    dest_lat: float,
    dest_lng: float
) -> Optional[Dict[str, Any]]:
    """
    Get walking-only directions from Google Directions API.
    Use this for quick recommendations where walking distance is more important than transit speed.
    FAST MODE: short timeout, returns None on failure (UI can still show place).
    """
    if not GOOGLE_API_KEY:
        logger.warning("GOOGLE_API_KEY not set, cannot get directions")
        return None
    
    return _get_directions_for_mode(origin_lat, origin_lng, dest_lat, dest_lng, "walking")


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
    from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeoutError, as_completed
    
    walking_result = None
    transit_result = None
    
    # Use ThreadPoolExecutor to fetch both in parallel
    # Use context manager to ensure proper cleanup - it will wait for tasks to complete
    with ThreadPoolExecutor(max_workers=2) as executor:
        walking_future = executor.submit(
            _get_directions_for_mode, origin_lat, origin_lng, dest_lat, dest_lng, "walking"
        )
        transit_future = executor.submit(
            _get_directions_for_mode, origin_lat, origin_lng, dest_lat, dest_lng, "transit"
        )
        
        # Wait for both to complete (with timeout)
        # Use as_completed to handle timeouts gracefully
        futures = {walking_future: "walking", transit_future: "transit"}
        
        try:
            for future in as_completed(futures, timeout=5):
                mode = futures[future]
                try:
                    result = future.result(timeout=0.1)  # Should be ready since as_completed returned it
                    if mode == "walking":
                        walking_result = result
                    else:
                        transit_result = result
                except Exception as e:
                    logger.debug(f"Error getting {mode} directions result: {e}")
        except FutureTimeoutError:
            # Timeout waiting for results - cancel remaining futures
            logger.debug("Timeout waiting for directions results")
            for future, mode in futures.items():
                if not future.done():
                    future.cancel()
                    try:
                        # Wait a bit for cancellation to propagate
                        future.result(timeout=0.5)
                    except:
                        pass  # Expected for cancelled/timeout futures

    # Choose the shorter/quicker route
    # Use Distance Matrix API for accurate comparison if available
    best_result = None
    
    if walking_result and transit_result:
        # Get accurate distances from Distance Matrix API for comparison
        walking_matrix = get_distance_matrix(origin_lat, origin_lng, dest_lat, dest_lng, "walking")
        transit_matrix = get_distance_matrix(origin_lat, origin_lng, dest_lat, dest_lng, "transit")
        
        # Use Distance Matrix duration for accurate comparison if available
        walking_duration = walking_matrix.get("duration_seconds") if walking_matrix else walking_result.get("duration_seconds", float('inf'))
        transit_duration = transit_matrix.get("duration_seconds") if transit_matrix else transit_result.get("duration_seconds", float('inf'))
        
        # Choose the faster route
        if walking_duration <= transit_duration:
            best_result = walking_result
            # Update with Distance Matrix data if available (more accurate)
            if walking_matrix:
                best_result["distance_text"] = walking_matrix.get("distance_text")
                best_result["duration_text"] = walking_matrix.get("duration_text")
        else:
            best_result = transit_result
            # Update with Distance Matrix data if available (more accurate)
            if transit_matrix:
                best_result["distance_text"] = transit_matrix.get("distance_text")
                best_result["duration_text"] = transit_matrix.get("duration_text")
    elif walking_result:
        best_result = walking_result
        # Enhance with Distance Matrix if available
        walking_matrix = get_distance_matrix(origin_lat, origin_lng, dest_lat, dest_lng, "walking")
        if walking_matrix:
            best_result["distance_text"] = walking_matrix.get("distance_text")
            best_result["duration_text"] = walking_matrix.get("duration_text")
    elif transit_result:
        best_result = transit_result
        # Enhance with Distance Matrix if available
        transit_matrix = get_distance_matrix(origin_lat, origin_lng, dest_lat, dest_lng, "transit")
        if transit_matrix:
            best_result["distance_text"] = transit_matrix.get("distance_text")
            best_result["duration_text"] = transit_matrix.get("duration_text")
    
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
