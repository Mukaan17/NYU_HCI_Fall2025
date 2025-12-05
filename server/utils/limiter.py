"""
Rate limiter configuration for Flask-Limiter.
"""
import os
import logging
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

logger = logging.getLogger(__name__)

# Global limiter instance - initialized early with a dummy app, then re-initialized properly
limiter = None


class NoOpLimiter:
    """No-op limiter that can be used before the real limiter is initialized."""
    def limit(self, *args, **kwargs):
        def decorator(f):
            return f
        return decorator
    
    def exempt(self, f):
        """Exempt a function from rate limiting."""
        return f


def init_limiter(app):
    """Initialize rate limiter with Valkey/Redis or memory backend."""
    global limiter
    
    redis_url = os.getenv("REDIS_URL")
    if redis_url:
        # Use Valkey/Redis for distributed rate limiting (works with both)
        limiter = Limiter(
            app=app,
            key_func=get_remote_address,
            storage_uri=redis_url,
            default_limits=["200 per day", "50 per hour"],
            strategy="fixed-window"
        )
        logger.info("Rate limiter initialized with Valkey/Redis backend")
    else:
        # Fallback to memory (not shared across workers)
        limiter = Limiter(
            app=app,
            key_func=get_remote_address,
            default_limits=["200 per day", "50 per hour"],
            strategy="fixed-window"
        )
        logger.warning("Rate limiter initialized with memory backend (not shared across workers)")
    
    return limiter


# Initialize with no-op limiter so routes can use it at import time
limiter = NoOpLimiter()
