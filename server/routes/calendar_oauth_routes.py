# routes/calendar_oauth_routes.py

from flask import Blueprint, redirect, request, jsonify
import urllib.parse
import os
import secrets
import requests

from utils.auth import decode_token
from models.users import User
from models.db import db

oauth_bp = Blueprint("oauth", __name__)


# ------------------------------------------------------------
# START GOOGLE LOGIN
# ------------------------------------------------------------
@oauth_bp.route("/google/start")
def google_start():
    """
    Start Google OAuth.

    Frontend (or you in a browser) should call:
    /api/calendar/oauth/google/start?token=JWT_HERE

    We don't bother with cookies anymore. We just pass the JWT
    through Google's `state` parameter.
    """
    client_id = os.getenv("GOOGLE_CLIENT_ID")
    redirect_uri = os.getenv("GOOGLE_REDIRECT_URI")
    scopes = os.getenv("GOOGLE_SCOPES")  # e.g. "https://www.googleapis.com/auth/calendar.readonly"

    if not client_id or not redirect_uri or not scopes:
        return jsonify({"error": "Google OAuth env vars not set"}), 500

    jwt_token = request.args.get("token")
    if not jwt_token:
        return jsonify({"error": "Missing ?token=<JWT> query param"}), 400

    # Optional: basic sanity check that token decodes
    try:
        decode_token(jwt_token)
    except Exception as e:
        return jsonify({"error": f"Invalid JWT token: {e}"}), 400

    # Put the JWT into state (URL-safe already, but we’ll encode anyway)
    state = urllib.parse.quote(jwt_token)

    params = {
        "client_id": client_id,
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": scopes,
        "access_type": "offline",
        "include_granted_scopes": "true",
        "prompt": "consent",
        "state": state,
    }

    url = "https://accounts.google.com/o/oauth2/v2/auth?" + urllib.parse.urlencode(params)
    return redirect(url)


# ------------------------------------------------------------
# GOOGLE CALLBACK (exchange code → refresh token)
# ------------------------------------------------------------
@oauth_bp.route("/google/callback")
def google_callback():
    code = request.args.get("code")
    error = request.args.get("error")
    state = request.args.get("state")

    if error:
        return jsonify({"error": error}), 400

    if not code:
        return jsonify({"error": "Missing authorization code"}), 400

    if not state:
        return jsonify({"error": "Missing state"}), 400

    # Extract JWT from state
    jwt_token = urllib.parse.unquote(state)

    try:
        payload = decode_token(jwt_token)
    except Exception as e:
        return jsonify({"error": f"Invalid JWT in state: {e}"}), 400

    user_id = payload.get("sub")
    if not user_id:
        return jsonify({"error": "JWT has no 'sub'"}), 400

    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404

    # Exchange code for access + refresh token
    data = {
        "code": code,
        "client_id": os.getenv("GOOGLE_CLIENT_ID"),
        "client_secret": os.getenv("GOOGLE_CLIENT_SECRET"),
        "redirect_uri": os.getenv("GOOGLE_REDIRECT_URI"),
        "grant_type": "authorization_code",
    }

    resp = requests.post("https://oauth2.googleapis.com/token", data=data)
    token_json = resp.json()

    refresh_token = token_json.get("refresh_token")

    if not refresh_token:
        # This usually means Google has already given a refresh token for this user+client
        return jsonify({
            "error": "Google did not return a refresh token. Try revoking access in your Google Account and re-linking.",
            "raw_response": token_json,
        }), 400

    # Save to DB
    user.google_refresh_token = refresh_token
    db.session.commit()

    # For local debugging we can just show JSON.
    # Later you can switch this back to a deep link: "violetvibes://calendar/linked"
    return jsonify({"status": "linked", "user_id": user.id})
