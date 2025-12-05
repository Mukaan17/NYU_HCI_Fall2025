from flask import Blueprint, request, jsonify, g
from sqlalchemy.exc import IntegrityError
import logging
import jwt

from models.db import db, bcrypt
from models.users import User
from utils.auth import generate_token_pair, decode_token
from utils.limiter import limiter
from utils.validation import validate_email, validate_password

logger = logging.getLogger(__name__)
auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/signup", methods=["POST"])
@limiter.limit("5 per minute")
def signup():
    try:
        data = request.get_json(force=True) or {}
        email = (data.get("email") or "").strip().lower()
        password = data.get("password") or ""

        if not email or not password:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Signup missing email or password")
            return jsonify({"error": "Email and password are required"}), 400
        
        # Validate email format
        if not validate_email(email):
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Signup with invalid email format - {email}")
            return jsonify({"error": "Invalid email format"}), 400
        
        # Validate password strength
        is_valid, error_msg = validate_password(password)
        if not is_valid:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Signup with weak password")
            return jsonify({"error": error_msg}), 400

        # hash password
        pw_hash = bcrypt.generate_password_hash(password).decode("utf-8")

        user = User(email=email, password_hash=pw_hash)

        # optional: set default prefs/settings
        user.set_preferences({
            "vibes": {},  # will fill over time
            "distance_limit_minutes": 20,
            "indoor_outdoor": "either",
        })
        user.set_settings({
            "notifications_enabled": True,
            "calendar_integration_enabled": False,
        })

        try:
            db.session.add(user)
            db.session.commit()
            logger.info(f"Request {g.get('request_id', 'unknown')}: New user signed up - {email}")
        except IntegrityError:
            db.session.rollback()
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Signup attempt with existing email - {email}")
            return jsonify({"error": "Email already registered"}), 409

        access_token, refresh_token = generate_token_pair(user)

        return jsonify({
            "token": access_token,
            "refresh_token": refresh_token,
            "user": {
                "id": user.id,
                "email": user.email,
                "preferences": user.get_preferences(),
                "settings": user.get_settings(),
            },
        }), 201
    except Exception as e:
        logger.error(f"Request {g.get('request_id', 'unknown')}: Signup error - {e}", exc_info=True)
        return jsonify({"error": "Internal server error", "request_id": g.get('request_id', 'unknown')}), 500


@auth_bp.route("/login", methods=["POST"])
@limiter.limit("5 per minute")
def login():
    try:
        data = request.get_json(force=True) or {}
        email = (data.get("email") or "").strip().lower()
        password = data.get("password") or ""

        if not email or not password:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Login missing email or password")
            return jsonify({"error": "Email and password are required"}), 400
        
        # Validate email format
        if not validate_email(email):
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Login with invalid email format - {email}")
            return jsonify({"error": "Invalid email format"}), 400

        user = User.query.filter_by(email=email).first()
        if not user:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Login attempt with non-existent email - {email}")
            return jsonify({"error": "Invalid email or password"}), 401

        if not bcrypt.check_password_hash(user.password_hash, password):
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Login attempt with wrong password for - {email}")
            return jsonify({"error": "Invalid email or password"}), 401

        access_token, refresh_token = generate_token_pair(user)
        logger.info(f"Request {g.get('request_id', 'unknown')}: User logged in - {email}")

        return jsonify({
            "token": access_token,
            "refresh_token": refresh_token,
            "user": {
                "id": user.id,
                "email": user.email,
                "preferences": user.get_preferences(),
                "settings": user.get_settings(),
            },
        }), 200
    except Exception as e:
        logger.error(f"Request {g.get('request_id', 'unknown')}: Login error - {e}", exc_info=True)
        return jsonify({"error": "Internal server error", "request_id": g.get('request_id', 'unknown')}), 500


@auth_bp.route("/refresh", methods=["POST"])
@limiter.limit("10 per minute")
def refresh():
    """Refresh access token using refresh token."""
    try:
        data = request.get_json(force=True) or {}
        refresh_token = data.get("refresh_token") or ""
        
        if not refresh_token:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Refresh missing token")
            return jsonify({"error": "Refresh token is required"}), 400
        
        try:
            payload = decode_token(refresh_token)
            
            # Verify it's a refresh token
            if payload.get("type") != "refresh":
                logger.warning(f"Request {g.get('request_id', 'unknown')}: Refresh with non-refresh token")
                return jsonify({"error": "Invalid token type"}), 401
            
            user_id = payload.get("sub")
            if not user_id:
                logger.warning(f"Request {g.get('request_id', 'unknown')}: Refresh with invalid payload")
                return jsonify({"error": "Invalid token payload"}), 401
            
            user = User.query.get(user_id)
            if not user:
                logger.warning(f"Request {g.get('request_id', 'unknown')}: Refresh for non-existent user - {user_id}")
                return jsonify({"error": "User not found"}), 401
            
            # Generate new token pair
            access_token, new_refresh_token = generate_token_pair(user)
            logger.info(f"Request {g.get('request_id', 'unknown')}: Token refreshed - {user.email}")
            
            return jsonify({
                "token": access_token,
                "refresh_token": new_refresh_token
            }), 200
            
        except jwt.ExpiredSignatureError:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Expired refresh token")
            return jsonify({"error": "Refresh token expired"}), 401
        except jwt.InvalidTokenError as e:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Invalid refresh token - {e}")
            return jsonify({"error": "Invalid refresh token"}), 401
            
    except Exception as e:
        logger.error(f"Request {g.get('request_id', 'unknown')}: Refresh error - {e}", exc_info=True)
        return jsonify({"error": "Internal server error", "request_id": g.get('request_id', 'unknown')}), 500
