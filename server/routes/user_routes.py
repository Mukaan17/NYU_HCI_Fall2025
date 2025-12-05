# server/routes/user_routes.py

from flask import Blueprint, request, jsonify, g
import logging

from models.db import db
from utils.auth import require_auth
from services.recommendation.preference_utils import sanitize_preferences
from utils.validation import validate_activity_payload_size

logger = logging.getLogger(__name__)
user_bp = Blueprint("user", __name__)


@user_bp.route("/me", methods=["GET"])
@require_auth
def me():
    try:
        user = g.current_user
        logger.debug(
            f"Request {g.get('request_id', 'unknown')}: User profile requested - {user.id}"
        )
        return jsonify(
            {
                "id": user.id,
                "email": user.email,
                "first_name": user.first_name,
                "home_address": user.get_home_address(),  # Decrypted
                "preferences": user.get_preferences(),
                "settings": user.get_settings(),
                "recent_activity": user.get_recent_activity(),
            }
        )
    except Exception as e:
        logger.error(
            f"Request {g.get('request_id', 'unknown')}: Error getting user profile - {e}",
            exc_info=True,
        )
        return (
            jsonify(
                {
                    "error": "Internal server error",
                    "request_id": g.get("request_id", "unknown"),
                }
            ),
            500,
        )


@user_bp.route("/preferences", methods=["GET", "POST"])
@require_auth
def preferences():
    try:
        user = g.current_user

        if request.method == "GET":
            logger.debug(
                f"Request {g.get('request_id', 'unknown')}: Preferences requested - {user.id}"
            )
            return jsonify(user.get_preferences())

        # POST: update prefs (with sanitization)
        data = request.get_json(force=True) or {}
        cleaned = sanitize_preferences(data)

        prefs = user.get_preferences()
        prefs.update(cleaned)

        user.set_preferences(prefs)
        db.session.commit()

        logger.info(
            f"Request {g.get('request_id', 'unknown')}: Preferences updated - {user.id}"
        )

        return jsonify(prefs)

    except Exception as e:
        logger.error(
            f"Request {g.get('request_id', 'unknown')}: Error with preferences - {e}",
            exc_info=True,
        )
        db.session.rollback()
        return (
            jsonify(
                {
                    "error": "Internal server error",
                    "request_id": g.get("request_id", "unknown"),
                }
            ),
            500,
        )


@user_bp.route("/settings", methods=["GET", "POST"])
@require_auth
def settings():
    try:
        user = g.current_user

        if request.method == "GET":
            logger.debug(
                f"Request {g.get('request_id', 'unknown')}: Settings requested - {user.id}"
            )
            return jsonify(user.get_settings())

        data = request.get_json(force=True) or {}
        settings = user.get_settings()
        settings.update(data)

        user.set_settings(settings)
        db.session.commit()
        logger.info(
            f"Request {g.get('request_id', 'unknown')}: Settings updated - {user.id}"
        )

        return jsonify(settings)
    except Exception as e:
        logger.error(
            f"Request {g.get('request_id', 'unknown')}: Error with settings - {e}",
            exc_info=True,
        )
        db.session.rollback()
        return (
            jsonify(
                {
                    "error": "Internal server error",
                    "request_id": g.get("request_id", "unknown"),
                }
            ),
            500,
        )


@user_bp.route("/activity", methods=["POST"])
@require_auth
def activity():
    """
    Frontend can call this whenever user interacts:
    {
      "type": "clicked_recommendation",
      "place_id": "...",
      "name": "...",
      "vibe": "chill",
      "score": 0.87
    }
    """
    try:
        user = g.current_user
        data = request.get_json(force=True) or {}

        if not data.get("type"):
            logger.warning(
                f"Request {g.get('request_id', 'unknown')}: Activity missing type field"
            )
            return jsonify({"error": "Missing 'type' field"}), 400
        
        # Validate activity payload size
        is_valid, error_msg = validate_activity_payload_size(data)
        if not is_valid:
            logger.warning(
                f"Request {g.get('request_id', 'unknown')}: Activity payload too large - {user.id}"
            )
            return jsonify({"error": error_msg}), 400

        user.add_activity(data)
        db.session.commit()
        logger.debug(
            f"Request {g.get('request_id', 'unknown')}: Activity logged - {user.id}, "
            f"type: {data.get('type')}"
        )

        return jsonify({"status": "ok"}), 200
    except Exception as e:
        logger.error(
            f"Request {g.get('request_id', 'unknown')}: Error logging activity - {e}",
            exc_info=True,
        )
        db.session.rollback()
        return (
            jsonify(
                {
                    "error": "Internal server error",
                    "request_id": g.get("request_id", "unknown"),
                }
            ),
            500,
        )


@user_bp.route("/profile", methods=["GET", "POST"])
@require_auth
def profile():
    """
    Get or update user profile (first_name, home_address).
    GET: Returns current profile
    POST: Updates profile with { "first_name": "...", "home_address": "..." }
    """
    try:
        user = g.current_user
        
        if request.method == "GET":
            logger.debug(
                f"Request {g.get('request_id', 'unknown')}: Profile requested - {user.id}"
            )
            return jsonify({
                "first_name": user.first_name,
                "home_address": user.get_home_address(),  # Decrypted
            })
        
        # POST: update profile
        data = request.get_json(force=True) or {}
        
        # Update first name if provided
        if "first_name" in data:
            first_name = (data.get("first_name") or "").strip()
            user.first_name = first_name if first_name else None
        
        # Update home address if provided (encrypted)
        if "home_address" in data:
            home_address = (data.get("home_address") or "").strip()
            try:
                user.set_home_address(home_address if home_address else None)
            except Exception as e:
                logger.error(f"Failed to encrypt home address: {e}")
                return jsonify({"error": "Failed to save home address"}), 500
        
        db.session.commit()
        
        logger.info(
            f"Request {g.get('request_id', 'unknown')}: Profile updated - {user.id}"
        )
        
        return jsonify({
            "first_name": user.first_name,
            "home_address": user.get_home_address(),  # Decrypted
        })
        
    except Exception as e:
        logger.error(
            f"Request {g.get('request_id', 'unknown')}: Error with profile - {e}",
            exc_info=True,
        )
        db.session.rollback()
        return (
            jsonify(
                {
                    "error": "Internal server error",
                    "request_id": g.get("request_id", "unknown"),
                }
            ),
            500,
        )


@user_bp.route("/notification_token", methods=["POST"])
@require_auth
def notification_token():
    """
    Frontend sends Expo push token or APNs token:
    { "token": "..." }
    """
    try:
        user = g.current_user
        data = request.get_json(force=True) or {}
        token = data.get("token")

        if not token:
            logger.warning(
                f"Request {g.get('request_id', 'unknown')}: Notification token missing"
            )
            return jsonify({"error": "Missing 'token'"}), 400

        user.notification_token = token
        db.session.commit()
        logger.info(
            f"Request {g.get('request_id', 'unknown')}: Notification token updated - {user.id}"
        )

        return jsonify({"status": "ok"}), 200
    except Exception as e:
        logger.error(
            f"Request {g.get('request_id', 'unknown')}: Error updating notification token - {e}",
            exc_info=True,
        )
        db.session.rollback()
        return (
            jsonify(
                {
                    "error": "Internal server error",
                    "request_id": g.get("request_id", "unknown"),
                }
            ),
            500,
        )
