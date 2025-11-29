# Security Documentation

## Overview

This document outlines security practices, policies, and compliance considerations for the VioletVibes backend API.

## Security Architecture

### Authentication & Authorization

#### JWT Token Authentication

- **Algorithm**: HS256 (HMAC with SHA-256)
- **Expiration**: 7 days
- **Secret Key**: Stored in `JWT_SECRET` environment variable
- **Validation**: Token validated on every authenticated request

**Security Measures**:
- Secret key must be strong (minimum 32 characters recommended)
- Secret key never committed to version control
- Tokens expire after 7 days (configurable)
- Invalid/expired tokens rejected immediately

#### Password Security

- **Hashing**: bcrypt with automatic salt generation
- **Rounds**: Default bcrypt rounds (10)
- **Storage**: Only hashed passwords stored, never plaintext

**Best Practices**:
- Passwords never logged or exposed
- Password validation on client and server
- No password recovery mechanism (intentional for MVP)

### API Security

#### CORS (Cross-Origin Resource Sharing)

**Production Configuration**:
- Restricted to specific domains via `ALLOWED_ORIGINS`
- Never uses wildcard (`*`) in production
- Validates origin on every request

**Development Configuration**:
- Allows localhost origins for development
- Automatically configured based on `FLASK_ENV`

**Implementation**:
```python
# Production: Specific origins only
ALLOWED_ORIGINS=https://your-frontend.com,https://another-domain.com

# Development: Localhost allowed
# Automatically configured
```

#### Rate Limiting

**Purpose**: Prevent abuse, DoS attacks, and protect external API quotas.

**Configuration**:
- Default: 200 requests/day, 50 requests/hour per IP
- Chat: 10 requests/minute
- Auth: 5 requests/minute
- Quick Recommendations: 30 requests/minute

**Storage**: Redis (distributed) or memory (fallback)

**Response**: `429 Too Many Requests` with error message

#### Input Validation

**All Inputs Validated**:
- Request parameters
- Request body fields
- Query parameters
- Headers (where applicable)

**Validation Rules**:
- Email format validation
- Required field checks
- Type validation
- Length limits (where applicable)

**Error Handling**:
- Clear error messages for validation failures
- No internal details exposed
- Consistent error response format

### Data Protection

#### Encryption at Rest

- **Database**: PostgreSQL with SSL/TLS connections
- **Connection String**: Includes `sslmode=require`
- **Managed Database**: DigitalOcean provides encryption at rest

#### Encryption in Transit

- **HTTPS**: All production traffic over HTTPS
- **TLS**: DigitalOcean App Platform provides automatic TLS certificates
- **Database**: SSL/TLS connections required
- **Redis**: TLS connections recommended (if available)

#### Sensitive Data Handling

**Never Logged**:
- Passwords (plaintext or hashed)
- JWT tokens (except for debugging in development)
- API keys
- Personal information (unless necessary for debugging)

**Stored Securely**:
- User preferences: Encrypted in database
- Settings: Encrypted in database
- Activity logs: Stored with minimal PII

### Secrets Management

#### Environment Variables

**Required Secrets** (must be set in production):
- `JWT_SECRET`: JWT signing secret
- `GEMINI_API_KEY`: Google Gemini API key
- `DATABASE_URL`: PostgreSQL connection string

**Optional Secrets**:
- `REDIS_URL`: Redis connection string
- `OPENWEATHER_KEY`: OpenWeather API key
- `ALLOWED_ORIGINS`: CORS allowed origins

**Security Practices**:
- All secrets in environment variables
- Never hardcoded in source code
- Validated on application startup
- Production fails fast if secrets missing

#### Secret Rotation

**JWT_SECRET**:
- Rotate periodically (recommended: every 90 days)
- Rotation invalidates all existing tokens
- Users must re-authenticate after rotation

**API Keys**:
- Rotate if compromised
- Update in environment variables
- No application restart needed for most keys

### Vulnerability Management

#### Dependency Scanning

**Regular Updates**:
- Dependencies pinned to specific versions
- Regular security updates recommended
- Monitor for security advisories

