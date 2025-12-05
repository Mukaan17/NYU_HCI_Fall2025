# DigitalOcean Migration Changes

This document outlines all backend changes made for DigitalOcean App Platform compatibility. Apply these changes when pulling the `Final_v1` branch to ensure seamless deployment without breaking functionality.

## Date: Current Session

---

## Overview

The backend was migrated from a local development setup to DigitalOcean App Platform, requiring several configuration and code changes for production deployment. All changes maintain backward compatibility with local development.

---

## 1. Configuration Files

### 1.1 `app.yaml` - DigitalOcean App Platform Configuration

**File**: `server/app.yaml`

**Purpose**: Defines the app structure, build commands, health checks, and environment variables for DigitalOcean App Platform.

**Create/Update this file**:

```yaml
name: violetvibes-backend
region: nyc

services:
  - name: api
    github:
      repo: your-username/your-repo
      branch: main
      deploy_on_push: true
    
    build_command: pip install -r requirements.txt
    
    run_command: gunicorn --worker-tmp-dir /dev/shm --workers 2 --timeout 120 --bind 0.0.0.0:$PORT app:app
    
    http_port: 8080
    
    instance_count: 1
    instance_size_slug: basic-xxs
    
    health_check:
      http_path: /health
      initial_delay_seconds: 10
      period_seconds: 10
      timeout_seconds: 5
      success_threshold: 1
      failure_threshold: 3
    
    envs:
      - key: FLASK_ENV
        value: production
      - key: PORT
        value: ${PORT}
      - key: JWT_SECRET
        scope: RUN_TIME
        type: SECRET
      - key: GEMINI_API_KEY
        scope: RUN_TIME
        type: SECRET
      - key: DATABASE_URL
        scope: RUN_TIME
        type: SECRET
      - key: REDIS_URL
        scope: RUN_TIME
        type: SECRET
      - key: OPENWEATHER_KEY
        scope: RUN_TIME
        type: SECRET
      - key: ALLOWED_ORIGINS
        scope: RUN_TIME
        type: SECRET
      - key: LOG_LEVEL
        value: INFO

databases:
  - name: violetvibes-db
    engine: PG
    version: "15"
    production: false
    cluster_name: violetvibes-db-cluster
```

**Key Points**:
- `run_command` uses Gunicorn with worker configuration optimized for App Platform
- `http_port: 8080` is required by DigitalOcean
- Health check endpoint configured at `/health`
- All sensitive values use `type: SECRET` and `scope: RUN_TIME`
- Database configuration included (can be managed separately)

---

### 1.2 `runtime.txt` - Python Version Specification

**File**: `server/runtime.txt`

**Purpose**: Specifies the Python version for DigitalOcean App Platform.

**Create/Update this file**:

```
python-3.11.0
```

**Note**: Ensure this matches the Python version used in development and that all dependencies are compatible.

---

### 1.3 `requirements.txt` - Production Dependencies

**File**: `server/requirements.txt`

**Purpose**: Lists all Python dependencies including production-specific packages.

**Ensure these packages are included**:

```txt
Flask==3.0.0
flask-sqlalchemy==3.1.1
flask-bcrypt==1.0.1
flask-cors==4.0.0
flask-limiter==3.5.0
PyJWT==2.8.0
python-dotenv==1.0.1
requests==2.32.3
google-generativeai
google-api-python-client==2.149.0
google-auth-httplib2==0.2.0
google-auth-oauthlib==1.2.1
requests-cache==1.2.0
openai==1.51.2
beautifulsoup4==4.12.3
lxml==5.1.0
redis==5.0.1
tenacity==8.2.3
gunicorn==21.2.0
psycopg2-binary==2.9.9
```

**Key Production Packages**:
- `gunicorn==21.2.0` - WSGI HTTP server for production
- `psycopg2-binary==2.9.9` - PostgreSQL adapter (required for production database)
- `redis==5.0.1` - Redis client for caching and state management

---

## 2. Application Code Changes

