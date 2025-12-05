# routes/dashboard_routes.py
from flask import Blueprint, jsonify, g
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
    # System calendar only - handled client-side
    # ------------------------------------------------------

    # ------------------------------------------------------
    # QUICK RECOMMENDATIONS (all 4 categories)
    # ------------------------------------------------------
    quick_recs = {}
    try:
        quick_recs = {
            "quick_bites": get_quick_recommendations("quick_bites", limit=6).get("places", []),
            "cozy_cafes": get_quick_recommendations("cozy_cafes", limit=6).get("places", []),
            "explore": get_quick_recommendations("explore", limit=6).get("places", []),
            "events": get_quick_recommendations("events", limit=6).get("places", []),
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

