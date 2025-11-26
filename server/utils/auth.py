import os
import datetime
from functools import wraps

import jwt
from flask import request, jsonify, g

from models.users import User

JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret-change-me")
JWT_ALGORITHM = "HS256"
JWT_EXP_DAYS = 7


def generate_token(user: User) -> str:
    payload = {
        "sub": user.id,
        "email": user.email,
        "exp": datetime.datetime.utcnow() + datetime.timedelta(days=JWT_EXP_DAYS),
        "iat": datetime.datetime.utcnow(),
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    # In PyJWT>=2, this is already a string
    if isinstance(token, bytes):
        token = token.decode("utf-8")
    return token


def decode_token(token: str):
    return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])


def require_auth(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "Authorization header missing or invalid"}), 401

        token = auth_header.split(" ", 1)[1].strip()
        try:
            payload = decode_token(token)
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Token expired"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"error": "Invalid token"}), 401

        user_id = payload.get("sub")
        if not user_id:
            return jsonify({"error": "Invalid token payload"}), 401

        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 401

        # Attach to Flask global context
        g.current_user = user
        return fn(*args, **kwargs)

    return wrapper
