# routes/notification_routes.py
from flask import Blueprint, request, jsonify, g
from utils.auth import require_auth
from models.users import User
from models.db import db

# MUST match what app.py registers
notifications_bp = Blueprint("notifications", __name__)


@notifications_bp.route("/register_token", methods=["POST"])
@require_auth
def register_token():
    """
    Save a user's APNs push notification token.
    Body:
        { "device_token": "<APNS_TOKEN>" }
    """
    data = request.get_json(force=True) or {}
    token = data.get("device_token")

    if not token:
        return jsonify({"error": "Missing device_token"}), 400

    user = g.current_user
    user.notification_token = token

    db.session.commit()

    return jsonify({
        "status": "success",
        "message": "Device token saved",
        "device_token": token
    }), 200
