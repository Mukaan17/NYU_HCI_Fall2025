# Testing Guide

## Overview

This guide covers how to test the VioletVibes backend API locally and verify all functionality before deployment.

## Quick Start Testing

### 1. Start the Server Locally

```bash
cd server

# Activate virtual environment (if using one)
source venv/bin/activate  # or: venv\Scripts\activate on Windows

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
export JWT_SECRET="test-secret-key"
export GEMINI_API_KEY="your-gemini-key"
export FLASK_ENV="development"
export LOG_LEVEL="DEBUG"

# Start server
python app.py
```

Server should start on `http://localhost:5001`

### 2. Test Health Endpoint

```bash
curl http://localhost:5001/health
```

**Expected Response**:
```json
{
  "status": "ok",
  "database": "connected",
  "redis": "not_configured"
}
```

## Testing Checklist

### Basic Functionality Tests

#### ✅ Health Check
```bash
curl http://localhost:5001/health
```
- Should return 200 OK
- Database should show "connected"
- Redis shows "not_configured" (if not set) or "connected"

#### ✅ Authentication - Sign Up
```bash
curl -X POST http://localhost:5001/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123"
  }'
```
- Should return 201 Created
- Should include JWT token
- Should include user data

#### ✅ Authentication - Login
```bash
curl -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123"
  }'
```
- Should return 200 OK
- Should include JWT token

#### ✅ Chat Endpoint (No Auth)
```bash
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I want coffee"
  }'
```
- Should return 200 OK
- Should include AI reply
- Should include places array

#### ✅ Chat Endpoint (With Auth)
```bash
# First, get token from login
TOKEN=$(curl -s -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpassword123"}' \
  | jq -r '.token')

# Then use token
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "message": "I want coffee",
    "latitude": 40.693393,
    "longitude": -73.98555
  }'
```

#### ✅ Quick Recommendations
```bash
curl "http://localhost:5001/api/quick_recs?category=chill_cafes&limit=5"
```
- Should return 200 OK
- Should include places array

#### ✅ Directions
```bash
curl "http://localhost:5001/api/directions?lat=40.6942&lng=-73.9866"
```
- Should return 200 OK
- Should include duration, distance, maps_link

#### ✅ Events
```bash
curl "http://localhost:5001/api/nyu_engage_events?days=7"
```
- Should return 200 OK
- Should include engage_events array

### Security Tests

#### ✅ Rate Limiting - Auth Endpoints
```bash
# Make 6 rapid requests (limit is 5 per minute)
for i in {1..6}; do
  curl -X POST http://localhost:5001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"wrong"}' \
    -w "\nStatus: %{http_code}\n"
  sleep 1
done
```
- First 5 should return 401 (wrong password)
- 6th should return 429 (rate limited)

#### ✅ CORS Configuration
```bash
# Test CORS preflight
curl -X OPTIONS http://localhost:5001/api/chat \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -v
```
- Should include CORS headers
- Should allow localhost origins in development

#### ✅ JWT Token Validation
```bash
# Test with invalid token
curl -X GET http://localhost:5001/api/user/me \
  -H "Authorization: Bearer invalid-token"
```
- Should return 401 Unauthorized

#### ✅ Missing Required Fields
```bash
# Test signup without email
curl -X POST http://localhost:5001/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"password":"test123"}'
```
- Should return 400 Bad Request
- Should include error message

### Error Handling Tests

#### ✅ Invalid Endpoint
```bash
curl http://localhost:5001/api/nonexistent
```
- Should return 404 Not Found
- Should include error message

#### ✅ Invalid JSON
```bash
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -d 'invalid json'
```
- Should handle gracefully
- Should return appropriate error

#### ✅ Database Error Simulation
- Stop database (if using external)
- Make request
- Should return appropriate error
- Should not expose internal details

### Performance Tests

#### ✅ Response Time
```bash
time curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"test"}'
```
- Should respond within reasonable time (< 5 seconds)

#### ✅ Concurrent Requests
```bash
# Make 10 concurrent requests
for i in {1..10}; do
  curl -X POST http://localhost:5001/api/chat \
    -H "Content-Type: application/json" \
    -d '{"message":"test"}' &
done
wait
```
- All should complete successfully
- No connection errors

## Testing with Different Configurations

### Test with Redis

```bash
# Start Redis locally
redis-server

# Set REDIS_URL
export REDIS_URL="redis://localhost:6379/0"

# Restart server
python app.py

# Test - conversation context should persist
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: test-session-123" \
  -d '{"message":"first message"}'

curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: test-session-123" \
  -d '{"message":"second message"}'
# Context should be maintained
```

### Test with PostgreSQL

```bash
# Set DATABASE_URL
export DATABASE_URL="postgresql://user:password@localhost:5432/violetvibes"

# Run migration (if needed)
python migrate_to_postgresql.py

# Restart server
python app.py

# Test - should work with PostgreSQL
curl http://localhost:5001/health
```

### Test Production Configuration

```bash
# Set production environment
export FLASK_ENV="production"
export JWT_SECRET="strong-production-secret"
export ALLOWED_ORIGINS="https://your-frontend.com"
export DATABASE_URL="postgresql://..."
export LOG_LEVEL="INFO"

# Start with Gunicorn
gunicorn --workers 2 --timeout 120 --bind 0.0.0.0:5001 app:app

# Test - should work in production mode
curl http://localhost:5001/health
```

## Automated Testing Script