**Tools**:
- `pip list --outdated` to check for updates
- GitHub Dependabot (if enabled)
- Security advisories from package maintainers

#### Security Updates

**Process**:
1. Monitor security advisories
2. Test updates in development
3. Deploy updates to production
4. Monitor for issues

**Critical Updates**:
- Deploy immediately after testing
- Security patches take priority
- Document changes in CHANGELOG.md

### Error Handling & Information Disclosure

#### Production Error Responses

**Never Exposed**:
- Stack traces
- Internal file paths
- Database schema details
- Internal error messages

**Exposed**:
- Generic error messages
- Request ID for tracking
- HTTP status codes

**Example**:
```json
{
  "error": "Internal server error",
  "request_id": "abc123"
}
```

#### Development vs Production

**Development**:
- Detailed error messages
- Stack traces in responses
- Debug information

**Production**:
- Generic error messages only
- Errors logged server-side
- Request ID for support tracking

### API Security Best Practices

#### Request Validation

- Validate all inputs
- Sanitize user input
- Check data types
- Enforce length limits

#### SQL Injection Prevention

- **ORM**: SQLAlchemy prevents SQL injection
- **Parameterized Queries**: All queries use parameters
- **No Raw SQL**: Avoid raw SQL when possible

#### XSS Prevention

- JSON responses only (no HTML)
- Content-Type headers set correctly
- No user input in responses without sanitization

### Compliance Considerations

#### Data Privacy

- **Minimal Data Collection**: Only necessary data collected
- **User Control**: Users can update/delete preferences
- **Activity Logs**: Limited retention (last 100 actions)

#### GDPR Considerations (if applicable)

- User data export capability (future)
- Data deletion requests (future)
- Privacy policy compliance (frontend responsibility)

### Security Monitoring

#### Logging

**Security Events Logged**:
- Failed authentication attempts
- Rate limit violations
- Invalid token attempts
- Unusual request patterns

**Log Format**:
- Structured JSON logging
- Request ID tracking
- Timestamp for all events

#### Alerting

**Recommended Alerts**:
- High error rate
- Multiple failed authentication attempts
- Rate limit violations
- Database connection failures

### Incident Response

#### Security Incident Procedure

1. **Identify**: Detect security issue
2. **Contain**: Limit impact (rate limiting, IP blocking)
3. **Investigate**: Review logs and identify cause
4. **Remediate**: Fix vulnerability
5. **Document**: Record incident and resolution
6. **Notify**: Inform affected users if necessary

#### Common Security Issues

**Rate Limit Exceeded**:
- Normal: User making too many requests
- Attack: Potential DoS attempt
- Response: Automatic rate limiting, monitor patterns

**Invalid Authentication**:
- Normal: User with wrong password
- Attack: Brute force attempt
- Response: Rate limiting, log attempts

**Database Connection Failure**:
- Normal: Temporary network issue
- Attack: Potential DDoS
- Response: Health check fails, automatic retry

### Security Checklist

#### Pre-Deployment

- [ ] All secrets set in environment variables
- [ ] CORS configured for production domains
- [ ] Rate limiting enabled
- [ ] Error handling configured for production
- [ ] Database SSL/TLS enabled
- [ ] HTTPS enforced
- [ ] Health checks configured

#### Ongoing

- [ ] Monitor security logs regularly
- [ ] Review failed authentication attempts
- [ ] Check for dependency updates
- [ ] Rotate secrets periodically
- [ ] Review access logs for anomalies
- [ ] Test security measures regularly

### Security Best Practices for Developers

#### Code Security

- Never commit secrets to version control
- Validate all user input
- Use parameterized queries
- Sanitize output
- Follow principle of least privilege

#### Secret Management

- Use environment variables
- Never log secrets
- Rotate secrets regularly
- Use strong, random secrets

#### Error Handling

- Don't expose internal details
- Log errors server-side
- Provide generic error messages
- Include request ID for tracking

## Contact

For security concerns or vulnerabilities:
1. Review logs and error messages
2. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
3. Contact development team

**Note**: This is a development/educational project. For production use, additional security measures may be required.

