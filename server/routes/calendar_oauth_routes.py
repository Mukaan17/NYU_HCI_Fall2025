# server/routes/calendar_oauth_routes.py
from flask import Blueprint, request, jsonify, redirect, g
from utils.auth import require_auth, decode_token
from models.db import db
from models.users import User
import os
import logging
import secrets
from google_auth_oauthlib.flow import Flow
from google.oauth2.credentials import Credentials
import utils.limiter as limiter_module

logger = logging.getLogger(__name__)
calendar_oauth_bp = Blueprint("calendar_oauth", __name__)

# OAuth 2.0 configuration
SCOPES = ['https://www.googleapis.com/auth/calendar.readonly']
# Backend callback URL - Google will redirect here
BACKEND_REDIRECT_URI = os.getenv("GOOGLE_OAUTH_REDIRECT_URI", "http://localhost:5001/api/calendar/oauth/callback")
# iOS app URL scheme for deep linking
IOS_APP_SCHEME = "violetvibes://calendar-oauth"

def get_oauth_flow():
    """Create OAuth flow instance."""
    return Flow.from_client_config(
        {
            "web": {
                "client_id": os.getenv("GOOGLE_CLIENT_ID"),
                "client_secret": os.getenv("GOOGLE_CLIENT_SECRET"),
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "redirect_uris": [BACKEND_REDIRECT_URI]
            }
        },
        scopes=SCOPES,
        redirect_uri=BACKEND_REDIRECT_URI
    )


@calendar_oauth_bp.route("/oauth/authorize", methods=["GET"])
@require_auth
@limiter_module.limiter.limit("10 per minute")
def authorize():
    """
    Initiate Google Calendar OAuth flow.
    Returns authorization URL for the client to open.
    """
    try:
        user = g.current_user
        
        # If already linked, return success
        if user.google_refresh_token:
            logger.info(f"Request {g.get('request_id', 'unknown')}: User {user.id} already has Google Calendar linked")
            return jsonify({
                "status": "already_linked",
                "message": "Google Calendar is already linked"
            }), 200
        
        flow = get_oauth_flow()
        # Include state with user_id for verification
        authorization_url, state = flow.authorization_url(
            access_type='offline',
            include_granted_scopes='true',
            prompt='consent',  # Force consent to get refresh token
            state=f"{user.id}"  # Include user ID in state for verification
        )
        
        # Store state in user's session or return it to client
        # For simplicity, we'll return state to client and they'll send it back in callback
        logger.info(f"Request {g.get('request_id', 'unknown')}: OAuth authorization URL generated for user {user.id}")
        
        return jsonify({
            "authorization_url": authorization_url,
            "state": state
        }), 200
        
    except Exception as e:
        logger.error(f"Request {g.get('request_id', 'unknown')}: OAuth authorization error - {e}", exc_info=True)
        return jsonify({"error": "Failed to initiate OAuth flow"}), 500


@calendar_oauth_bp.route("/oauth/callback", methods=["GET"])
@limiter_module.limiter.limit("10 per minute")
def callback():
    """
    Handle OAuth callback from Google.
    Expects: ?code=...&state=...&token=... (JWT token to identify user)
    """
    try:
        code = request.args.get('code')
        state = request.args.get('state')
        token = request.args.get('token')  # JWT token to identify user (optional, can use state)
        
        if not code:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: OAuth callback missing code")
            # Redirect to iOS app with error
            return redirect(f"{IOS_APP_SCHEME}?status=error&message=Missing authorization code", code=302)
        
        # Get user ID from state (if provided) or from token
        user_id = None
        if state:
            try:
                user_id = int(state)  # State contains user ID
            except ValueError:
                pass
        
        if not user_id and token:
            # Fallback to token if state doesn't have user ID
            try:
                payload = decode_token(token)
                user_id = payload.get('user_id')
            except Exception as e:
                logger.error(f"Request {g.get('request_id', 'unknown')}: Token decode error - {e}")
                return redirect(f"{IOS_APP_SCHEME}?status=error&message=Invalid token", code=302)
        
        if not user_id:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: OAuth callback missing user identification")
            return redirect(f"{IOS_APP_SCHEME}?status=error&message=User identification missing", code=302)
        
        user = User.query.get(user_id)
        if not user:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: User not found - {user_id}")
            return redirect(f"{IOS_APP_SCHEME}?status=error&message=User not found", code=302)
        
        # Exchange code for tokens
        flow = get_oauth_flow()
        flow.fetch_token(code=code)
        
        credentials = flow.credentials
        
        # Store refresh token
        if credentials.refresh_token:
            user.google_refresh_token = credentials.refresh_token
            
            # Update settings to mark calendar as enabled
            settings = user.get_settings()
            settings['google_calendar_enabled'] = True
            settings['calendar_integration_enabled'] = True
            user.set_settings(settings)
            
            db.session.commit()
            
            # Update session in Redis and Postgres
            from services.session_service import update_calendar_linked_status
            update_calendar_linked_status(user.id, True)
            
            logger.info(f"Request {g.get('request_id', 'unknown')}: Google Calendar linked for user {user.id}")
            
            # Redirect to iOS app with success
            # iOS app URL scheme: violetvibes://calendar-oauth?status=success
            redirect_url = f"violetvibes://calendar-oauth?status=success&user_id={user_id}"
            return redirect(redirect_url, code=302)
        else:
            logger.warning(f"Request {g.get('request_id', 'unknown')}: No refresh token received for user {user.id}")
            return redirect(f"{IOS_APP_SCHEME}?status=error&message=Failed to obtain refresh token", code=302)
            
    except Exception as e:
        logger.error(f"Request {g.get('request_id', 'unknown')}: OAuth callback error - {e}", exc_info=True)
        db.session.rollback()
        return redirect(f"{IOS_APP_SCHEME}?status=error&message=Failed to complete OAuth flow", code=302)


@calendar_oauth_bp.route("/oauth/unlink", methods=["POST"])
@require_auth
@limiter_module.limiter.limit("5 per minute")
def unlink():
    """
    Unlink Google Calendar from user account.
    """
    try:
        user = g.current_user
        
        if not user.google_refresh_token:
            return jsonify({"error": "Google Calendar is not linked"}), 400
        
        user.google_refresh_token = None
        
        # Update settings
        settings = user.get_settings()
        settings['google_calendar_enabled'] = False
        settings['calendar_integration_enabled'] = False
        user.set_settings(settings)
        
        db.session.commit()
        
        # Update session in Redis and Postgres
        from services.session_service import update_calendar_linked_status
        update_calendar_linked_status(user.id, False)
        
        logger.info(f"Request {g.get('request_id', 'unknown')}: Google Calendar unlinked for user {user.id}")
        
        return jsonify({
            "status": "success",
            "message": "Google Calendar unlinked successfully"
        }), 200
        
    except Exception as e:
        logger.error(f"Request {g.get('request_id', 'unknown')}: Unlink error - {e}", exc_info=True)
        db.session.rollback()
        return jsonify({"error": "Failed to unlink Google Calendar"}), 500
