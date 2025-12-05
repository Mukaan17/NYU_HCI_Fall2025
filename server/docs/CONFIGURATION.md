# Configuration Reference

## Environment Variables

### Required Variables

#### `JWT_SECRET`
- **Type**: String
- **Required**: Yes (in production)
- **Description**: Secret key for JWT token generation and validation
- **Example**: `your-secret-key-here-change-in-production`
- **Security**: Must be a strong, random string. Never commit to version control.
- **Default**: `dev-secret-change-me` (development only)

#### `GEMINI_API_KEY`
- **Type**: String
- **Required**: Yes
- **Description**: Google Gemini API key for chat functionality
- **Example**: `AIzaSy...`
- **How to Get**: [Google AI Studio](https://makersuite.google.com/app/apikey)

#### `DATABASE_URL`
- **Type**: String (PostgreSQL connection string)
- **Required**: Yes (in production)
- **Description**: Database connection string for PostgreSQL
- **Format**: `postgresql://user:password@host:port/database?sslmode=require`
- **Example**: `postgresql://user:pass@db.example.com:5432/violetvibes?sslmode=require`
- **Default**: SQLite (`sqlite:///violetvibes.db`) for development

### Optional Variables

#### `REDIS_URL`
- **Type**: String (Redis/Valkey connection string)
- **Required**: No (but recommended for production)
- **Description**: Redis/Valkey connection string for state management and caching
- **Format**: `redis://user:password@host:port/database`
- **Example**: `redis://default:password@valkey.example.com:6379/0`
- **Impact**: If not set, uses in-memory storage (not shared across workers)
- **Note**: DigitalOcean offers Valkey (Redis-compatible), which works with the same connection string format

#### `OPENWEATHER_KEY`
- **Type**: String
- **Required**: No
- **Description**: OpenWeather API key for weather data
- **Example**: `dbb5ec5c928fa184644c1d33f2d9b396`
- **How to Get**: [OpenWeather API](https://openweathermap.org/api)

#### `ALLOWED_ORIGINS`
- **Type**: String (comma-separated)
- **Required**: No (required in production)
- **Description**: Comma-separated list of allowed CORS origins
- **Example**: `https://your-frontend.com,https://another-domain.com`
- **Default**: Localhost origins for development
- **Security**: Must be set in production to restrict CORS

#### `FLASK_ENV`
- **Type**: String
- **Required**: No
- **Description**: Environment mode (development/production)
- **Values**: `development`, `production`, `prod`
- **Default**: `development`
- **Impact**: Affects logging, error handling, and security settings

#### `ENVIRONMENT`
- **Type**: String
- **Required**: No
- **Description**: Alternative to `FLASK_ENV` for environment mode
- **Values**: `development`, `production`, `prod`
- **Default**: `development`

#### `LOG_LEVEL`
- **Type**: String
- **Required**: No
- **Description**: Logging level
- **Values**: `DEBUG`, `INFO`, `WARNING`, `ERROR`
- **Default**: `DEBUG` (development), `INFO` (production)
- **Impact**: Controls verbosity of logs

#### `PORT`
- **Type**: Integer
- **Required**: No (auto-set by App Platform)
- **Description**: Server port
- **Default**: `5001` (development)
- **Note**: Automatically set by DigitalOcean App Platform

#### `INIT_DB`
- **Type**: Boolean (string: "true"/"false")
- **Required**: No
- **Description**: Flag to initialize database on startup
- **Default**: `false`
- **Usage**: Set to `true` to run `db.create_all()` on startup

## Configuration Files

### `runtime.txt`

Specifies Python version for App Platform.

**Format:**
```
python-3.11.0
```

**Supported Versions:**
- `python-3.11.0`
- `python-3.12.0`

### `app.yaml`

DigitalOcean App Platform configuration file (optional but recommended).

**Key Sections:**
- `name`: App name
- `region`: Deployment region
- `services`: Service configuration
  - `build_command`: Command to build app
  - `run_command`: Command to run app
  - `health_check`: Health check configuration
  - `envs`: Environment variables
- `databases`: Database configuration

See `app.yaml` in repository root for example.

### `.env.example`

Template for environment variables. Copy to `.env` for local development.

**Note**: Never commit `.env` file to version control.

## Database Configuration

### PostgreSQL Connection String

Format:
```
postgresql://[user[:password]@][host][:port][/database][?sslmode=require]
```

Components:
- `user`: Database username
- `password`: Database password
- `host`: Database hostname
- `port`: Database port (default: 5432)
- `database`: Database name
- `sslmode`: SSL mode (use `require` for production)

### Connection Pooling

Configured in `app.py`:
- `pool_size`: 10 connections
- `max_overflow`: 20 connections
- `pool_pre_ping`: True (verify connections before use)
- `pool_recycle`: 3600 seconds (recycle connections after 1 hour)

## Redis/Valkey Configuration

### Connection String

Format:
```
redis://[user[:password]@][host][:port][/database]
```

Components:
- `user`: Redis/Valkey username (optional)
- `password`: Redis/Valkey password
- `host`: Redis/Valkey hostname
- `port`: Redis/Valkey port (default: 6379)
- `database`: Database number (0-15)

**Note**: DigitalOcean now offers **Valkey** (a Redis-compatible fork) instead of Redis. Valkey uses the same protocol and connection string format, so the `redis` Python client works seamlessly with Valkey.

### Usage

Redis/Valkey is used for:
- Conversation context storage (shared across workers)
- Request caching
- Rate limiting storage

If Redis/Valkey is unavailable, the app falls back to in-memory storage.

## CORS Configuration

### Development

Automatically allows:
- `http://localhost:3000`
- `http://localhost:5001`
- `http://127.0.0.1:3000`
- `http://127.0.0.1:5001`

### Production

Must set `ALLOWED_ORIGINS` environment variable:
```
ALLOWED_ORIGINS=https://your-frontend.com,https://another-domain.com
```

## Rate Limiting Configuration

Configured in `app.py`:

**Default Limits:**
- 200 requests per day
- 50 requests per hour

**Per-Endpoint Limits:**
- `/api/chat`: 10 requests per minute
- `/api/auth/*`: 5 requests per minute
- `/api/quick_recs`: 30 requests per minute

**Storage:**
- Redis/Valkey (if `REDIS_URL` is set)
- Memory (fallback)

## Logging Configuration

### Log Levels

- `DEBUG`: Detailed information for debugging
- `INFO`: General informational messages
- `WARNING`: Warning messages
- `ERROR`: Error messages

### Log Format

**Development:**
```
2025-01-15 10:30:45 - app - INFO - Request abc123: GET /api/chat
```

**Production (JSON):**
```json
{
  "timestamp": "2025-01-15 10:30:45",
  "level": "INFO",
  "logger": "app",
  "message": "Request abc123: GET /api/chat",
  "request_id": "abc123"
}
```

### Log Output

All logs go to `stdout` and are captured by DigitalOcean App Platform.

## Gunicorn Configuration

Configured in `app.yaml` or run command:

- `--workers 2`: Number of worker processes
- `--timeout 120`: Request timeout in seconds
- `--worker-tmp-dir /dev/shm`: Use shared memory for worker temp files
- `--bind 0.0.0.0:$PORT`: Bind address and port

**Worker Count Formula:**
```
(2 × CPU cores) + 1
```

For App Platform Basic plan: 2-4 workers recommended.

## Health Check Configuration

Endpoint: `/health`

**Response Format:**
```json
{
  "status": "ok",
  "database": "connected",
  "redis": "connected"
}
```

**Status Values:**
- `ok`: All systems operational
- `connected`: Component is connected
- `disconnected`: Component connection failed
- `not_configured`: Component not configured

## Security Configuration

### JWT Secret

- Must be set in production
- Should be at least 32 characters
- Use cryptographically secure random generator
- Rotate periodically

### CORS

- Must restrict origins in production
- Never use `*` in production
- Validate origins match expected frontend domains

### Rate Limiting

- Prevents abuse and DoS attacks
- Configured per endpoint
- Uses Redis for distributed rate limiting

## Validation

Configuration is validated on application startup via `utils.config.validate_config()`.

**Production Checks:**
- All required environment variables must be set
- `JWT_SECRET` cannot use default value
- `ALLOWED_ORIGINS` must be set

**Development:**
- Warnings for missing variables
- Defaults allowed for development

## Troubleshooting

### Configuration Not Loading

- Check environment variables are set correctly
- Verify `.env` file format (if using locally)
- Check App Platform environment variable settings

### Database Connection Issues

- Verify `DATABASE_URL` format
- Check database firewall rules
- Ensure database is accessible from app region

### Redis/Valkey Connection Issues

- Verify `REDIS_URL` format
- Check Valkey/Redis firewall rules
- App will fall back to memory if Redis/Valkey unavailable
- **Note**: DigitalOcean offers Valkey (Redis-compatible), which uses the same connection string format

For more troubleshooting, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

