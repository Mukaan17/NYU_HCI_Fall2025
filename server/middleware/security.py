"""
Security headers middleware for Flask application.
"""
import os
from functools import wraps
from flask import request, Response

def add_security_headers(response: Response) -> Response:
    """Add security headers to response."""
    # Prevent MIME type sniffing
    response.headers['X-Content-Type-Options'] = 'nosniff'
    
    # Prevent clickjacking
    response.headers['X-Frame-Options'] = 'DENY'
    
    # XSS Protection (legacy, but still useful)
    response.headers['X-XSS-Protection'] = '1; mode=block'
    
    # Referrer Policy
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    
    # Content Security Policy (basic)
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    
    # Strict Transport Security (only in production with HTTPS)
    env = os.getenv("FLASK_ENV", os.getenv("ENVIRONMENT", "development")).lower()
    is_production = env in ("production", "prod")
    
    if is_production:
        # HSTS only in production
        response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    
    return response


def enforce_https():
    """Enforce HTTPS in production."""
    env = os.getenv("FLASK_ENV", os.getenv("ENVIRONMENT", "development")).lower()
    is_production = env in ("production", "prod")
    
    if is_production:
        # Check if request is over HTTPS
        # Note: In production behind a proxy (like DigitalOcean), check X-Forwarded-Proto
        forwarded_proto = request.headers.get('X-Forwarded-Proto', '')
        is_https = request.is_secure or forwarded_proto == 'https'
        
        if not is_https and request.method in ['POST', 'PUT', 'PATCH', 'DELETE']:
            from flask import jsonify
            return jsonify({"error": "HTTPS required"}), 403
    
    return None
