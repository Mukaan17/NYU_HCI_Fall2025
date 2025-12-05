# server/services/session_service.py
"""
Session management service using Redis for caching and Postgres for persistence.
Manages user session data including Google Calendar linked status.
"""
import os
import json
import logging
from typing import Optional, Dict, Any
from datetime import timedelta
from models.users import User
from utils.context_manager import get_redis_client

logger = logging.getLogger(__name__)

# Session expiry time in Redis (7 days)
SESSION_EXPIRY_SECONDS = 7 * 24 * 60 * 60  # 7 days


def get_user_session_key(user_id: int) -> str:
    """Generate Redis key for user session."""
    return f"session:user:{user_id}"


def save_user_session(user_id: int, session_data: Dict[str, Any]) -> bool:
    """
    Save user session data to Redis (cache) and Postgres (persistence).
    
    Args:
        user_id: User ID
        session_data: Dictionary containing session data (e.g., google_calendar_linked)
    
    Returns:
        True if successful, False otherwise
    """
    try:
        # Save to Redis for fast access
        redis_client = get_redis_client()
        if redis_client:
            session_key = get_user_session_key(user_id)
            redis_client.setex(
                session_key,
                SESSION_EXPIRY_SECONDS,
                json.dumps(session_data)
            )
            logger.debug(f"Session saved to Redis for user {user_id}")
        
        # Persist to Postgres (via User model)
        user = User.query.get(user_id)
        if user:
            settings = user.get_settings()
            # Update calendar linked status in settings
            if 'google_calendar_linked' in session_data:
                settings['google_calendar_enabled'] = session_data['google_calendar_linked']
                settings['calendar_integration_enabled'] = session_data['google_calendar_linked']
                user.set_settings(settings)
                # Note: google_refresh_token is already stored in user.google_refresh_token
                # We use that as the source of truth for calendar linked status
            
            from models.db import db
            db.session.commit()
            logger.debug(f"Session persisted to Postgres for user {user_id}")
        
        return True
    except Exception as e:
        logger.error(f"Error saving session for user {user_id}: {e}", exc_info=True)
        return False


def get_user_session(user_id: int) -> Optional[Dict[str, Any]]:
    """
    Get user session data from Redis (cache) or Postgres (persistence).
    
    Args:
        user_id: User ID
    
    Returns:
        Dictionary with session data, or None if not found
    """
    try:
        # Try Redis first (fast)
        redis_client = get_redis_client()
        if redis_client:
            session_key = get_user_session_key(user_id)
            cached_data = redis_client.get(session_key)
            if cached_data:
                session_data = json.loads(cached_data)
                logger.debug(f"Session loaded from Redis for user {user_id}")
                return session_data
        
        # Fallback to Postgres (source of truth)
        user = User.query.get(user_id)
        if user:
            settings = user.get_settings()
            session_data = {
                'google_calendar_linked': bool(user.google_refresh_token),
                'google_calendar_enabled': settings.get('google_calendar_enabled', False),
                'calendar_integration_enabled': settings.get('calendar_integration_enabled', False),
            }
            
            # Cache in Redis for next time
            if redis_client:
                session_key = get_user_session_key(user_id)
                redis_client.setex(
                    session_key,
                    SESSION_EXPIRY_SECONDS,
                    json.dumps(session_data)
                )
            
            logger.debug(f"Session loaded from Postgres for user {user_id}")
            return session_data
        
        return None
    except Exception as e:
        logger.error(f"Error loading session for user {user_id}: {e}", exc_info=True)
        return None


def update_calendar_linked_status(user_id: int, linked: bool) -> bool:
    """
    Update Google Calendar linked status in session.
    
    Args:
        user_id: User ID
        linked: Whether calendar is linked
    
    Returns:
        True if successful, False otherwise
    """
    try:
        # Get current session or create new one
        session_data = get_user_session(user_id) or {}
        session_data['google_calendar_linked'] = linked
        session_data['google_calendar_enabled'] = linked
        session_data['calendar_integration_enabled'] = linked
        
        return save_user_session(user_id, session_data)
    except Exception as e:
        logger.error(f"Error updating calendar linked status for user {user_id}: {e}", exc_info=True)
        return False


def clear_user_session(user_id: int) -> bool:
    """
    Clear user session from Redis and Postgres.
    
    Args:
        user_id: User ID
    
    Returns:
        True if successful, False otherwise
    """
    try:
        # Clear from Redis
        redis_client = get_redis_client()
        if redis_client:
            session_key = get_user_session_key(user_id)
            redis_client.delete(session_key)
            logger.debug(f"Session cleared from Redis for user {user_id}")
        
        # Clear from Postgres (set calendar linked to False)
        user = User.query.get(user_id)
        if user:
            settings = user.get_settings()
            settings['google_calendar_enabled'] = False
            settings['calendar_integration_enabled'] = False
            user.set_settings(settings)
            # Note: We don't clear google_refresh_token here as it's used for calendar access
            # It should be cleared explicitly via the unlink endpoint
            
            from models.db import db
            db.session.commit()
            logger.debug(f"Session cleared from Postgres for user {user_id}")
        
        return True
    except Exception as e:
        logger.error(f"Error clearing session for user {user_id}: {e}", exc_info=True)
        return False
