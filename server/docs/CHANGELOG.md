# Changelog

All notable changes to the VioletVibes backend API will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Redis-backed conversation context management for shared state across workers
- Redis-backed caching for HTTP requests
- Rate limiting with Flask-Limiter (Redis or memory backend)
- Comprehensive error handling with consistent error response format
- Request ID tracking for debugging
- Enhanced health check endpoint with database and Redis connectivity checks
- Structured JSON logging for production
- Retry logic with exponential backoff for external API calls
- Timeout handling for external API calls
- Environment variable validation on startup
- CORS configuration with environment-based origin restrictions
- Database connection pooling for PostgreSQL
- Production-ready Gunicorn configuration
- DigitalOcean App Platform deployment configuration (`app.yaml`)
- Python runtime specification (`runtime.txt`)
- Database migration script (SQLite to PostgreSQL)
- Comprehensive documentation (API, Architecture, Security, Deployment, etc.)

### Changed
- Database configuration: Support for PostgreSQL in production, SQLite for development
- Cache implementation: File-based SQLite cache → Redis or memory cache
- State management: Global memory → Redis-backed context manager
- Logging: Print statements → Structured logging with Python logging module
- Error handling: Basic error handling → Comprehensive error handlers with request tracking
- Health check: Simple status → Detailed component status checks
- JWT secret: Default fallback removed in production (must be set)
- CORS: Wildcard origins → Environment-based origin restrictions

### Security
- JWT secret validation (required in production)
- CORS restrictions for production
- Rate limiting on all endpoints
- Input validation on all requests
- Error messages don't expose internal details in production
- Secrets management via environment variables only

### Performance
- Database connection pooling (10 connections, 20 overflow)
- Gunicorn worker configuration (2 workers, 120s timeout)
- Request caching with Redis backend
- Retry logic prevents unnecessary failures
- Timeout handling prevents hanging requests

### Documentation
- API reference documentation
- Architecture documentation
- Security documentation
- Deployment guide
- Configuration reference
- Migration guide
- Troubleshooting guide

## [1.0.0] - 2025-01-XX

### Added
- Initial release
- Flask REST API with chat, recommendations, and events endpoints
- User authentication with JWT
- User preferences and settings management
- Google Places integration
- Google Gemini AI chat integration
- NYU Engage events integration
- Walking directions integration
- SQLite database for development

### Known Issues
- Global conversation context not shared across workers
- File-based cache not suitable for production
- No rate limiting
- Basic error handling
- Print statements instead of logging

---

## Version History

### Version Format

We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Release Types

- **Major Release**: Breaking API changes, requires frontend updates
- **Minor Release**: New features, backward compatible
- **Patch Release**: Bug fixes and improvements

## Migration Notes

### From SQLite to PostgreSQL

See [MIGRATION.md](./MIGRATION.md) for detailed migration instructions.

**Breaking Changes**: None (schema compatible)

**Action Required**: Run migration script before switching to PostgreSQL

### From Development to Production

**Breaking Changes**:
- `JWT_SECRET` must be set (no default)
- `ALLOWED_ORIGINS` must be set for CORS
- `DATABASE_URL` must be set (PostgreSQL)

**Action Required**:
1. Set all required environment variables
2. Configure CORS origins
3. Set up PostgreSQL database
4. Deploy to DigitalOcean App Platform

## Future Plans

### Planned Features

- API versioning (`/api/v1/`, `/api/v2/`)
- WebSocket support for real-time chat
- GraphQL endpoint (alternative to REST)
- Advanced caching strategies
- Background job processing
- Enhanced monitoring and metrics

### Under Consideration

- Microservices architecture
- CDN integration
- Message queue for async tasks
- Advanced rate limiting strategies
- API key authentication for third-party access

---

For detailed information about changes, see individual commit messages and pull requests.

