import os
import datetime
import logging
from functools import wraps

import jwt
from flask import request, jsonify, g

from models.users import User
from utils.config import get_jwt_secret

logger = logging.getLogger(__name__)

JWT_ALGORITHM = "HS256"
JWT_EXP_HOURS = 24  # Reduced from 7 days to 24 hours for better security
REFRESH_TOKEN_EXP_DAYS = 30  # Refresh tokens last 30 days


def generate_token(user: User, is_refresh: bool = False) -> str:
    """
    Generate JWT token for user.
    
    Args:
        user: User object
        is_refresh: If True, generate refresh token with longer expiration
    
    Returns:
        JWT token string
    """
    exp_delta = datetime.timedelta(days=REFRESH_TOKEN_EXP_DAYS) if is_refresh else datetime.timedelta(hours=JWT_EXP_HOURS)
    
    payload = {
        "sub": user.id,
        "email": user.email,
        "exp": datetime.datetime.utcnow() + exp_delta,
        "iat": datetime.datetime.utcnow(),
        "type": "refresh" if is_refresh else "access"
    }
    jwt_secret = get_jwt_secret()
    token = jwt.encode(payload, jwt_secret, algorithm=JWT_ALGORITHM)
    # In PyJWT>=2, this is already a string
    if isinstance(token, bytes):
        token = token.decode("utf-8")
    return token


def generate_token_pair(user: User) -> tuple[str, str]:
    """
    Generate both access and refresh tokens.
    
    Returns:
        Tuple of (access_token, refresh_token)
    """
    access_token = generate_token(user, is_refresh=False)
    refresh_token = generate_token(user, is_refresh=True)
    return access_token, refresh_token


def decode_token(token: str):
    jwt_secret = get_jwt_secret()
    return jwt.decode(token, jwt_secret, algorithms=[JWT_ALGORITHM])


def require_auth(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        request_id = g.get('request_id', 'unknown')
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            logger.warning(f"Request {request_id}: Missing or invalid authorization header")
            return jsonify({"error": "Authorization header missing or invalid"}), 401

        token = auth_header.split(" ", 1)[1].strip()
        try:
            payload = decode_token(token)
        except jwt.ExpiredSignatureError:
            logger.warning(f"Request {request_id}: Expired token")
            return jsonify({"error": "Token expired"}), 401
        except jwt.InvalidTokenError as e:
            logger.warning(f"Request {request_id}: Invalid token - {e}")
            return jsonify({"error": "Invalid token"}), 401

        user_id = payload.get("sub")
        if not user_id:
            logger.warning(f"Request {request_id}: Invalid token payload")
            return jsonify({"error": "Invalid token payload"}), 401

        user = User.query.get(user_id)
        if not user:
            logger.warning(f"Request {request_id}: User {user_id} not found")
            return jsonify({"error": "User not found"}), 401

        # Attach to Flask global context
        g.current_user = user
        logger.debug(f"Request {request_id}: Authenticated as user {user_id}")
        return fn(*args, **kwargs)

    return wrapper
