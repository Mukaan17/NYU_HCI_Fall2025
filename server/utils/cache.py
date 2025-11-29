"""
Cache initialization with Redis backend support.
Falls back to memory cache if Redis is unavailable.
"""
import os
import logging
import requests_cache
from datetime import timedelta
import redis

logger = logging.getLogger(__name__)


def init_requests_cache():
    """
    Initialize requests cache with Redis backend if available,
    otherwise use memory cache.
    """
    redis_url = os.getenv("REDIS_URL")
    
    if redis_url:
        try:
            # Test Redis connection
            redis_client = redis.from_url(redis_url)
            redis_client.ping()
            
            # Use Redis backend for requests_cache
            requests_cache.install_cache(
                "requests_cache",
                backend="redis",
                connection=redis_client,
                expire_after=timedelta(minutes=5),
                allowable_methods=("GET",),
            )
            logger.info("Requests cache initialized with Redis backend")
            return
        except Exception as e:
            logger.warning(f"Failed to initialize Redis cache: {e}. Using memory cache.")
    
    # Fallback to memory cache
    requests_cache.install_cache(
        "requests_cache",
        backend="memory",
        expire_after=timedelta(minutes=5),
        allowable_methods=("GET",),
    )
    logger.info("Requests cache initialized with memory backend")