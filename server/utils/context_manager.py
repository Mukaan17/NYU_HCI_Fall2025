"""
Redis-backed conversation context manager for shared state across workers.
"""
import os
import json
import logging
from typing import List, Dict, Any, Optional
import redis
from services.recommendation.context import ConversationContext

logger = logging.getLogger(__name__)

# Global Redis client (lazy initialization)
_redis_client = None


def get_redis_client():
    """
    Get or create Redis client. Returns None if Redis is not available.
    """
    global _redis_client
    
    if _redis_client is not None:
        return _redis_client
    
    redis_url = os.getenv("REDIS_URL")
    if not redis_url:
        logger.warning("REDIS_URL not set, using in-memory context (not shared across workers)")
        return None
    
    try:
        _redis_client = redis.from_url(redis_url, decode_responses=True)
        # Test connection
        _redis_client.ping()
        logger.info("Redis connection established")
        return _redis_client
    except Exception as e:
        logger.warning(f"Failed to connect to Redis: {e}. Using in-memory context.")
        return None


class ConversationContextManager:
    """
    Manages conversation context using Redis for shared state across workers.
    Falls back to in-memory storage if Redis is unavailable.
    """
    
    def __init__(self, user_id: Optional[str] = None, session_id: Optional[str] = None):
        """
        Initialize context manager.
        
        Args:
            user_id: User ID for user-specific context
            session_id: Session ID for anonymous sessions
        """
        self.user_id = user_id
        self.session_id = session_id
        self.redis_client = get_redis_client()
        self._in_memory_context: Optional[ConversationContext] = None
        
        # Generate key for Redis storage
        if user_id:
            self.key = f"conversation:user:{user_id}"
        elif session_id:
            self.key = f"conversation:session:{session_id}"
        else:
            # Fallback to a default key (not recommended for production)
            self.key = "conversation:default"
            logger.warning("No user_id or session_id provided, using default key")
    
    def get_context(self) -> ConversationContext:
        """
        Get conversation context from Redis or create new one.
        """
        if self.redis_client:
            try:
                data = self.redis_client.get(self.key)
                if data:
                    context_data = json.loads(data)
                    context = ConversationContext()
                    context.history = context_data.get("history", [])
                    context.last_places = context_data.get("last_places", [])
                    context.all_results = context_data.get("all_results", [])
                    context.result_index = context_data.get("result_index", 0)
                    context.context = context_data.get("context")
                    context.last_intent = context_data.get("last_intent")
                    return context
            except Exception as e:
                logger.error(f"Error loading context from Redis: {e}")
        
        # Fallback to in-memory or create new
        if self._in_memory_context is None:
            self._in_memory_context = ConversationContext()
        return self._in_memory_context
    
    def save_context(self, context: ConversationContext):
        """
        Save conversation context to Redis.
        """
        if self.redis_client:
            try:
                context_data = {
                    "history": context.history,
                    "last_places": context.last_places,
                    "all_results": context.all_results,
                    "result_index": context.result_index,
                    "context": context.context,
                    "last_intent": context.last_intent,
                }
                # Store with 24 hour expiration
                self.redis_client.setex(
                    self.key,
                    86400,  # 24 hours
                    json.dumps(context_data)
                )
            except Exception as e:
                logger.error(f"Error saving context to Redis: {e}")
        else:
            # In-memory fallback
            self._in_memory_context = context
    
    def clear_context(self):
        """
        Clear conversation context from Redis.
        """
        if self.redis_client:
            try:
                self.redis_client.delete(self.key)
            except Exception as e:
                logger.error(f"Error clearing context from Redis: {e}")
        
        self._in_memory_context = None

