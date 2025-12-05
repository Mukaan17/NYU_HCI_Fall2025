"""
Input validation utilities for API endpoints.
"""
import re
import logging

logger = logging.getLogger(__name__)

# Email validation regex
EMAIL_REGEX = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')

# Coordinate ranges
MIN_LATITUDE = -90.0
MAX_LATITUDE = 90.0
MIN_LONGITUDE = -180.0
MAX_LONGITUDE = 180.0

# Request size limits (in bytes)
MAX_REQUEST_SIZE = 1024 * 1024  # 1 MB
MAX_ACTIVITY_PAYLOAD_SIZE = 10 * 1024  # 10 KB

# Numeric limits
MAX_QUICK_RECS_LIMIT = 50
MAX_DAYS_AHEAD = 30
MAX_WALK_MINUTES = 120


def validate_email(email: str) -> bool:
    """Validate email format."""
    if not email or not isinstance(email, str):
        return False
    return bool(EMAIL_REGEX.match(email.strip()))


def validate_coordinates(lat: float, lon: float) -> tuple[bool, str]:
    """
    Validate latitude and longitude coordinates.
    Returns (is_valid, error_message)
    """
    try:
        lat_float = float(lat)
        lon_float = float(lon)
    except (ValueError, TypeError):
        return False, "Coordinates must be valid numbers"
    
    if not (MIN_LATITUDE <= lat_float <= MAX_LATITUDE):
        return False, f"Latitude must be between {MIN_LATITUDE} and {MAX_LATITUDE}"
    
    if not (MIN_LONGITUDE <= lon_float <= MAX_LONGITUDE):
        return False, f"Longitude must be between {MIN_LONGITUDE} and {MAX_LONGITUDE}"
    
    return True, ""


def validate_limit(value: int, max_value: int = MAX_QUICK_RECS_LIMIT, min_value: int = 1) -> tuple[bool, int, str]:
    """
    Validate and clamp limit value.
    Returns (is_valid, clamped_value, error_message)
    """
    try:
        limit_int = int(value)
    except (ValueError, TypeError):
        return False, min_value, f"Limit must be a valid integer"
    
    if limit_int < min_value:
        return False, min_value, f"Limit must be at least {min_value}"
    
    if limit_int > max_value:
        return False, max_value, f"Limit must be at most {max_value}"
    
    return True, limit_int, ""


def validate_days(value: int, max_value: int = MAX_DAYS_AHEAD, min_value: int = 1) -> tuple[bool, int, str]:
    """
    Validate and clamp days value.
    Returns (is_valid, clamped_value, error_message)
    """
    try:
        days_int = int(value)
    except (ValueError, TypeError):
        return False, min_value, f"Days must be a valid integer"
    
    if days_int < min_value:
        return False, min_value, f"Days must be at least {min_value}"
    
    if days_int > max_value:
        return False, max_value, f"Days must be at most {max_value}"
    
    return True, days_int, ""


def validate_password(password: str, min_length: int = 8) -> tuple[bool, str]:
    """
    Validate password strength.
    Returns (is_valid, error_message)
    """
    if not password or not isinstance(password, str):
        return False, "Password is required"
    
    if len(password) < min_length:
        return False, f"Password must be at least {min_length} characters"
    
    return True, ""


def validate_activity_payload_size(data: dict) -> tuple[bool, str]:
    """
    Validate activity payload size.
    Returns (is_valid, error_message)
    """
    import json
    try:
        payload_size = len(json.dumps(data).encode('utf-8'))
        if payload_size > MAX_ACTIVITY_PAYLOAD_SIZE:
            return False, f"Activity payload too large (max {MAX_ACTIVITY_PAYLOAD_SIZE} bytes)"
        return True, ""
    except Exception as e:
        logger.error(f"Error validating activity payload size: {e}")
        return False, "Invalid activity payload"