Create `server/test_api.sh`:

```bash
#!/bin/bash

BASE_URL="${1:-http://localhost:5001}"
echo "Testing API at $BASE_URL"

# Health check
echo -e "\n1. Testing health endpoint..."
curl -s "$BASE_URL/health" | jq '.'
if [ $? -eq 0 ]; then
  echo "✓ Health check passed"
else
  echo "✗ Health check failed"
  exit 1
fi

# Sign up
echo -e "\n2. Testing signup..."
SIGNUP_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{"email":"test'$(date +%s)'@example.com","password":"test123"}')
echo "$SIGNUP_RESPONSE" | jq '.'
TOKEN=$(echo "$SIGNUP_RESPONSE" | jq -r '.token // empty')

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
  echo "✓ Signup passed, token received"
else
  echo "✗ Signup failed"
  exit 1
fi

# Login
echo -e "\n3. Testing login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}')
echo "$LOGIN_RESPONSE" | jq '.'

# Chat
echo -e "\n4. Testing chat endpoint..."
CHAT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message":"I want coffee"}')
echo "$CHAT_RESPONSE" | jq '.reply // .error'

# Quick recs
echo -e "\n5. Testing quick recommendations..."
curl -s "$BASE_URL/api/quick_recs?category=chill_cafes" | jq '.places | length'

echo -e "\n✓ All tests completed!"
```

Make it executable:
```bash
chmod +x server/test_api.sh
```

Run tests:
```bash
./server/test_api.sh http://localhost:5001
```

## Testing Specific Features

### Test Conversation Context

```bash
# First message
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: test-123" \
  -d '{"message":"I like coffee"}'

# Second message (should remember context if Redis is configured)
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: test-123" \
  -d '{"message":"What about tea?"}'
```

### Test Rate Limiting

```bash
# Test chat rate limit (10 per minute)
for i in {1..12}; do
  echo "Request $i:"
  curl -s -X POST http://localhost:5001/api/chat \
    -H "Content-Type: application/json" \
    -d '{"message":"test"}' \
    -w " Status: %{http_code}\n" | tail -1
  sleep 1
done
```

### Test Error Handling

```bash
# Test 404
curl http://localhost:5001/api/nonexistent

# Test 400 (missing field)
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -d '{}'

# Test 401 (invalid token)
curl -X GET http://localhost:5001/api/user/me \
  -H "Authorization: Bearer invalid"
```

## Testing Deployment Configuration

### Test app.yaml Configuration

```bash
# Validate YAML syntax
python -c "import yaml; yaml.safe_load(open('app.yaml'))"
```

### Test Runtime Configuration

```bash
# Check Python version matches runtime.txt
python --version
cat runtime.txt
```

### Test Environment Variables

```bash
# Test config validation
python -c "from utils.config import validate_config; validate_config()"
```

## Integration Testing

### Test Full User Flow

```bash
# 1. Sign up
SIGNUP=$(curl -s -X POST http://localhost:5001/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"password123"}')
TOKEN=$(echo $SIGNUP | jq -r '.token')

# 2. Get user profile
curl -X GET http://localhost:5001/api/user/me \
  -H "Authorization: Bearer $TOKEN"

# 3. Update preferences
curl -X POST http://localhost:5001/api/user/preferences \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"distance_limit_minutes": 30}'

# 4. Send chat message
curl -X POST http://localhost:5001/api/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message":"I want coffee"}'

# 5. Log activity
curl -X POST http://localhost:5001/api/user/activity \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"clicked_recommendation","name":"Test Place"}'
```

## Load Testing

### Basic Load Test

```bash
# Install Apache Bench (if available)
# macOS: brew install httpd
# Ubuntu: sudo apt-get install apache2-utils

# Test health endpoint
ab -n 100 -c 10 http://localhost:5001/health

# Test chat endpoint (POST)
ab -n 50 -c 5 -p chat_payload.json -T application/json \
   http://localhost:5001/api/chat
```

Create `chat_payload.json`:
```json
{"message":"test"}
```

## Testing Checklist

Before deploying to production:

- [ ] Health endpoint returns OK
- [ ] All API endpoints respond correctly
- [ ] Authentication works (signup, login)
- [ ] Rate limiting works
- [ ] CORS configured correctly
- [ ] Error handling works
- [ ] Logging works (check logs)
- [ ] Database connectivity works
- [ ] Redis connectivity works (if configured)
- [ ] Environment variables validated
- [ ] Gunicorn starts successfully
- [ ] Migration script works (if migrating)
- [ ] All documentation reviewed

## Troubleshooting Tests

### Server Won't Start

1. Check Python version: `python --version` (should be 3.11+)
2. Check dependencies: `pip install -r requirements.txt`
3. Check environment variables: `env | grep -E "JWT_SECRET|GEMINI|DATABASE"`
4. Check logs for errors

### Tests Failing

1. Check server is running: `curl http://localhost:5001/health`
2. Check logs for errors
3. Verify environment variables
4. Test individual endpoints manually

### Database Issues

1. Check database is running
2. Verify DATABASE_URL format
3. Test connection: `psql $DATABASE_URL -c "SELECT 1;"`
4. Check database logs

## Next Steps

After local testing passes:

1. Test on staging environment (if available)
2. Deploy to DigitalOcean App Platform
3. Test production endpoints
4. Monitor logs and metrics
5. Perform smoke tests

For deployment, see [DEPLOYMENT.md](./DEPLOYMENT.md).

