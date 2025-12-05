# server/services/session_service.py
"""
Session management service using Redis for caching and Postgres for persistence.
Manages user session data.
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
        user_id: User ID (CRITICAL: must be the authenticated user's ID)
        session_data: Dictionary containing session data
    
    Returns:
        True if successful, False otherwise
    """
    try:
        # CRITICAL: Verify user exists and get user object
        user = User.query.get(user_id)
        if not user:
            logger.error(f"Attempted to save session for non-existent user {user_id}")
            return False
        
        logger.info(f"Saving session for user {user_id} (email: {user.email})")
        
        # Save to Redis for fast access (user-specific key)
        redis_client = get_redis_client()
        if redis_client:
            session_key = get_user_session_key(user_id)
            redis_client.setex(
                session_key,
                SESSION_EXPIRY_SECONDS,
                json.dumps(session_data)
            )
            logger.debug(f"Session saved to Redis with key '{session_key}' for user {user_id}")
        
        # Persist to Postgres (via User model) if needed
        if 'calendar_integration_enabled' in session_data:
            settings = user.get_settings()
            settings['calendar_integration_enabled'] = session_data.get('calendar_integration_enabled', False)
            user.set_settings(settings)
            from models.db import db
            db.session.commit()
        
        return True
    except Exception as e:
        logger.error(f"Error saving session for user {user_id}: {e}", exc_info=True)
        return False


def get_user_session(user_id: int) -> Optional[Dict[str, Any]]:
    """
    Get user session data from Redis (cache) or Postgres (persistence).
    
    Args:
        user_id: User ID (CRITICAL: must be the authenticated user's ID)
    
    Returns:
        Dictionary with session data, or None if not found
    """
    try:
        # CRITICAL: Verify user exists
        user = User.query.get(user_id)
        if not user:
            logger.warning(f"Attempted to get session for non-existent user {user_id}")
            return None
        
        # Try Redis first (fast) - using user-specific key
        redis_client = get_redis_client()
        if redis_client:
            session_key = get_user_session_key(user_id)
            cached_data = redis_client.get(session_key)
            if cached_data:
                session_data = json.loads(cached_data)
                logger.debug(f"Session loaded from Redis (key: '{session_key}') for user {user_id} (email: {user.email})")
                return session_data
        
        # Fallback to Postgres (source of truth)
        settings = user.get_settings()
        session_data = {
            'calendar_integration_enabled': settings.get('calendar_integration_enabled', False),
        }
        
        # Cache in Redis for next time (user-specific key)
        if redis_client:
            session_key = get_user_session_key(user_id)
            redis_client.setex(
                session_key,
                SESSION_EXPIRY_SECONDS,
                json.dumps(session_data)
            )
            logger.debug(f"Session cached in Redis (key: '{session_key}') for user {user_id}")
        
        logger.debug(f"Session loaded from Postgres for user {user_id} (email: {user.email})")
        return session_data
    except Exception as e:
        logger.error(f"Error loading session for user {user_id}: {e}", exc_info=True)
        return None




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
        
        # Clear from Postgres if needed
        user = User.query.get(user_id)
        if user:
            settings = user.get_settings()
            settings['calendar_integration_enabled'] = False
            user.set_settings(settings)
            
            from models.db import db
            db.session.commit()
            logger.debug(f"Session cleared from Postgres for user {user_id}")
        
        return True
    except Exception as e:
        logger.error(f"Error clearing session for user {user_id}: {e}", exc_info=True)
        return False
