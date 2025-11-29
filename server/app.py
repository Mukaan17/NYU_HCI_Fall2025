# -*- coding: utf-8 -*-
# @Author: Mukhil Sundararaj
# @Date:   2025-11-26 12:00:44
# @Last Modified by:   Mukhil Sundararaj
# @Last Modified time: 2025-11-29 15:21:36
# server/app.py
from flask import Flask, request, jsonify, g
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from dotenv import load_dotenv
import google.generativeai as genai
import os
import logging
import uuid
from functools import wraps

from models.db import db, bcrypt

# ROUTES
from routes.auth_routes import auth_bp
from routes.user_routes import user_bp

# SERVICES
from utils.cache import init_requests_cache
from utils.config import validate_config, get_allowed_origins, get_jwt_secret
from utils.logging_config import setup_logging
from utils.context_manager import ConversationContextManager
from services.directions_service import get_walking_directions
from services.recommendation.driver import build_chat_response
from services.recommendation.quick_recommendations import get_quick_recommendations
from services.scrapers.engage_events_service import fetch_engage_events
from utils.auth import decode_token
from models.users import User

# Initialize logging first
setup_logging()
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
    raise

# CORS configuration
allowed_origins = get_allowed_origins()
CORS(app, resources={r"/api/*": {"origins": allowed_origins}})
logger.info(f"CORS configured for origins: {allowed_origins}")

# Secret key for JWT
app.config["SECRET_KEY"] = get_jwt_secret()

# Database config - support both SQLite (dev) and PostgreSQL (prod)
database_url = os.getenv("DATABASE_URL")
if database_url:
    # PostgreSQL connection string
    app.config["SQLALCHEMY_DATABASE_URI"] = database_url
    # Connection pooling for PostgreSQL
    app.config["SQLALCHEMY_ENGINE_OPTIONS"] = {
        "pool_size": 10,
        "max_overflow": 20,
        "pool_pre_ping": True,
        "pool_recycle": 3600,
    }
    logger.info("Using PostgreSQL database")
else:
    # SQLite for local development
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///violetvibes.db"
    logger.warning("Using SQLite database (development only)")

app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

# Init extensions
db.init_app(app)
bcrypt.init_app(app)

# Initialize cache
init_requests_cache()

# Rate limiting setup
redis_url = os.getenv("REDIS_URL")
if redis_url:
    try:
        import redis
        redis_client = redis.from_url(redis_url)
        redis_client.ping()
        limiter = Limiter(
            app=app,
            key_func=get_remote_address,
            storage_uri=redis_url,
            default_limits=["200 per day", "50 per hour"],
        )
        logger.info("Rate limiting configured with Redis backend")
    except Exception as e:
        logger.warning(f"Failed to initialize Redis for rate limiting: {e}. Using memory backend.")
        limiter = Limiter(
            app=app,
            key_func=get_remote_address,
            default_limits=["200 per day", "50 per hour"],
        )
else:
    limiter = Limiter(
        app=app,
        key_func=get_remote_address,
        default_limits=["200 per day", "50 per hour"],
    )
    logger.info("Rate limiting configured with memory backend")

# Apply rate limiting to auth blueprint before registration
limiter.limit("5 per minute")(auth_bp)

# Database initialization (only in development or when INIT_DB is set)
init_db = os.getenv("INIT_DB", "false").lower() == "true"
env = os.getenv("FLASK_ENV", os.getenv("ENVIRONMENT", "development")).lower()
if init_db or env not in ("production", "prod"):
    with app.app_context():
        db.create_all()
        logger.info("Database tables created/verified")

# Register blueprints
app.register_blueprint(auth_bp, url_prefix="/api/auth")
app.register_blueprint(user_bp, url_prefix="/api/user")

# Configure Gemini
gemini_key = os.getenv("GEMINI_API_KEY")
if gemini_key:
    genai.configure(api_key=gemini_key)
else:
    logger.warning("GEMINI_API_KEY not set")


# ─────────────────────────────────────────────────────────────
# REQUEST ID MIDDLEWARE
# ─────────────────────────────────────────────────────────────

@app.before_request
def before_request():
    """Add request ID for tracking."""
    g.request_id = str(uuid.uuid4())[:8]
    logger.info(f"Request {g.request_id}: {request.method} {request.path}")


# ─────────────────────────────────────────────────────────────
# ERROR HANDLERS
# ─────────────────────────────────────────────────────────────

@app.errorhandler(400)
def bad_request(error):
    """Handle 400 Bad Request errors."""
    logger.warning(f"Request {g.get('request_id', 'unknown')}: Bad request - {error}")
    return jsonify({"error": "Bad request", "message": str(error)}), 400


@app.errorhandler(401)
def unauthorized(error):
    """Handle 401 Unauthorized errors."""
    logger.warning(f"Request {g.get('request_id', 'unknown')}: Unauthorized - {error}")
    return jsonify({"error": "Unauthorized", "message": "Authentication required"}), 401


