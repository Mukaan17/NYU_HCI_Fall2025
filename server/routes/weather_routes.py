# server/routes/weather_routes.py
from flask import Blueprint, jsonify
from services.weather_service import current_weather
import logging
import utils.limiter as limiter_module

weather_bp = Blueprint("weather", __name__)
logger = logging.getLogger(__name__)


@weather_bp.route("/weather", methods=["GET"])
@limiter_module.limiter.limit("30 per minute")
def weather():
    """
    Public weather endpoint — no auth required.
    Returns current weather for Brooklyn, US.
    """
    try:
        data = current_weather()
        return jsonify(data), 200
    except Exception as e:
        logger.error(f"Weather endpoint error: {e}", exc_info=True)
        return jsonify({"error": "Weather unavailable"}), 500