### 2.1 Health Check Endpoint

**File**: `server/app.py`

**Location**: Add after the directions route (around line 163)

**Add this endpoint**:

```python
# ─────────────────────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    """
    Health check endpoint for DigitalOcean App Platform.
    Checks database and Redis connectivity.
    """
    status = {
        "status": "ok",
        "database": "not_configured",
        "redis": "not_configured"
    }
    http_status = 200
    
    # Check database connectivity
    try:
        from models.db import db
        with app.app_context():
            db.session.execute(db.text("SELECT 1"))
        status["database"] = "connected"
    except Exception as e:
        status["database"] = "disconnected"
        logger.warning(f"Health check: Database connection failed - {e}")
        http_status = 503  # Service Unavailable
    
    # Check Redis connectivity (optional)
    redis_url = os.getenv("REDIS_URL")
    if redis_url:
        try:
            import redis
            redis_client = redis.from_url(redis_url)
            redis_client.ping()
            status["redis"] = "connected"
        except Exception as e:
            status["redis"] = "disconnected"
            logger.warning(f"Health check: Redis connection failed - {e}")
    # If REDIS_URL not set, redis status remains "not_configured" (OK)
    
    return jsonify(status), http_status
```

**Purpose**: 
- DigitalOcean App Platform uses this endpoint for health monitoring
- Returns 200 if healthy, 503 if database is down
- Checks both database and Redis connectivity

---

### 2.2 Database Configuration - PostgreSQL Support

**File**: `server/app.py`

**Location**: Replace the database configuration section (around line 50-52)

**Current code** (development only):
```python
# Database config
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///violetvibes.db"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
```

**Replace with** (supports both SQLite and PostgreSQL):
```python
# Database config - supports both SQLite (dev) and PostgreSQL (production)
database_url = os.getenv("DATABASE_URL")
if database_url:
    # Production: Use PostgreSQL from DATABASE_URL
    app.config["SQLALCHEMY_DATABASE_URI"] = database_url
else:
    # Development: Use SQLite
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///violetvibes.db"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
```

**Purpose**: 
- Automatically uses PostgreSQL when `DATABASE_URL` is set (production)
- Falls back to SQLite for local development
- Maintains backward compatibility

---

### 2.3 Configuration Validation Utilities

**File**: `server/utils/config.py`

**Purpose**: Validates environment variables and provides configuration helpers.

**Create this file if it doesn't exist**:

```python
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
        "REDIS_URL": "Redis connection string for state management and caching",
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
```

**Usage in app.py** (optional but recommended):
```python
from utils.config import validate_config, get_allowed_origins

# Validate configuration on startup
try:
    config_status = validate_config()
    logger.info(f"Configuration status: {config_status}")
except ValueError as e:
    logger.error(f"Configuration error: {e}")
    # In production, you might want to exit here
```

---

### 2.4 Redis-Backed Caching

**File**: `server/utils/cache.py`

**Purpose**: Provides Redis-backed caching with fallback to memory cache.

**Create this file if it doesn't exist**:

```python
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
```

**Usage in app.py**:
```python
from utils.cache import init_requests_cache

# Initialize cache (should be called early in app setup)
init_requests_cache()
```

---

### 2.5 CORS Configuration Update

**File**: `server/app.py`

**Location**: Replace CORS initialization (around line 37)

**Current code**:
```python
CORS(app, resources={r"/api/*": {"origins": "*"}})
```

**Replace with** (environment-aware CORS):
```python
from utils.config import get_allowed_origins

# CORS configuration - environment-aware
try:
    allowed_origins = get_allowed_origins()
    CORS(app, resources={r"/api/*": {"origins": allowed_origins}})
    logger.info(f"CORS configured with origins: {allowed_origins}")
except ValueError as e:
    logger.warning(f"CORS configuration error: {e}. Using wildcard for development.")
    CORS(app, resources={r"/api/*": {"origins": "*"}})
```

