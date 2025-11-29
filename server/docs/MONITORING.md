# Monitoring & Observability Guide

## Overview

This guide covers monitoring, logging, and observability for the VioletVibes backend API.

## Logging

### Log Levels

- **DEBUG**: Detailed information for debugging (development only)
- **INFO**: General informational messages
- **WARNING**: Warning messages (non-critical issues)
- **ERROR**: Error messages (requires attention)

### Log Format

**Development** (Human-readable):
```
2025-01-15 10:30:45 - app - INFO - Request abc123: GET /api/chat
```

**Production** (JSON):
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

**View Logs**:
- **App Platform**: App → Activity → Runtime Logs
- **Local**: Console output when running `python app.py`

### Request Tracking

Every request gets a unique `request_id` (8-character UUID) for tracking:

```python
# Request ID available in:
g.request_id  # In route handlers
logger.info(f"Request {g.request_id}: ...")
```

**Use Cases**:
- Trace requests across services
- Debug specific user issues
- Correlate errors with requests

### Structured Logging

Logs include context:

```python
logger.info("User logged in", extra={
    "user_id": user.id,
    "email": user.email,
    "request_id": g.request_id
})
```

## Metrics

### Application Metrics

**DigitalOcean App Platform Provides**:
- CPU usage
- Memory usage
- Request count
- Response times
- Error rates

**Access Metrics**:
1. Navigate to App Platform dashboard
2. Go to Metrics tab
3. View real-time and historical metrics

### Custom Metrics

Can be added via logging:

```python
logger.info("api_request", extra={
    "endpoint": "/api/chat",
    "duration_ms": 234,
    "status_code": 200
})
```

### Key Performance Indicators (KPIs)

**Monitor**:
- Request rate (requests/second)
- Response time (p50, p95, p99)
- Error rate (errors/requests)
- Database connection pool usage
- External API response times

## Health Checks

### Health Endpoint

**Endpoint**: `GET /health`

**Response**:
```json
{
  "status": "ok",
  "database": "connected",
  "redis": "connected"
}
```

**Status Values**:
- `ok`: Application running
- `connected`: Component operational
- `disconnected`: Component failed
- `not_configured`: Component not set up

### Health Check Configuration

**DigitalOcean App Platform**:
- Path: `/health`
- Initial Delay: 10 seconds
- Period: 10 seconds
- Timeout: 5 seconds
- Success Threshold: 1
- Failure Threshold: 3

### Monitoring Health

**Automated**:
- App Platform monitors health endpoint
- Alerts on health check failures

**Manual**:
```bash
curl https://your-app.ondigitalocean.app/health
```

## Error Tracking

### Error Logging

All errors are logged with:
- Error message
- Stack trace
- Request ID
- User ID (if available)
- Endpoint

**Example**:
```json
{
  "timestamp": "2025-01-15 10:30:45",
  "level": "ERROR",
  "logger": "app",
  "message": "Chat error - Connection timeout",
  "request_id": "abc123",
  "endpoint": "/api/chat",
  "exception": "Traceback (most recent call last)..."
}
```

### Error Response Format

**Production**:
```json
{
  "error": "Internal server error",
  "request_id": "abc123"
}
```

**Development**:
```json
{
  "error": "Internal server error",
  "message": "Connection timeout",
  "request_id": "abc123"
}
```

## Alerts

### Recommended Alerts

**High Error Rate**:
- Threshold: > 5% error rate
- Action: Investigate errors in logs

**Health Check Failures**:
- Threshold: 3 consecutive failures
- Action: Check database/Redis connectivity

**High Response Time**:
- Threshold: p95 > 2 seconds
- Action: Investigate performance issues

**Database Connection Pool Exhausted**:
- Threshold: Pool usage > 80%
- Action: Increase pool size or optimize queries

### Setting Up Alerts

**DigitalOcean App Platform**:
1. Navigate to App → Alerts
2. Create alert rules
3. Configure thresholds
4. Set notification channels

