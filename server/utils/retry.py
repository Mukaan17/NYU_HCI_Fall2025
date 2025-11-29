"""
Retry utilities for external API calls with exponential backoff.
"""
import logging
from functools import wraps
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
    RetryError
)
import requests

logger = logging.getLogger(__name__)


def retry_api_call(max_attempts=3, min_wait=1, max_wait=10):
    """
    Decorator for retrying API calls with exponential backoff.
    
    Args:
        max_attempts: Maximum number of retry attempts
        min_wait: Minimum wait time in seconds
        max_wait: Maximum wait time in seconds
    """
    def decorator(func):
        @wraps(func)
        @retry(
            stop=stop_after_attempt(max_attempts),
            wait=wait_exponential(multiplier=min_wait, min=min_wait, max=max_wait),
            retry=retry_if_exception_type((requests.RequestException, ConnectionError, TimeoutError)),
            reraise=True
        )
        def wrapper(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except RetryError as e:
                logger.error(f"API call {func.__name__} failed after {max_attempts} attempts: {e}")
                raise e.last_attempt.exception()
            except Exception as e:
                logger.warning(f"API call {func.__name__} failed: {e}")
                raise
        
        return wrapper
    return decorator

