# routes/dashboard_routes.py
from flask import Blueprint, jsonify, g, request
import logging

from utils.auth import require_auth
import utils.limiter as limiter_module

from services.weather_service import current_weather
from services.recommendation.quick_recommendations import get_quick_recommendations

dashboard_bp = Blueprint("dashboard", __name__)
logger = logging.getLogger(__name__)


@dashboard_bp.route("/dashboard", methods=["GET"])
@require_auth
@limiter_module.limiter.limit("10 per minute")
def dashboard():
    """
    Dashboard API combines:
      - Current weather
      - Next free block today
      - Free-time recommendation (if >= 30 min gap)
      - All quick recommendation categories
    """
    user = g.current_user
    req_id = g.get("request_id", "unknown")

    logger.info(f"[{req_id}] Dashboard request from user {user.id} (email: {user.email})")

    # ------------------------------------------------------
    # WEATHER
    # ------------------------------------------------------
    try:
        weather = current_weather()
    except Exception as e:
        logger.error(f"[{req_id}] Weather fetch error: {e}", exc_info=True)
        weather = {"error": "Weather unavailable"}

    # ------------------------------------------------------
    # CALENDAR
    # System calendar is handled entirely client-side on iOS
    # The backend does not fetch calendar data - it's managed by the device
    # Calendar events are processed locally in the iOS app using EventKit
    # ------------------------------------------------------

    # ------------------------------------------------------
    # QUICK RECOMMENDATIONS (all 4 categories)
    # ------------------------------------------------------
    # Get location from request if provided
    user_lat = None
    user_lng = None
    lat_raw = request.args.get("latitude")
    lng_raw = request.args.get("longitude")
    if lat_raw and lng_raw:
        try:
            user_lat = float(lat_raw)
            user_lng = float(lng_raw)
            # Validate coordinates
            from utils.validation import validate_coordinates
            is_valid, error_msg = validate_coordinates(user_lat, user_lng)
            if not is_valid:
                logger.warning(f"[{req_id}] Invalid coordinates: {error_msg}")
                user_lat = None
                user_lng = None
        except (ValueError, TypeError):
            logger.warning(f"[{req_id}] Invalid latitude/longitude format: {lat_raw}, {lng_raw}")
            user_lat = None
            user_lng = None
    
    quick_recs = {}
    try:
        # Only fetch recommendations if location is available
        if user_lat is not None and user_lng is not None:
            quick_recs = {
                "quick_bites": get_quick_recommendations("quick_bites", limit=6, user_lat=user_lat, user_lng=user_lng).get("places", []),
                "cozy_cafes": get_quick_recommendations("cozy_cafes", limit=6, user_lat=user_lat, user_lng=user_lng).get("places", []),
                "explore": get_quick_recommendations("explore", limit=6, user_lat=user_lat, user_lng=user_lng).get("places", []),
                "events": get_quick_recommendations("events", limit=6, user_lat=user_lat, user_lng=user_lng).get("places", []),
            }
        else:
            # No location available - return empty recommendations
            logger.info(f"[{req_id}] No location provided, returning empty recommendations")
            quick_recs = {
                "quick_bites": [],
                "cozy_cafes": [],
                "explore": [],
                "events": [],
            }
    except Exception as e:
        logger.error(f"[{req_id}] Quick recommendations error: {e}", exc_info=True)
        quick_recs = {
            "quick_bites": [],
            "cozy_cafes": [],
            "explore": [],
            "events": [],
        }

    # ------------------------------------------------------
    # FINAL RESPONSE PACKAGE
    # ------------------------------------------------------
    return jsonify({
        "weather": weather,
        "calendar_linked": False,  # System calendar only - handled client-side
        "next_free": None,
        "free_time_suggestion": None,
        "quick_recommendations": quick_recs,
    }), 200

