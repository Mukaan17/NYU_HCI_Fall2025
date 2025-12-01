# routes/calendar_routes.py
from flask import Blueprint, jsonify, g
import logging
import os

from utils.auth import require_auth
from services.calendar_service import (
    fetch_today_events,
    fetch_free_time_blocks,
)
from services.calendar_suggestion_service import (
    compute_next_free_block,
    build_suggestion_message,
)

calendar_bp = Blueprint("calendar", __name__)
logger = logging.getLogger(__name__)


@calendar_bp.route("/today", methods=["GET"])
@require_auth
def today():
    user = g.current_user
    req_id = g.get("request_id", "unknown")

    if not user.google_refresh_token:
        logger.warning(f"[{req_id}] No Google Calendar linked for user {user.id}")
        return jsonify({"error": "No Google Calendar linked"}), 400

    try:
        events = fetch_today_events(
            refresh_token=user.google_refresh_token,
            client_id=os.getenv("GOOGLE_CLIENT_ID"),
            client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
        )

        logger.info(f"[{req_id}] Returned {len(events)} calendar events for user {user.id}")
        return jsonify({"events": events}), 200

    except Exception as e:
        logger.error(f"[{req_id}] GOOGLE CAL ERROR: {e}", exc_info=True)
        return jsonify({"error": "Failed to fetch Google Calendar events"}), 500


@calendar_bp.route("/free_time", methods=["GET"])
@require_auth
def free_time():
    """
    Returns all free blocks today.
    """
    user = g.current_user
    req_id = g.get("request_id", "unknown")

    if not user.google_refresh_token:
        logger.warning(f"[{req_id}] No Google Calendar linked for user {user.id}")
        return jsonify({"error": "No Google Calendar linked"}), 400

    try:
        blocks = fetch_free_time_blocks(
            refresh_token=user.google_refresh_token,
            client_id=os.getenv("GOOGLE_CLIENT_ID"),
            client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
        )

        logger.info(f"[{req_id}] Returned {len(blocks)} free blocks for user {user.id}")
        return jsonify({"free_blocks": blocks}), 200

    except Exception as e:
        logger.error(f"[{req_id}] FREE TIME ERROR: {e}", exc_info=True)
        return jsonify({"error": "Failed to compute free time"}), 500


@calendar_bp.route("/next_free", methods=["GET"])
@require_auth
def next_free():
    """
    1. Fetch today's calendar events
    2. Compute today's free blocks
    3. Pick the NEXT free block
    4. Run the free-time recommender:
         - Only if block >= 30 min
         - Only if block is between two events
         - Suggest event first, fallback to place
    """

    user = g.current_user
    req_id = g.get("request_id", "unknown")

    if not user.google_refresh_token:
        logger.warning(f"[{req_id}] No Google Calendar linked for user {user.id}")
        return jsonify({"error": "No Google Calendar linked"}), 400

    try:
        # ------------------------------------------------------
        # 1. Load today's events (Google Calendar)
        # ------------------------------------------------------
        from services.calendar_service import fetch_today_events, fetch_free_time_blocks
        from services.free_time_recommender import get_free_time_suggestion
        from services.calendar_suggestion_service import compute_next_free_block

        events = fetch_today_events(
            refresh_token=user.google_refresh_token,
            client_id=os.getenv("GOOGLE_CLIENT_ID"),
            client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
        )

        # ------------------------------------------------------
        # 2. Compute today's free blocks
        # ------------------------------------------------------
        free_blocks = fetch_free_time_blocks(
            refresh_token=user.google_refresh_token,
            client_id=os.getenv("GOOGLE_CLIENT_ID"),
            client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
        )

        # ------------------------------------------------------
        # 3. Identify the next free block
        # ------------------------------------------------------
        next_block = compute_next_free_block(free_blocks)

        if not next_block:
            return jsonify({
                "has_free_time": False,
                "next_free": None,
                "suggestion": None,
                "message": "You're fully booked for the rest of today."
            }), 200

        # ------------------------------------------------------
        # 4. Generate free-time recommendation (new engine!)
        # ------------------------------------------------------
        suggestion_payload = get_free_time_suggestion(
            free_block=next_block,
            events=events,
            user_profile={"default_vibe": user.vibe if hasattr(user, "vibe") else ""}
        )

        # ------------------------------------------------------
        # 5. Format response
        # ------------------------------------------------------
        if not suggestion_payload.get("should_suggest"):
            return jsonify({
                "has_free_time": True,
                "next_free": next_block,
                "suggestion": None,
                "message": f"You have free time from {next_block['start']} to {next_block['end']}."
            }), 200

        # Suggestion exists
        return jsonify({
            "has_free_time": True,
            "next_free": next_block,
            "suggestion": suggestion_payload.get("suggestion"),
            "suggestion_type": suggestion_payload.get("type"),
            "message": suggestion_payload.get("message"),
        }), 200

    except Exception as e:
        logger.error(f"[{req_id}] NEXT FREE ERROR: {e}", exc_info=True)
        return jsonify({"error": "Failed to compute next free time"}), 500

@calendar_bp.route("/next_free_block", methods=["GET"])
@require_auth
def next_free_block():
    """
    Find the next free block in the user's calendar today.
    """
    user = g.current_user

    if not user.google_refresh_token:
        return jsonify({"error": "No Google Calendar linked"}), 400

    try:
        from services.calendar_suggestion_service import find_next_free_block
        from services.calendar_service import fetch_today_events

        events = fetch_today_events(
            refresh_token=user.google_refresh_token,
            client_id=os.getenv("GOOGLE_CLIENT_ID"),
            client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
        )

        free = find_next_free_block(events)

        if not free:
            return jsonify({
                "status": "no_free_time",
                "message": "No free time left today"
            })

        return jsonify({
            "status": "success",
            "free_block": free
        })

    except Exception as e:
        print("FREE BLOCK ERROR:", e)
        return jsonify({"error": "Failed to compute free time"}), 500

@calendar_bp.route("/recommendation", methods=["GET"])
@require_auth
def calendar_recommendation():
    """
    Full free-time recommendation endpoint:
      - Detect next free block
      - Must be >= 30 minutes
      - Must be between events
      - Generates a suggested place/event
    Returns JSON dashboard package.
    """

    user = g.current_user

    if not user.google_refresh_token:
        return jsonify({"error": "No Google Calendar linked"}), 400

    try:
        from services.calendar_service import fetch_free_time_blocks
        from services.calendar_suggestion_service import compute_next_free_block
        from services.free_time_recommender import generate_free_time_recommendation

        # Fetch free blocks
        blocks = fetch_free_time_blocks(
            refresh_token=user.google_refresh_token,
            client_id=os.getenv("GOOGLE_CLIENT_ID"),
            client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
        )

        # Find next free block
        next_block = compute_next_free_block(blocks)

        # Build recommendation response
        package = generate_free_time_recommendation(next_block)

        return jsonify(package), 200

    except Exception as e:
        print("FREE TIME RECOMMENDATION ERROR:", e)
        return jsonify({"error": "Failed to build free-time recommendation"}), 500
