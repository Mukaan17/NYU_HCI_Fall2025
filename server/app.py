# server/app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import google.generativeai as genai
import os
import pytz
from datetime import datetime

from models.db import db, bcrypt

# SERVICES
from utils.cache import init_requests_cache
from utils.config import get_allowed_origins, validate_config, get_jwt_secret
from utils.limiter import init_limiter
import utils.limiter as limiter_module
from utils.validation import (
    validate_coordinates, validate_limit, validate_days
)
from middleware.security import add_security_headers, enforce_https
from services.directions_service import get_walking_directions
from services.recommendation.driver import build_chat_response
from services.recommendation.quick_recommendations import (
    get_quick_recommendations,
    get_top_recommendations_for_user,
)
from services.scrapers.engage_events_service import fetch_engage_events
from services.recommendation.context import ConversationContext
from services.weather_service import get_weather_by_coords, get_forecast_by_coords
from utils.auth import decode_token
from utils.context_manager import ConversationContextManager
from models.users import User
import logging
import uuid

logger = logging.getLogger(__name__)


# NYU Tandon-ish coordinates
TANDON_LAT = 40.6942
TANDON_LNG = -73.9866


# ─────────────────────────────────────────────────────────────
# APP SETUP
# ─────────────────────────────────────────────────────────────

app = Flask(__name__)

# Set maximum request size
app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024  # 1 MB

load_dotenv()

# Validate configuration
try:
    validate_config()
except ValueError as e:
    logger.error(f"Configuration validation failed: {e}")
    # In production, this should fail. In development, continue with warnings.

# CORS configuration - environment-aware
env = os.getenv("FLASK_ENV", os.getenv("ENVIRONMENT", "development")).lower()
is_production = env in ("production", "prod")

try:
    allowed_origins = get_allowed_origins()
    CORS(app, resources={r"/api/*": {"origins": allowed_origins}})
    logger.info(f"CORS configured with origins: {allowed_origins}")
except ValueError as e:
    if is_production:
        # Fail fast in production - never use wildcard
        logger.error(f"CORS configuration error in production: {e}")
        raise ValueError(f"CORS configuration required in production: {e}")
    else:
        # Development: allow wildcard with warning
        logger.warning(f"CORS configuration error: {e}. Using wildcard for development.")
        CORS(app, resources={r"/api/*": {"origins": "*"}})

init_requests_cache()

# Secret key for Flask (uses JWT_SECRET, but JWT tokens use get_jwt_secret() which validates)
# In production, JWT_SECRET must be set (validated by get_jwt_secret())
if is_production:
    # In production, get_jwt_secret() will raise error if JWT_SECRET not set
    app.config["SECRET_KEY"] = get_jwt_secret()
else:
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

# Initialize rate limiter early (routes will import it)
init_limiter(app)
limiter = limiter_module.limiter

with app.app_context():
    db.create_all()

# Register security middleware
@app.after_request
def security_headers(response):
    """Add security headers to all responses."""
    return add_security_headers(response)

@app.before_request
def check_https():
    """Enforce HTTPS in production."""
    result = enforce_https()
    if result:
        return result

# Import routes (limiter is already initialized)
from routes.auth_routes import auth_bp
from routes.user_routes import user_bp
from routes.calendar_routes import calendar_bp
from routes.calendar_oauth_routes import calendar_oauth_bp
from routes.migration_routes import migration_bp
from routes.purge_routes import purge_bp
from routes.dashboard_routes import dashboard_bp
from routes.weather_routes import weather_bp

# Register blueprints
app.register_blueprint(auth_bp, url_prefix="/api/auth")
app.register_blueprint(user_bp, url_prefix="/api/user")
app.register_blueprint(calendar_bp, url_prefix="/api/calendar")
app.register_blueprint(calendar_oauth_bp, url_prefix="/api/calendar")
app.register_blueprint(migration_bp, url_prefix="/api")
app.register_blueprint(purge_bp, url_prefix="/api")
app.register_blueprint(dashboard_bp, url_prefix="/api")
app.register_blueprint(weather_bp, url_prefix="/api")

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))


# ─────────────────────────────────────────────────────────────
# CHAT ROUTE
# ─────────────────────────────────────────────────────────────

