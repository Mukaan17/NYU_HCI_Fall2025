# Quick Testing Guide

## Prerequisites

1. **Install dependencies**:
   ```bash
   cd server
   pip install -r requirements.txt
   ```

2. **Set environment variables**:
   ```bash
   export JWT_SECRET="test-secret-key"
   export GEMINI_API_KEY="your-gemini-api-key"
   export FLASK_ENV="development"
   export LOG_LEVEL="DEBUG"
   ```

## Quick Test (5 minutes)

### 1. Start the Server

```bash
python app.py
```

You should see:
```
Logging configured for environment: development, level: DEBUG
CORS configured for origins: ['http://localhost:3000', ...]
Using SQLite database (development only)
Rate limiting configured with memory backend
 * Running on http://0.0.0.0:5001
```

### 2. Test Health Endpoint

In a new terminal:
```bash
curl http://localhost:5001/health
```

Expected:
```json
{"status":"ok","database":"connected","redis":"not_configured"}
```

### 3. Run Automated Tests

```bash
./test_api.sh
```

This will test:
- Health check
- Sign up
- Login
- User profile
- Chat
- Quick recommendations
- Directions
- Events
- Error handling

### 4. Manual Test - Chat

```bash
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"I want coffee"}'
```

Should return AI reply and places.

## Testing Specific Features

### Test Rate Limiting

```bash
# Make 6 rapid login attempts (limit is 5/minute)
for i in {1..6}; do
  curl -X POST http://localhost:5001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"wrong"}' \
    -w " Status: %{http_code}\n"
done
```

6th request should return `429 Too Many Requests`.

### Test Authentication Flow

```bash
# 1. Sign up
curl -X POST http://localhost:5001/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"password123"}'

# Copy the token from response, then:

# 2. Get profile
curl -X GET http://localhost:5001/api/user/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Test Error Handling

```bash
# Missing field
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -d '{}'
# Should return 400

# Invalid endpoint
curl http://localhost:5001/api/nonexistent
# Should return 404
```

## Testing with Redis (Optional)

If you have Redis installed:

```bash
# Start Redis
redis-server

# Set REDIS_URL
export REDIS_URL="redis://localhost:6379/0"

# Restart server
python app.py

# Test - conversation context should persist across requests
```

## Testing Production Configuration

```bash
# Set production environment
export FLASK_ENV="production"
export JWT_SECRET="strong-production-secret-here"
export ALLOWED_ORIGINS="https://your-frontend.com"
export DATABASE_URL="postgresql://user:pass@host:5432/db"
export LOG_LEVEL="INFO"

# Test with Gunicorn
gunicorn --workers 2 --timeout 120 --bind 0.0.0.0:5001 app:app
```

## Common Issues

**Server won't start**:
- Check Python version: `python --version` (need 3.11+)
- Install dependencies: `pip install -r requirements.txt`
- Check for port conflicts: `lsof -i :5001`

**Tests fail**:
- Ensure server is running
- Check environment variables are set
- Review server logs for errors

**Rate limiting not working**:
- Check logs for limiter initialization
- Verify Redis is running (if using Redis backend)

For detailed testing, see [docs/TESTING.md](./docs/TESTING.md).

