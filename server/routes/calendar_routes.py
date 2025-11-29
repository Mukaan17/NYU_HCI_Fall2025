# routes/calendar_routes.py
from flask import Blueprint, jsonify, g
from utils.auth import require_auth
from services.calendar_service import fetch_today_events
import os

calendar_bp = Blueprint("calendar", __name__)


@calendar_bp.route("/today", methods=["GET"])
@require_auth
def today():
    user = g.current_user

    if not user.google_refresh_token:
        return jsonify({"error": "No Google Calendar linked"}), 400

    try:
        events = fetch_today_events(
            refresh_token=user.google_refresh_token,
            client_id=os.getenv("GOOGLE_CLIENT_ID"),
            client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
        )
        return jsonify({"events": events})

    except Exception as e:
        print("GOOGLE CAL ERROR:", e)
        return jsonify({"error": "Failed to fetch Google Calendar events"}), 500