**Purpose**: 
- Restricts CORS in production to specified origins
- Allows all origins in development for easier testing

---

### 2.6 Logging Configuration

**File**: `server/app.py`

**Location**: Update logging setup (around line 42-44)

**Current code**:
```python
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
```

**Replace with** (environment-aware logging):
```python
import logging
import sys

# Configure logging based on environment
log_level = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=getattr(logging, log_level, logging.INFO),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)
logger.info(f"Logging configured at level: {log_level}")
```

**Purpose**: 
- Configurable log levels via `LOG_LEVEL` environment variable
- Structured logging format for production
- Logs to stdout (captured by DigitalOcean)

---

### 2.7 Main Entry Point Update

**File**: `server/app.py`

**Location**: Update the `if __name__ == "__main__"` block (around line 211)

**Current code**:
```python
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
```

**Replace with** (production-aware):
```python
if __name__ == "__main__":
    # Get port from environment (DigitalOcean sets PORT)
    port = int(os.getenv("PORT", 5001))
    # Only enable debug in development
    debug = os.getenv("FLASK_ENV", "development").lower() != "production"
    app.run(host="0.0.0.0", port=port, debug=debug)
```

**Purpose**: 
- Uses `PORT` environment variable (set by DigitalOcean)
- Disables debug mode in production
- Maintains local development behavior

---

## 3. Environment Variables

### Required in Production

These must be set in DigitalOcean App Platform:

1. **JWT_SECRET** (SECRET)
   - Secret key for JWT token generation
   - Generate: `python -c "import secrets; print(secrets.token_urlsafe(32))"`

2. **GEMINI_API_KEY** (SECRET)
   - Google Gemini API key for chat functionality

3. **DATABASE_URL** (SECRET)
   - PostgreSQL connection string
   - Format: `postgresql://user:password@host:port/database?sslmode=require`
   - Provided by DigitalOcean Managed Database

4. **FLASK_ENV**
   - Set to `production` in production

### Optional but Recommended

5. **REDIS_URL** (SECRET)
   - Redis/Valkey connection string for caching and state management
   - Format: `redis://user:password@host:port/db`
   - Provided by DigitalOcean Managed Valkey (Redis-compatible)
   - **Note**: DigitalOcean now offers Valkey instead of Redis, but it's fully compatible

6. **OPENWEATHER_KEY** (SECRET)
   - OpenWeather API key for weather data

7. **ALLOWED_ORIGINS** (SECRET)
   - Comma-separated list of allowed CORS origins
   - Example: `https://your-app.com,https://www.your-app.com`

8. **LOG_LEVEL**
   - Set to `INFO` for production, `DEBUG` for development

9. **PORT**
   - Automatically set by DigitalOcean App Platform
   - Do not manually set this

---

## 4. Database Migration (SQLite → PostgreSQL)

### Migration Script

**File**: `server/migrate_to_postgresql.py`

**Purpose**: Migrates data from SQLite to PostgreSQL.

**Note**: This script should already exist. If not, create it based on the migration guide in `server/docs/MIGRATION.md`.

**Usage**:
```bash
export DATABASE_URL="postgresql://user:password@host:port/database?sslmode=require"
python migrate_to_postgresql.py
```

---

## 5. Gunicorn Configuration

### Run Command

The `app.yaml` specifies:
```bash
gunicorn --worker-tmp-dir /dev/shm --workers 2 --timeout 120 --bind 0.0.0.0:$PORT app:app
```

**Key Parameters**:
- `--worker-tmp-dir /dev/shm`: Uses shared memory for better performance
- `--workers 2`: Number of worker processes (adjust based on instance size)
- `--timeout 120`: Request timeout in seconds
- `--bind 0.0.0.0:$PORT`: Binds to all interfaces on the PORT environment variable

**For Local Testing**:
```bash
gunicorn --workers 2 --timeout 120 --bind 0.0.0.0:5001 app:app
```

---

## 6. Testing Checklist

After applying changes, verify:

- [ ] Health endpoint returns 200: `curl https://your-app.ondigitalocean.app/health`
- [ ] Database connectivity works (check health endpoint response)
- [ ] Redis connectivity works (if REDIS_URL is set)
- [ ] All API endpoints respond correctly
- [ ] CORS is properly configured (test from frontend)
- [ ] Logs are visible in DigitalOcean dashboard
- [ ] Environment variables are set correctly
- [ ] Database migrations completed successfully

---

## 7. Deployment Steps

1. **Commit all changes** to the repository
2. **Push to the branch** specified in `app.yaml` (typically `main`)
3. **DigitalOcean will automatically deploy** if `deploy_on_push: true`
4. **Set environment variables** in DigitalOcean App Platform dashboard
5. **Create managed database** (PostgreSQL) in DigitalOcean
6. **Create managed Valkey** (Redis-compatible, optional but recommended) in DigitalOcean
7. **Link database and Valkey** to the app in DigitalOcean dashboard
8. **Run database migrations** if needed
9. **Verify health endpoint** is responding
10. **Test all API endpoints**

---

## 8. Rollback Plan

If issues occur:

1. **Revert to previous deployment** in DigitalOcean dashboard
2. **Check logs** in DigitalOcean dashboard for errors
3. **Verify environment variables** are set correctly
4. **Test health endpoint** to identify failing components
5. **Check database connectivity** separately
6. **Review application logs** for specific error messages

---

## 9. Key Differences: Development vs Production

| Aspect | Development | Production (DigitalOcean) |
|--------|-------------|---------------------------|
| Database | SQLite | PostgreSQL (via DATABASE_URL) |
| Cache | Memory | Redis (if REDIS_URL set) |
| Server | Flask dev server | Gunicorn |
| Port | 5001 (fixed) | $PORT (dynamic) |
| Debug | Enabled | Disabled |
| CORS | All origins | Restricted origins |
| Logging | DEBUG/INFO | INFO |
| Health Check | Optional | Required |

---

## 10. Files Summary

### New Files Created:
1. `server/app.yaml` - DigitalOcean App Platform configuration
2. `server/runtime.txt` - Python version specification
3. `server/utils/config.py` - Configuration validation utilities
4. `server/utils/cache.py` - Redis-backed caching

### Files Modified:
1. `server/app.py` - Health endpoint, database config, CORS, logging, main entry
2. `server/requirements.txt` - Added gunicorn, psycopg2-binary, redis

### Files to Review:
1. `server/migrate_to_postgresql.py` - Database migration script (should exist)

---

## 11. Important Notes

1. **Backward Compatibility**: All changes maintain backward compatibility with local development
2. **Environment Detection**: Code automatically detects production vs development
3. **Graceful Degradation**: Redis and PostgreSQL are optional (with fallbacks)
4. **No Breaking Changes**: Existing functionality remains intact
5. **Configuration Validation**: Production mode validates required environment variables

---

## 12. Troubleshooting

### Common Issues:

1. **Health check failing**:
   - Check database connectivity
   - Verify DATABASE_URL format
   - Check logs for specific errors

2. **Database connection errors**:
   - Verify DATABASE_URL is set correctly
   - Check database is accessible from App Platform
   - Ensure SSL mode is set: `?sslmode=require`

3. **Redis/Valkey connection errors**:
   - Verify REDIS_URL is set correctly
   - Check Valkey is accessible from App Platform
   - App will fall back to memory cache if Valkey/Redis fails
   - **Note**: DigitalOcean offers Valkey (Redis-compatible), which works with the same connection string format

4. **CORS errors**:
   - Verify ALLOWED_ORIGINS includes your frontend URL
   - Check CORS configuration in app.py

5. **Port binding errors**:
   - Ensure using $PORT environment variable
   - Do not hardcode port numbers

---

## Conclusion

All changes are designed to be non-breaking and maintain full backward compatibility with local development. The application will automatically adapt based on environment variables, making it seamless to deploy to DigitalOcean while still working locally.

