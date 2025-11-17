# server/app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import google.generativeai as genai
import os
from services.directions_service import get_walking_directions
from utils.cache import init_requests_cache
from services.recommendation_service import build_chat_response
from services.nyc_events_service import events_near_bbox  # your existing file name
from utils.chat_memory import ChatMemory

# NYU Tandon-ish coordinates (for events bbox)
TANDON_LAT = 40.6942
TANDON_LNG = -73.9866

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Load env + configure external libs
load_dotenv()
init_requests_cache()

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))


# ─────────────────────────────────────────────────────────────
# CHAT
# ─────────────────────────────────────────────────────────────
memory = ChatMemory()

@app.route("/api/chat", methods=["POST"])
def chat():
    try:
        data = request.get_json(force=True) or {}
        user_message = (data.get("message") or "").strip()

        if not user_message:
            return jsonify({"error": "Missing 'message'"}), 400

        # FIX: pass memory into build_chat_response
        print("MEMORY STATE:", memory.history)
        result = build_chat_response(user_message, memory)
        return jsonify(result)

    except Exception as e:
        print("CHAT ERROR:", e)
        return jsonify({"error": "Internal server error"}), 500

# ─────────────────────────────────────────────────────────────
# EVENTS
# ─────────────────────────────────────────────────────────────

@app.route("/api/events", methods=["GET"])
def events():
    """
    Example: grab permitted events from NYC Open Data
    within a bounding box around Downtown Brooklyn.
    """
    try:
        lat_min = TANDON_LAT - 0.03
        lat_max = TANDON_LAT + 0.03
        lng_min = TANDON_LNG - 0.03
        lng_max = TANDON_LNG + 0.03

        data = events_near_bbox(lat_min, lat_max, lng_min, lng_max, limit=10)
        return jsonify({"nyc_permitted": data})
    except Exception as e:
        print("EVENTS ERROR:", e)
        return jsonify({"error": "Unable to fetch events"}), 500
    
#--------------------------------
# Directions
#--------------------------------
@app.route("/api/directions", methods=["GET"])
def directions():
    lat = float(request.args.get("lat"))
    lng = float(request.args.get("lng"))

    origin_lat = 40.693393   # 2 MetroTech
    origin_lng = -73.98555

    result = get_walking_directions(origin_lat, origin_lng, lat, lng)

    if not result:
        return jsonify({"error": "Directions failed"}), 500

    return jsonify(result)


# ─────────────────────────────────────────────────────────────
# HEALTH
# ─────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


# ─────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # When running directly: python app.py
    app.run(host="0.0.0.0", port=5000, debug=True)