@app.route("/api/chat", methods=["POST"])
@limiter_module.limiter.limit("10 per minute")
def chat():
    try:
        data = request.get_json(force=True) or {}
        user_message = (data.get("message") or "").strip()

        if not user_message:
            return jsonify({"error": "Missing 'message'"}), 400

        # Try to get user from JWT
        token = request.headers.get("Authorization", "").replace("Bearer ", "").strip()
        user = None
        user_id = None
        session_id = None

        if token:
            try:
                payload = decode_token(token)
                user = User.query.get(payload.get("sub"))
                if user:
                    user_id = str(user.id)
            except Exception:
                user = None
        
        # If no authenticated user, use session-based context
        if not user_id:
            # Try to get session ID from request or generate one
            session_id = request.headers.get("X-Session-ID") or str(uuid.uuid4())
        
        # Get or create user-scoped conversation context
        context_manager = ConversationContextManager(user_id=user_id, session_id=session_id)
        memory = context_manager.get_context()

        logger.debug(f"Chat request - user: {user_id or 'anonymous'}, session: {session_id}, message length: {len(user_message)}")

        prefs = user.get_preferences() if user else {}

        result = build_chat_response(
            user_message,
            memory,
            user_profile=prefs,
        )
        
        # Save context after conversation
        context_manager.save_context(memory)

        # Include session ID in response for anonymous users
        response_data = result.copy()
        if not user_id and session_id:
            response_data["session_id"] = session_id

        return jsonify(response_data)

    except Exception as e:
        logger.error(f"Chat endpoint error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# ─────────────────────────────────────────────────────────────
# QUICK RECOMMENDATIONS
# ─────────────────────────────────────────────────────────────

@app.route("/api/quick_recs", methods=["GET"])
@limiter_module.limiter.limit("30 per minute")
def quick_recs():
    try:
        category = (request.args.get("category") or "explore").lower()
        
        # Validate limit parameter
        limit_raw = request.args.get("limit", 10)
        is_valid, limit, error_msg = validate_limit(limit_raw)
        if not is_valid:
            logger.warning(f"Invalid limit parameter: {limit_raw}, using clamped value: {limit}")
        
        vibe = request.args.get("vibe")  # Optional vibe parameter
        result = get_quick_recommendations(category, limit=limit, vibe=vibe)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Quick recommendations endpoint error: {e}", exc_info=True)
        return jsonify({"error": "Unable to fetch quick recommendations"}), 500


# ─────────────────────────────────────────────────────────────
# TOP RECOMMENDATIONS (preferences + context for dashboard)
# ─────────────────────────────────────────────────────────────

@app.route("/api/top_recommendations", methods=["GET"])
@limiter_module.limiter.limit("20 per minute")
def top_recommendations():
    """
    Get personalized top recommendations based on user preferences and context.
    Optional JWT token for personalized preferences.
    """
    try:
        # Optional JWT for personalized preferences
        token = request.headers.get("Authorization", "").replace("Bearer ", "").strip()
        user = None

        if token:
            try:
                payload = decode_token(token)
                user = User.query.get(payload.get("sub"))
            except Exception as e:
                logger.debug(f"Failed to decode token for top recommendations: {e}")
                user = None

        prefs = user.get_preferences() if user else {}

        # Simple context from server (time of day) + optional weather hint from client
        tz = pytz.timezone("America/New_York")
        now = datetime.now(tz)

        context = {
            "hour": now.hour,
            "weather": (request.args.get("weather") or "").strip(),
        }

        # Validate limit parameter
        limit_raw = request.args.get("limit", 3)
        is_valid, limit, error_msg = validate_limit(limit_raw, max_value=10, min_value=1)
        if not is_valid:
            logger.warning(f"Invalid limit parameter: {limit_raw}, using clamped value: {limit}")

        result = get_top_recommendations_for_user(
            prefs=prefs,
            context=context,
            limit=limit,
        )

        return jsonify(result)
    except Exception as e:
        logger.error(f"Top recommendations endpoint error: {e}", exc_info=True)
        return jsonify({"error": "Unable to fetch top recommendations"}), 500


# ─────────────────────────────────────────────────────────────
# EVENTS
# ─────────────────────────────────────────────────────────────

@app.route("/api/nyu_engage_events", methods=["GET"])
@limiter_module.limiter.limit("20 per minute")
def nyu_engage_events():
    try:
        days_raw = request.args.get("days", 7)
        is_valid, days, error_msg = validate_days(days_raw)
        if not is_valid:
            logger.warning(f"Invalid days parameter: {days_raw}, using clamped value: {days}")
        
        data = fetch_engage_events(days_ahead=days)
        return jsonify({"engage_events": data})
    except Exception as e:
        logger.error(f"Engage events endpoint error: {e}", exc_info=True)
        return jsonify({"error": "Unable to fetch NYU Engage events"}), 500


# ─────────────────────────────────────────────────────────────
# DIRECTIONS
# ─────────────────────────────────────────────────────────────

@app.route("/api/directions", methods=["GET"])
@limiter_module.limiter.limit("30 per minute")
def directions():
    try:
        # Validate destination coordinates
        lat_raw = request.args.get("lat")
        lng_raw = request.args.get("lng")
        
        if not lat_raw or not lng_raw:
            return jsonify({"error": "Latitude and longitude are required"}), 400
        
        is_valid, error_msg = validate_coordinates(float(lat_raw), float(lng_raw))
        if not is_valid:
            return jsonify({"error": error_msg}), 400
        
        lat = float(lat_raw)
        lng = float(lng_raw)
        
        # Validate origin coordinates (optional, default to 2 MetroTech)
        origin_lat_raw = request.args.get("origin_lat", "40.693393")
        origin_lng_raw = request.args.get("origin_lng", "-73.98555")
        
        is_valid, error_msg = validate_coordinates(float(origin_lat_raw), float(origin_lng_raw))
        if not is_valid:
            return jsonify({"error": f"Invalid origin coordinates: {error_msg}"}), 400
        
        origin_lat = float(origin_lat_raw)
        origin_lng = float(origin_lng_raw)

        result = get_walking_directions(origin_lat, origin_lng, lat, lng)

        if not result:
            return jsonify({"error": "Directions failed"}), 500

        # Ensure mode is included in response for frontend
        if "mode" not in result:
            result["mode"] = "walking"  # Default fallback

        return jsonify(result)
    except ValueError as e:
        logger.error(f"Directions endpoint validation error: {e}")
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Directions endpoint error: {e}", exc_info=True)
        return jsonify({"error": "Directions failed"}), 500


# ─────────────────────────────────────────────────────────────
# WEATHER ENDPOINTS
# ─────────────────────────────────────────────────────────────

@app.route("/api/weather", methods=["GET"])
@limiter_module.limiter.limit("30 per minute")
def weather():
    """Get current weather by coordinates."""
    try:
        lat_raw = request.args.get("lat")
        lon_raw = request.args.get("lon")
        
        if not lat_raw or not lon_raw:
            return jsonify({"error": "Latitude and longitude are required"}), 400
        
        is_valid, error_msg = validate_coordinates(float(lat_raw), float(lon_raw))
        if not is_valid:
            return jsonify({"error": error_msg}), 400
        
        lat = float(lat_raw)
        lon = float(lon_raw)
        
        result = get_weather_by_coords(lat, lon)
        return jsonify(result)
    except ValueError as e:
        logger.error(f"Weather endpoint error: {e}")
        return jsonify({"error": str(e)}), 500
    except Exception as e:
        logger.error(f"Weather endpoint error: {e}", exc_info=True)
        return jsonify({"error": "Unable to fetch weather"}), 500


@app.route("/api/weather/forecast", methods=["GET"])
@limiter_module.limiter.limit("30 per minute")
def weather_forecast():
    """Get weather forecast by coordinates."""
    try:
        lat_raw = request.args.get("lat")
        lon_raw = request.args.get("lon")
        
        if not lat_raw or not lon_raw:
            return jsonify({"error": "Latitude and longitude are required"}), 400
        
        is_valid, error_msg = validate_coordinates(float(lat_raw), float(lon_raw))
        if not is_valid:
            return jsonify({"error": error_msg}), 400
        
        lat = float(lat_raw)
        lon = float(lon_raw)
        
        result = get_forecast_by_coords(lat, lon)
        return jsonify({"forecast": result})
    except ValueError as e:
        logger.error(f"Weather forecast endpoint error: {e}")
        return jsonify({"error": str(e)}), 500
    except Exception as e:
        logger.error(f"Weather forecast endpoint error: {e}", exc_info=True)
        return jsonify({"error": "Unable to fetch weather forecast"}), 500


# ─────────────────────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
@limiter_module.limiter.exempt  # Exempt health checks from rate limiting
def health():
    """
    Health check endpoint for DigitalOcean App Platform.
    Checks database and Valkey/Redis connectivity.
    Must be exempt from rate limiting to allow Kubernetes health probes.
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
    
    # Check Valkey/Redis connectivity (optional, works with both Valkey and Redis)
    redis_url = os.getenv("REDIS_URL")
    if redis_url:
        try:
            import redis
            redis_client = redis.from_url(redis_url)
            redis_client.ping()
            status["redis"] = "connected"
        except Exception as e:
            status["redis"] = "disconnected"
            logger.warning(f"Health check: Valkey/Redis connection failed - {e}")
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
