# Troubleshooting Guide

## Overview

This guide helps diagnose and resolve common issues with the VioletVibes backend API.

## Common Issues

### Database Connection Errors

#### Error: "OperationalError: could not connect to server"

**Symptoms**:
- Application fails to start
- Health check shows database as "disconnected"
- Error logs show connection failures

**Causes**:
- Incorrect `DATABASE_URL`
- Database not accessible from app region
- Firewall blocking connections
- Database not running

**Solutions**:

1. **Verify DATABASE_URL**:
   ```bash
   echo $DATABASE_URL
   ```
   Should be: `postgresql://user:password@host:port/database?sslmode=require`

2. **Test Connection**:
   ```bash
   psql $DATABASE_URL -c "SELECT 1;"
   ```

3. **Check Firewall Rules**:
   - In DigitalOcean, ensure database allows connections from App Platform
   - Check database firewall settings

4. **Verify Database Status**:
   - Check DigitalOcean dashboard for database status
   - Ensure database is in same region as app

#### Error: "relation does not exist"

**Symptoms**:
- Tables not found errors
- Migration not run

**Solutions**:

1. **Initialize Database**:
   ```python
   from app import app, db
   with app.app_context():
       db.create_all()
   ```

2. **Run Migrations**:
   - See [MIGRATION.md](./MIGRATION.md) for migration steps

### Redis Connection Errors

#### Error: "Connection refused" or Redis unavailable

**Symptoms**:
- Warnings in logs about Redis
- App falls back to memory storage
- Rate limiting uses memory backend

**Causes**:
- `REDIS_URL` not set or incorrect
- Redis not accessible
- Redis service down

**Solutions**:

1. **Verify REDIS_URL**:
   ```bash
   echo $REDIS_URL
   ```
   Should be: `redis://user:password@host:port/database`

2. **Test Connection**:
   ```python
   import redis
   r = redis.from_url(REDIS_URL)
   r.ping()
   ```

3. **Check Redis Status**:
   - Verify Redis is running
   - Check firewall rules
   - Ensure Redis is accessible from app

**Note**: Redis is optional. App will work with in-memory storage, but:
- Conversation context not shared across workers
- Cache not persistent
- Rate limiting per-worker only

### Rate Limiting Issues

#### Error: "429 Too Many Requests"

**Symptoms**:
- API calls return 429 status
- Rate limit error messages

**Causes**:
- Too many requests from same IP
- Rate limits too restrictive
- Redis unavailable (memory limits per-worker)

**Solutions**:

1. **Check Rate Limits**:
   - Default: 200/day, 50/hour
   - Chat: 10/minute
   - Auth: 5/minute

2. **Wait for Reset**:
   - Rate limits reset after time period
   - Check rate limit headers in response

3. **Adjust Limits** (if needed):
   - Update limits in `app.py`
   - Redeploy application

#### Rate Limiting Not Working

**Symptoms**:
- No rate limiting applied
- Unlimited requests allowed

**Causes**:
- Flask-Limiter not initialized
- Redis unavailable and memory backend not working

**Solutions**:

1. **Check Logs**:
   - Look for rate limiter initialization messages
   - Verify limiter is created

2. **Test Rate Limiting**:
   ```bash
   # Make multiple rapid requests
   for i in {1..20}; do curl -X POST http://localhost:5001/api/auth/login -H "Content-Type: application/json" -d '{"email":"test","password":"test"}'; done
   ```

### CORS Errors

#### Error: "CORS policy: No 'Access-Control-Allow-Origin' header"

**Symptoms**:
- Browser blocks requests
- CORS errors in browser console
- Frontend cannot connect to backend

**Causes**:
- `ALLOWED_ORIGINS` not configured
- Frontend URL not in allowed origins
- CORS misconfiguration

**Solutions**:

1. **Check ALLOWED_ORIGINS**:
   ```bash
   echo $ALLOWED_ORIGINS
   ```
   Should include your frontend URL

2. **Update Configuration**:
   ```
   ALLOWED_ORIGINS=https://your-frontend.com,https://another-domain.com
   ```

3. **For Development**:
   - Localhost origins automatically allowed
   - Check `FLASK_ENV` is set to "development"

4. **Verify CORS Headers**:
   ```bash
   curl -H "Origin: https://your-frontend.com" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type" \
        -X OPTIONS \
        https://your-app.ondigitalocean.app/api/chat
   ```

### Authentication Errors

#### Error: "Invalid token" or "Token expired"

**Symptoms**:
- 401 Unauthorized responses
- Cannot access protected endpoints

**Causes**:
- Token expired (7 days)
- Invalid token format
- JWT_SECRET changed

**Solutions**:

1. **Check Token**:
   - Verify token is included in Authorization header
   - Format: `Authorization: Bearer <token>`

2. **Token Expired**:
   - Tokens expire after 7 days
   - User must log in again

3. **Invalid Token**:
   - Verify token wasn't modified
   - Check JWT_SECRET matches

#### Error: "JWT_SECRET must be set in production"

**Symptoms**:
- Application fails to start
- Configuration validation error

**Causes**:
- `JWT_SECRET` not set in production
- Using default secret in production

**Solutions**:

1. **Set JWT_SECRET**:
   ```bash
   # Generate strong secret
   openssl rand -hex 32
   
   # Set in environment
   export JWT_SECRET="your-generated-secret"
   ```

2. **Update in App Platform**:
   - Go to App Settings → Environment Variables
   - Add `JWT_SECRET` with strong random value

### API Endpoint Errors

#### Error: "Internal server error"

**Symptoms**:
- 500 status codes
- Generic error messages

**Causes**:
- Application errors
- External API failures
- Database errors

**Solutions**:

1. **Check Logs**:
   - Review application logs in App Platform
   - Look for error stack traces
   - Check request ID for tracking

2. **Check Health Endpoint**:
   ```bash
   curl https://your-app.ondigitalocean.app/health
   ```

3. **Verify External APIs**:
   - Check Google Gemini API key
   - Verify Google Places API key
   - Test external API connectivity

#### Error: "Missing 'message'" or validation errors

**Symptoms**:
- 400 Bad Request
- Missing required fields

**Causes**:
- Invalid request format
- Missing required parameters

**Solutions**:

1. **Check Request Format**:
   - Verify JSON format
   - Check required fields
   - See [API.md](./API.md) for endpoint requirements

2. **Test with cURL**:
   ```bash
   curl -X POST https://your-app.ondigitalocean.app/api/chat \
     -H "Content-Type: application/json" \
     -d '{"message":"test"}'
   ```

### Performance Issues

#### Slow Response Times

**Symptoms**:
- High latency
- Timeout errors
- Slow API responses

**Causes**:
- External API delays
- Database query performance
- Resource constraints

**Solutions**:

1. **Check External APIs**:
   - Google Places API response times
   - Gemini API latency
   - Network connectivity

2. **Database Performance**:
   - Check connection pool usage
   - Review slow queries
   - Consider database scaling

3. **Resource Limits**:
   - Check CPU/memory usage
   - Consider upgrading App Platform plan
   - Optimize worker count

#### High Memory Usage

**Symptoms**:
- Memory warnings
- App crashes
- OOM errors

**Causes**:
- Too many workers
- Memory leaks
- Large responses

**Solutions**:

1. **Reduce Workers**:
   - Update `app.yaml` worker count
   - Formula: `(2 × CPU cores) + 1`

2. **Check for Leaks**:
   - Review application logs
   - Monitor memory over time
   - Profile application

### Deployment Issues

#### Build Fails

**Symptoms**:
- Deployment fails
- Build errors in logs

**Causes**:
- Missing dependencies
- Python version mismatch
- Build command errors

**Solutions**:

1. **Check requirements.txt**:
   - Verify all dependencies listed
   - Check for version conflicts

2. **Verify Python Version**:
   - Check `runtime.txt` matches App Platform support
   - Use supported Python version

3. **Test Build Locally**:
   ```bash
   pip install -r requirements.txt
   ```

#### App Won't Start

**Symptoms**:
- Deployment succeeds but app doesn't start
- Health check fails
- No response from app

**Causes**:
- Missing environment variables
- Configuration errors
- Port binding issues

**Solutions**:

1. **Check Environment Variables**:
   - Verify all required variables set
   - Check for typos
   - Review configuration validation

2. **Check Logs**:
   - Review runtime logs
   - Look for startup errors
   - Check configuration validation messages

3. **Verify Port**:
   - App Platform sets `PORT` automatically
   - App should bind to `0.0.0.0:$PORT`

## Debugging Procedures

### Enable Debug Logging

Set `LOG_LEVEL=DEBUG` in environment variables:

```bash
export LOG_LEVEL=DEBUG
```

**Note**: Only use in development. Debug logs are verbose.

### Check Application Logs

**DigitalOcean App Platform**:
1. Navigate to App → Activity tab
2. View build and runtime logs
3. Filter by error level

**Local Development**:
```bash
# Logs go to stdout
python app.py
```

### Test Health Endpoint

```bash
curl https://your-app.ondigitalocean.app/health
```

Expected response:
```json
{
  "status": "ok",
  "database": "connected",
  "redis": "connected"
}
```

### Test API Endpoints

**Chat Endpoint**:
```bash
curl -X POST https://your-app.ondigitalocean.app/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"test"}'
```

**Health Check**:
```bash
curl https://your-app.ondigitalocean.app/health
```

### Verify Configuration

Run configuration validation:

```python
from utils.config import validate_config
validate_config()
```

## Error Message Reference

### Common Error Messages

| Error Message | Cause | Solution |
|--------------|-------|---------|
| "Missing required environment variables" | Required env vars not set | Set all required variables |
| "Database connection failed" | DATABASE_URL incorrect or DB unavailable | Verify DATABASE_URL and database status |
| "Rate limit exceeded" | Too many requests | Wait or adjust rate limits |
| "CORS policy" | Origin not allowed | Add origin to ALLOWED_ORIGINS |
| "Invalid token" | Token expired or invalid | Re-authenticate |
| "Internal server error" | Application error | Check logs for details |

## Getting Help

### Before Asking for Help

1. Check this troubleshooting guide
2. Review application logs
3. Test health endpoint
4. Verify configuration
5. Check [DEPLOYMENT.md](./DEPLOYMENT.md) for setup issues

### Information to Provide

When reporting issues, include:

1. **Error Message**: Exact error text
2. **Request ID**: From error response
3. **Endpoint**: Which API endpoint
4. **Request Details**: Method, headers, body
5. **Logs**: Relevant log entries
6. **Configuration**: Environment (dev/prod)
7. **Steps to Reproduce**: How to trigger the issue

### Support Resources

- [DigitalOcean App Platform Docs](https://docs.digitalocean.com/products/app-platform/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [API Reference](./API.md)
- [Configuration Guide](./CONFIGURATION.md)

## Prevention

### Best Practices

1. **Monitor Health Endpoint**: Regular health checks
2. **Review Logs**: Regular log review
3. **Test Changes**: Test in development first
4. **Backup Data**: Regular database backups
5. **Update Dependencies**: Keep dependencies updated
6. **Monitor Resources**: Watch CPU/memory usage

### Regular Maintenance

- **Weekly**: Review error logs
- **Monthly**: Check dependency updates
- **Quarterly**: Review and rotate secrets
- **As Needed**: Scale resources based on usage

