from flask import Blueprint, request, jsonify, g
from sqlalchemy.exc import IntegrityError
import logging

from models.db import db, bcrypt
from models.users import User
from utils.auth import generate_token

logger = logging.getLogger(__name__)
auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/signup", methods=["POST"])
def signup():
    try:
        data = request.get_json(force=True) or {}
        email = (data.get("email") or "").strip().lower()
        password = data.get("password") or ""

        if not email or not password:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Signup missing email or password")
            return jsonify({"error": "Email and password are required"}), 400

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

        token = generate_token(user)

        return jsonify({
            "token": token,
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
def login():
    try:
        data = request.get_json(force=True) or {}
        email = (data.get("email") or "").strip().lower()
        password = data.get("password") or ""

        if not email or not password:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Login missing email or password")
            return jsonify({"error": "Email and password are required"}), 400

        user = User.query.filter_by(email=email).first()
        if not user:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Login attempt with non-existent email - {email}")
            return jsonify({"error": "Invalid email or password"}), 401

        if not bcrypt.check_password_hash(user.password_hash, password):
            logger.warning(f"Request {g.get('request_id', 'unknown')}: Login attempt with wrong password for - {email}")
            return jsonify({"error": "Invalid email or password"}), 401

        token = generate_token(user)
        logger.info(f"Request {g.get('request_id', 'unknown')}: User logged in - {email}")

        return jsonify({
            "token": token,
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
