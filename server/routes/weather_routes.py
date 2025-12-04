# server/routes/weather_routes.py
from flask import Blueprint, jsonify
from services.weather_service import current_weather

weather_bp = Blueprint("weather", __name__)

@weather_bp.route("/weather", methods=["GET"])
def weather():
    """
    Public weather endpoint — no auth required.
    """
    try:
        data = current_weather()
        return jsonify(data), 200
    except Exception as e:
        print("WEATHER ERROR:", e)
        return jsonify({"error": "Weather unavailable"}), 500
