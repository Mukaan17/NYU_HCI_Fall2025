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
from routes.calendar_routes import calendar_bp

# SERVICES
from utils.cache import init_requests_cache
from utils.config import get_allowed_origins, validate_config
from services.directions_service import get_walking_directions
from services.recommendation.driver import build_chat_response
from services.recommendation.quick_recommendations import get_quick_recommendations
from services.scrapers.engage_events_service import fetch_engage_events
from services.recommendation.context import ConversationContext
from utils.auth import decode_token
from models.users import User
import logging

logger = logging.getLogger(__name__)


# NYU Tandon-ish coordinates
TANDON_LAT = 40.6942
TANDON_LNG = -73.9866


# ─────────────────────────────────────────────────────────────
# APP SETUP
# ─────────────────────────────────────────────────────────────

app = Flask(__name__)

load_dotenv()

# Validate configuration
try:
    validate_config()
except ValueError as e:
    logger.error(f"Configuration validation failed: {e}")
    # In production, this should fail. In development, continue with warnings.

# CORS configuration - environment-aware
try:
    allowed_origins = get_allowed_origins()
    CORS(app, resources={r"/api/*": {"origins": allowed_origins}})
    logger.info(f"CORS configured with origins: {allowed_origins}")
except ValueError as e:
    logger.warning(f"CORS configuration error: {e}. Using wildcard for development.")
    CORS(app, resources={r"/api/*": {"origins": "*"}})

init_requests_cache()

# Secret key for JWT
app.config["SECRET_KEY"] = os.getenv("JWT_SECRET", "dev-secret-change-me")

# Database config - supports both SQLite (dev) and PostgreSQL (production)
database_url = os.getenv("DATABASE_URL")
if database_url:
    # Production: Use PostgreSQL from DATABASE_URL
    app.config["SQLALCHEMY_DATABASE_URI"] = database_url
else:
    # Development: Use SQLite
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
app.register_blueprint(calendar_bp, url_prefix="/api/calendar")

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

        if token:
            try:
                payload = decode_token(token)
                user = User.query.get(payload.get("sub"))
            except Exception:
                user = None

        print("MEMORY STATE:", memory.history)

        prefs = user.get_preferences() if user else {}

        result = build_chat_response(
            user_message,
            memory,
            user_profile=prefs,
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
        limit = int(request.args.get("limit", 10))
        vibe = request.args.get("vibe")  # Optional vibe parameter
        result = get_quick_recommendations(category, limit=limit, vibe=vibe)
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
    
    # Accept optional origin coordinates (for user's current location)
    # Default to 2 MetroTech if not provided
    origin_lat = float(request.args.get("origin_lat", 40.693393))
    origin_lng = float(request.args.get("origin_lng", -73.98555))

    result = get_walking_directions(origin_lat, origin_lng, lat, lng)

    if not result:
        return jsonify({"error": "Directions failed"}), 500

    # Ensure mode is included in response for frontend
    if "mode" not in result:
        result["mode"] = "walking"  # Default fallback

    return jsonify(result)


# ─────────────────────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    """
    Health check endpoint for DigitalOcean App Platform.
    Checks database and Redis connectivity.
    """
    status = {
        "status": "ok",
        "database": "not_configured",
        "redis": "not_configured"
    }
    http_status = 200
    
    # Check database connectivity
    try:
        with app.app_context():
            db.session.execute(db.text("SELECT 1"))
        status["database"] = "connected"
    except Exception as e:
        status["database"] = "disconnected"
        logger.warning(f"Health check: Database connection failed - {e}")
        http_status = 503  # Service Unavailable
    
    # Check Redis connectivity (optional)
    redis_url = os.getenv("REDIS_URL")
    if redis_url:
        try:
            import redis
            redis_client = redis.from_url(redis_url)
            redis_client.ping()
            status["redis"] = "connected"
        except Exception as e:
            status["redis"] = "disconnected"
            logger.warning(f"Health check: Redis connection failed - {e}")
    # If REDIS_URL not set, redis status remains "not_configured" (OK)
    
    return jsonify(status), http_status


# ─────────────────────────────────────────────────────────────
# MAIN ENTRY
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # Get port from environment (DigitalOcean sets PORT)
    port = int(os.getenv("PORT", 5001))
    # Only enable debug in development
    debug = os.getenv("FLASK_ENV", "development").lower() != "production"
    app.run(host="0.0.0.0", port=port, debug=debug)
