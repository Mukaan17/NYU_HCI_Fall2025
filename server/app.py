# server/app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import google.generativeai as genai
import os

from models.db import db, bcrypt

# ROUTES
from routes.auth_routes import auth_bp
from routes.user_routes import user_bp

# SERVICES
from utils.cache import init_requests_cache
from services.directions_service import get_walking_directions
from services.recommendation.driver import build_chat_response
from services.recommendation.quick_recommendations import get_quick_recommendations
from services.scrapers.engage_events_service import fetch_engage_events
from services.recommendation.context import ConversationContext
from utils.auth import decode_token
from models.users import User



# NYU Tandon-ish coordinates
TANDON_LAT = 40.6942
TANDON_LNG = -73.9866


# ─────────────────────────────────────────────────────────────
# APP SETUP
# ─────────────────────────────────────────────────────────────

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

load_dotenv()
init_requests_cache()

# Secret key for JWT
app.config["SECRET_KEY"] = os.getenv("JWT_SECRET", "dev-secret-change-me")

# Database config
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///violetvibes.db"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

# Init extensions
db.init_app(app)
bcrypt.init_app(app)

with app.app_context():
    db.create_all()

# Register blueprints
app.register_blueprint(auth_bp, url_prefix="/api/auth")
app.register_blueprint(user_bp, url_prefix="/api/user")

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))


# ─────────────────────────────────────────────────────────────
# CHAT ROUTE
# ─────────────────────────────────────────────────────────────

memory = ConversationContext()

@app.route("/api/chat", methods=["POST"])
def chat():
    try:
        data = request.get_json(force=True) or {}
        user_message = (data.get("message") or "").strip()

        if not user_message:
            return jsonify({"error": "Missing 'message'"}), 400

        # Try to get user from JWT
        token = request.headers.get("Authorization", "").replace("Bearer ", "").strip()
        user = None
        profile_text = None

        if token:
            try:
                payload = decode_token(token)
                user = User.query.get(payload.get("sub"))
                if user:
                    # Build a text summary of user preferences
                    profile_text = user.get_profile_text()
            except Exception:
                user = None
                profile_text = None

        print("MEMORY STATE:", memory.history)

        # SAFE: profile_text is either a string or None
        result = build_chat_response(
            user_message,
            memory,
            user_profile_text=profile_text
        )

        return jsonify(result)

    except Exception as e:
        print("CHAT ERROR:", e)
        return jsonify({"error": "Internal server error"}), 500

# ─────────────────────────────────────────────────────────────
# QUICK RECOMMENDATIONS
# ─────────────────────────────────────────────────────────────

@app.route("/api/quick_recs", methods=["GET"])
def quick_recs():
    try:
        category = (request.args.get("category") or "explore").lower()
        result = get_quick_recommendations(category, limit=10)
        return jsonify(result)
    except Exception as e:
        print("QUICK_RECS ERROR:", e)
        return jsonify({"error": "Unable to fetch quick recommendations"}), 500


# ─────────────────────────────────────────────────────────────
# EVENTS
# ─────────────────────────────────────────────────────────────
@app.route("/api/nyu_engage_events", methods=["GET"])
def nyu_engage_events():
    try:
        days = int(request.args.get("days", 7))
        data = fetch_engage_events(days_ahead=days)
        return jsonify({"engage_events": data})
    except Exception as e:
        print("ENGAGE EVENTS ERROR:", e)
        return jsonify({"error": "Unable to fetch NYU Engage events"}), 500


# ─────────────────────────────────────────────────────────────
# DIRECTIONS
# ─────────────────────────────────────────────────────────────

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
# HEALTH CHECK
# ─────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


# ─────────────────────────────────────────────────────────────
# MAIN ENTRY
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
