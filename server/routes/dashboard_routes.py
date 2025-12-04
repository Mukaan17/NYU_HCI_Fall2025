# routes/dashboard_routes.py
from flask import Blueprint, jsonify, g
import os
import logging

from utils.auth import require_auth

from services.weather_service import current_weather
from services.calendar_service import fetch_free_time_blocks, fetch_today_events
from services.calendar_suggestion_service import compute_next_free_block
from services.free_time_recommender import get_free_time_suggestion

from services.recommendation.quick_recommendations import get_quick_recommendations

dashboard_bp = Blueprint("dashboard", __name__)
logger = logging.getLogger(__name__)

@dashboard_bp.route("/dashboard", methods=["GET"])
@require_auth
def dashboard():
    print("📡 DASHBOARD ROUTE HIT")
    """
    Dashboard API combines:
      - Current weather
      - Next free block today
      - Free-time recommendation (if >= 30 min gap)
      - All quick recommendation categories
    """

    user = g.current_user
    req_id = g.get("request_id", "unknown")

    if not user.google_refresh_token:
        logger.warning(f"[{req_id}] Dashboard load without Google linked")
        linked_calendar = False
    else:
        linked_calendar = True

    # ------------------------------------------------------
    # WEATHER
    # ------------------------------------------------------
    weather = current_weather()

    # ------------------------------------------------------
    # CALENDAR (free time, next free block, suggestion)
    # ------------------------------------------------------
    next_block = None
    suggestion_payload = None

    if linked_calendar:
        try:
            free_blocks = fetch_free_time_blocks(
                refresh_token=user.google_refresh_token,
                client_id=os.getenv("GOOGLE_CLIENT_ID"),
                client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
            )

            next_block = compute_next_free_block(free_blocks)

            # Only generate free-time suggestion if block exists
            if next_block:
                events = fetch_today_events(
                    refresh_token=user.google_refresh_token,
                    client_id=os.getenv("GOOGLE_CLIENT_ID"),
                    client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
                )

                suggestion_payload = get_free_time_suggestion(
                    free_block=next_block,
                    events=events,
                    user_profile=user.get_preferences()
                )

        except Exception as e:
            logger.error(f"[{req_id}] DASHBOARD CALENDAR ERROR: {e}", exc_info=True)

    # ------------------------------------------------------
    # QUICK RECOMMENDATIONS (all 4 categories)
    # ------------------------------------------------------
    quick_recs = {
        "quick_bites": get_quick_recommendations("quick_bites", limit=6).get("places", []),
        "cozy_cafes": get_quick_recommendations("cozy_cafes", limit=6).get("places", []),
        "explore": get_quick_recommendations("explore", limit=6).get("places", []),
        "events": get_quick_recommendations("events", limit=6).get("places", []),
    }

    # ------------------------------------------------------
    # FINAL RESPONSE PACKAGE
    # ------------------------------------------------------
    return jsonify({
        "weather": weather,
        "calendar_linked": linked_calendar,
        "next_free": next_block,
        "free_time_suggestion": suggestion_payload,
        "quick_recommendations": quick_recs,
    }), 200
