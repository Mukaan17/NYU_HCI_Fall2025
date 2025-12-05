"""
Configuration validation and management utilities.
"""
import os
import logging

logger = logging.getLogger(__name__)


def validate_config():
    """
    Validate that all required environment variables are set.
    Raises ValueError if any required variables are missing in production.
    """
    env = os.getenv("FLASK_ENV", os.getenv("ENVIRONMENT", "development")).lower()
    is_production = env in ("production", "prod")
    
    required_vars = {
        "JWT_SECRET": "Secret key for JWT token generation",
        "GEMINI_API_KEY": "Google Gemini API key for chat functionality",
        "DATABASE_URL": "Database connection string (PostgreSQL for production)",
    }
    
    optional_vars = {
        "REDIS_URL": "Valkey/Redis connection string for state management and caching (works with both Valkey and Redis)",
        "OPENWEATHER_KEY": "OpenWeather API key for weather data",
        "ALLOWED_ORIGINS": "Comma-separated list of allowed CORS origins",
        "FLASK_ENV": "Environment (development/production)",
        "ENVIRONMENT": "Environment (development/production)",
        "LOG_LEVEL": "Logging level (DEBUG/INFO/WARNING/ERROR)",
        "PORT": "Server port (auto-set by App Platform)",
        "INIT_DB": "Flag to initialize database on startup",
    }
    
    missing_vars = []
    for var, description in required_vars.items():
        value = os.getenv(var)
        if not value:
            if is_production:
                missing_vars.append(f"{var}: {description}")
            else:
                logger.warning(f"Required environment variable {var} not set (using default for development)")
    
    if missing_vars and is_production:
        error_msg = "Missing required environment variables in production:\n" + "\n".join(f"  - {var}" for var in missing_vars)
        raise ValueError(error_msg)
    
    # Log configuration status
    logger.info(f"Configuration validated for environment: {env}")
    if is_production:
        logger.info("Production mode: All required variables must be set")
    
    return {
        "environment": env,
        "is_production": is_production,
        "required_vars_set": len(missing_vars) == 0,
    }


def get_allowed_origins():
    """
    Get list of allowed CORS origins from environment variable.
    Falls back to localhost for development.
    """
    env = os.getenv("FLASK_ENV", os.getenv("ENVIRONMENT", "development")).lower()
    
    if env in ("production", "prod"):
        origins_str = os.getenv("ALLOWED_ORIGINS", "")
        if not origins_str:
            raise ValueError("ALLOWED_ORIGINS must be set in production")
        return [origin.strip() for origin in origins_str.split(",") if origin.strip()]
    else:
        # Development: allow localhost
        return ["http://localhost:3000", "http://localhost:5001", "http://127.0.0.1:3000", "http://127.0.0.1:5001"]


def get_jwt_secret():
    """
    Get JWT secret key. Raises error if not set.
    JWT_SECRET must be set in all environments for security.
    """
    secret = os.getenv("JWT_SECRET")
    
    if not secret:
        raise ValueError(
            "JWT_SECRET must be set in environment variables. "
            "Generate a secure secret using: python -c \"import secrets; print(secrets.token_urlsafe(32))\""
        )
    
    return secret