@app.errorhandler(404)
def not_found(error):
    """Handle 404 Not Found errors."""
    logger.info(f"Request {g.get('request_id', 'unknown')}: Not found - {request.path}")
    return jsonify({"error": "Not found", "message": "The requested resource was not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 Internal Server Error."""
    request_id = g.get('request_id', 'unknown')
    logger.error(f"Request {request_id}: Internal server error - {error}", exc_info=True)
    
    # Don't expose internal errors in production
    env = os.getenv("FLASK_ENV", os.getenv("ENVIRONMENT", "development")).lower()
    if env in ("production", "prod"):
        return jsonify({"error": "Internal server error", "request_id": request_id}), 500
    else:
        return jsonify({"error": "Internal server error", "message": str(error), "request_id": request_id}), 500


@app.errorhandler(429)
def ratelimit_handler(e):
    """Handle 429 Rate Limit errors."""
    logger.warning(f"Request {g.get('request_id', 'unknown')}: Rate limit exceeded")
    return jsonify({"error": "Rate limit exceeded", "message": str(e.description)}), 429


# ─────────────────────────────────────────────────────────────
# CHAT ROUTE
# ─────────────────────────────────────────────────────────────

@app.route("/api/chat", methods=["POST"])
@limiter.limit("10 per minute")
def chat():
    try:
        data = request.get_json(force=True) or {}
        user_message = (data.get("message") or "").strip()

        if not user_message:
            logger.warning(f"Request {g.request_id}: Missing message in chat request")
            return jsonify({"error": "Missing 'message'"}), 400

        # Try to get user from JWT
        token = request.headers.get("Authorization", "").replace("Bearer ", "").strip()
        user = None
        profile_text = None
        user_id = None

        if token:
            try:
                payload = decode_token(token)
                user_id = str(payload.get("sub"))
                user = User.query.get(payload.get("sub"))
                if user:
                    profile_text = user.get_profile_text()
                    logger.info(f"Request {g.request_id}: Chat request from user {user_id}")
            except Exception as e:
                logger.warning(f"Request {g.request_id}: Invalid token - {e}")
                user = None
                profile_text = None
        else:
            logger.info(f"Request {g.request_id}: Chat request from anonymous user")

        # Get or create conversation context
        session_id = request.headers.get("X-Session-ID") or g.request_id
        context_manager = ConversationContextManager(user_id=user_id, session_id=session_id)
        memory = context_manager.get_context()

        logger.debug(f"Request {g.request_id}: Memory state - {len(memory.history)} messages")

        # Build chat response
        result = build_chat_response(
            user_message,
            memory,
            user_profile_text=profile_text
        )

        # Save context back
        context_manager.save_context(memory)

        return jsonify(result)

    except Exception as e:
        logger.error(f"Request {g.request_id}: Chat error - {e}", exc_info=True)
        return jsonify({"error": "Internal server error", "request_id": g.request_id}), 500


# ─────────────────────────────────────────────────────────────
# QUICK RECOMMENDATIONS
# ─────────────────────────────────────────────────────────────

@app.route("/api/quick_recs", methods=["GET"])
@limiter.limit("30 per minute", key_func=get_remote_address)
def quick_recs():
    try:
        category = (request.args.get("category") or "explore").lower()
        logger.info(f"Request {g.request_id}: Quick recommendations for category: {category}")
        result = get_quick_recommendations(category, limit=10)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Request {g.request_id}: Quick recs error - {e}", exc_info=True)
        return jsonify({"error": "Unable to fetch quick recommendations", "request_id": g.request_id}), 500


# ─────────────────────────────────────────────────────────────
# EVENTS
# ─────────────────────────────────────────────────────────────

@app.route("/api/nyu_engage_events", methods=["GET"])
def nyu_engage_events():
    try:
        days = int(request.args.get("days", 7))
        logger.info(f"Request {g.request_id}: Fetching NYU Engage events for {days} days")
        data = fetch_engage_events(days_ahead=days)
        return jsonify({"engage_events": data})
    except Exception as e:
        logger.error(f"Request {g.request_id}: Engage events error - {e}", exc_info=True)
        return jsonify({"error": "Unable to fetch NYU Engage events", "request_id": g.request_id}), 500


# ─────────────────────────────────────────────────────────────
# DIRECTIONS
# ─────────────────────────────────────────────────────────────

@app.route("/api/directions", methods=["GET"])
def directions():
    try:
        lat = float(request.args.get("lat"))
        lng = float(request.args.get("lng"))
        logger.info(f"Request {g.request_id}: Directions request for lat={lat}, lng={lng}")

        origin_lat = 40.693393   # 2 MetroTech
        origin_lng = -73.98555

        result = get_walking_directions(origin_lat, origin_lng, lat, lng)

        if not result:
            logger.warning(f"Request {g.request_id}: Directions failed")
            return jsonify({"error": "Directions failed", "request_id": g.request_id}), 500

        return jsonify(result)
    except ValueError as e:
        logger.warning(f"Request {g.request_id}: Invalid coordinates - {e}")
        return jsonify({"error": "Invalid coordinates", "request_id": g.request_id}), 400
    except Exception as e:
        logger.error(f"Request {g.request_id}: Directions error - {e}", exc_info=True)
        return jsonify({"error": "Directions failed", "request_id": g.request_id}), 500


# ─────────────────────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    """Enhanced health check endpoint."""
    status = {
        "status": "ok",
        "database": "unknown",
        "redis": "unknown",
    }
    http_status = 200

    # Check database connectivity
    try:
        db.session.execute(db.text("SELECT 1"))
        status["database"] = "connected"
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        status["database"] = "disconnected"
        http_status = 503

    # Check Redis connectivity (if configured)
    redis_url = os.getenv("REDIS_URL")
    if redis_url:
        try:
            import redis
            redis_client = redis.from_url(redis_url)
            redis_client.ping()
            status["redis"] = "connected"
        except Exception as e:
            logger.warning(f"Redis health check failed: {e}")
            status["redis"] = "disconnected"
            # Redis is optional, so don't fail health check
    else:
        status["redis"] = "not_configured"

    return jsonify(status), http_status


# ─────────────────────────────────────────────────────────────
# MAIN ENTRY
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5001))
    app.run(host="0.0.0.0", port=port, debug=(env not in ("production", "prod")))
