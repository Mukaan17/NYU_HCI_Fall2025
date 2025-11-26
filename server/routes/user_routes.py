from flask import Blueprint, request, jsonify, g
from models.db import db
from utils.auth import require_auth

user_bp = Blueprint("user", __name__)


@user_bp.route("/me", methods=["GET"])
@require_auth
def me():
    user = g.current_user
    return jsonify({
        "id": user.id,
        "email": user.email,
        "preferences": user.get_preferences(),
        "settings": user.get_settings(),
        "recent_activity": user.get_recent_activity(),
    })


@user_bp.route("/preferences", methods=["GET", "POST"])
@require_auth
def preferences():
    user = g.current_user

    if request.method == "GET":
        return jsonify(user.get_preferences())

    # POST: update prefs
    data = request.get_json(force=True) or {}
    prefs = user.get_preferences()
    prefs.update(data)

    user.set_preferences(prefs)
    db.session.commit()

    return jsonify(prefs)


@user_bp.route("/settings", methods=["GET", "POST"])
@require_auth
def settings():
    user = g.current_user

    if request.method == "GET":
        return jsonify(user.get_settings())

    data = request.get_json(force=True) or {}
    settings = user.get_settings()
    settings.update(data)

    user.set_settings(settings)
    db.session.commit()

    return jsonify(settings)


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
    user = g.current_user
    data = request.get_json(force=True) or {}

    if not data.get("type"):
        return jsonify({"error": "Missing 'type' field"}), 400

    user.add_activity(data)
    db.session.commit()

    return jsonify({"status": "ok"}), 200


@user_bp.route("/notification_token", methods=["POST"])
@require_auth
def notification_token():
    """
    Frontend sends Expo push token or APNs token:
    { "token": "..." }
    """
    user = g.current_user
    data = request.get_json(force=True) or {}
    token = data.get("token")

    if not token:
        return jsonify({"error": "Missing 'token'"}), 400

    user.notification_token = token
    db.session.commit()

    return jsonify({"status": "ok"}), 200