## Dashboards

### App Platform Dashboard

**Available Metrics**:
- CPU usage over time
- Memory usage over time
- Request count
- Error rate
- Response times

**Access**:
- App Platform → App → Metrics tab

### Custom Dashboards

Can be created using:
- DigitalOcean monitoring APIs
- Third-party tools (Grafana, Datadog, etc.)
- Log aggregation services

## Performance Monitoring

### Response Times

**Monitor**:
- Average response time
- p50, p95, p99 percentiles
- Slowest endpoints

**Optimization**:
- Identify slow endpoints
- Optimize database queries
- Add caching
- Optimize external API calls

### Resource Usage

**CPU**:
- Monitor CPU usage
- Scale if consistently high
- Optimize CPU-intensive operations

**Memory**:
- Monitor memory usage
- Check for memory leaks
- Optimize data structures

**Database**:
- Monitor connection pool usage
- Check query performance
- Review slow queries

## Log Analysis

### Searching Logs

**App Platform**:
- Filter by time range
- Search by keyword
- Filter by log level

**Common Searches**:
- `ERROR` - All errors
- `request_id:abc123` - Specific request
- `endpoint:/api/chat` - Specific endpoint
- `user_id:123` - Specific user

### Log Retention

**App Platform**:
- Logs retained for limited time
- Download logs for long-term storage
- Export to external service if needed

## External Service Monitoring

### Google APIs

**Monitor**:
- API response times
- Error rates
- Quota usage

**Alerts**:
- High error rate from Google APIs
- Quota approaching limits

### Database Monitoring

**Monitor**:
- Connection count
- Query performance
- Replication lag (if applicable)

**DigitalOcean Managed Database**:
- Metrics available in dashboard
- Connection pool metrics
- Query performance insights

### Redis Monitoring

**Monitor**:
- Connection count
- Memory usage
- Command latency
- Hit/miss rates

**Alerts**:
- High memory usage
- Connection failures
- High latency

## Best Practices

### Logging Best Practices

1. **Use Appropriate Levels**:
   - DEBUG: Development only
   - INFO: Important events
   - WARNING: Non-critical issues
   - ERROR: Errors requiring attention

2. **Include Context**:
   - Request ID
   - User ID (when available)
   - Endpoint
   - Relevant parameters

3. **Don't Log Sensitive Data**:
   - No passwords
   - No tokens (except for debugging)
   - No personal information

4. **Structured Logging**:
   - Use JSON format in production
   - Include relevant fields
   - Make logs searchable

### Monitoring Best Practices

1. **Set Up Alerts Early**:
   - Configure alerts before issues occur
   - Test alert notifications
   - Review alert thresholds regularly

2. **Monitor Key Metrics**:
   - Error rates
   - Response times
   - Resource usage
   - External service health

3. **Regular Reviews**:
   - Weekly log review
   - Monthly performance review
   - Quarterly capacity planning

4. **Document Issues**:
   - Document common issues
   - Update troubleshooting guides
   - Share knowledge with team

## Tools & Integrations

### Available Tools

**DigitalOcean App Platform**:
- Built-in metrics
- Log aggregation
- Health monitoring

**Third-Party Options**:
- Datadog
- New Relic
- Sentry (error tracking)
- Grafana (dashboards)

### Integration Examples

**Error Tracking (Sentry)**:
```python
import sentry_sdk
sentry_sdk.init(dsn="your-sentry-dsn")
```

**Metrics (Datadog)**:
```python
from datadog import statsd
statsd.increment('api.requests', tags=['endpoint:/api/chat'])
```

## Troubleshooting Monitoring Issues

### Logs Not Appearing

**Check**:
- Log level configuration
- Output destination
- App Platform log settings

### Metrics Not Updating

**Check**:
- App Platform metrics collection
- Time range selection
- Metric availability

### Alerts Not Firing

**Check**:
- Alert configuration
- Threshold settings
- Notification channels
- Alert status

For more troubleshooting, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

