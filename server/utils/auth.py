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
JWT_EXP_DAYS = 7


def generate_token(user: User) -> str:
    payload = {
        "sub": user.id,
        "email": user.email,
        "exp": datetime.datetime.utcnow() + datetime.timedelta(days=JWT_EXP_DAYS),
        "iat": datetime.datetime.utcnow(),
    }
    jwt_secret = get_jwt_secret()
    token = jwt.encode(payload, jwt_secret, algorithm=JWT_ALGORITHM)
    # In PyJWT>=2, this is already a string
    if isinstance(token, bytes):
        token = token.decode("utf-8")
    return token


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
