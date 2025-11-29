"""
Logging configuration for the application.
"""
import os
import logging
import sys
from logging.handlers import RotatingFileHandler
import json


def setup_logging():
    """
    Configure logging for the application.
    Uses structured JSON logging in production, simple format in development.
    """
    env = os.getenv("FLASK_ENV", os.getenv("ENVIRONMENT", "development")).lower()
    log_level = os.getenv("LOG_LEVEL", "INFO" if env == "production" else "DEBUG")
    
    # Convert string to logging level
    numeric_level = getattr(logging, log_level.upper(), logging.INFO)
    
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(numeric_level)
    
    # Remove existing handlers
    root_logger.handlers = []
    
    # Create formatter
    if env in ("production", "prod"):
        # JSON formatter for production (structured logging)
        formatter = JSONFormatter()
    else:
        # Simple formatter for development
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
    
    # Console handler (stdout for App Platform)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(numeric_level)
    console_handler.setFormatter(formatter)
    root_logger.addHandler(console_handler)
    
    # Set levels for third-party libraries
    logging.getLogger("werkzeug").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    
    logging.info(f"Logging configured for environment: {env}, level: {log_level}")


class JSONFormatter(logging.Formatter):
    """
    Custom JSON formatter for structured logging in production.
    """
    def format(self, record):
        log_data = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        
        # Add exception info if present
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        
        # Add extra fields if present
        if hasattr(record, "request_id"):
            log_data["request_id"] = record.request_id
        if hasattr(record, "user_id"):
            log_data["user_id"] = record.user_id
        if hasattr(record, "endpoint"):
            log_data["endpoint"] = record.endpoint
        
        return json.dumps(log_data)

