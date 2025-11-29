# System Architecture

## Overview

VioletVibes backend is a Flask-based REST API server designed to provide location-based recommendations, chat functionality, and event discovery for NYU students. The system is deployed on DigitalOcean App Platform with PostgreSQL and Redis for data persistence and state management.

## Technology Stack

### Core Framework
- **Flask 3.0.0**: Python web framework
- **Python 3.11**: Runtime environment
- **Gunicorn**: Production WSGI server

### Database
- **PostgreSQL**: Primary database (production)
- **SQLite**: Development database (local)
- **SQLAlchemy**: ORM for database operations

### State Management & Caching
- **Redis**: Shared state and caching (production)
- **Memory**: Fallback for development

### Authentication & Security
- **JWT (PyJWT)**: Token-based authentication
- **Flask-Bcrypt**: Password hashing
- **Flask-Limiter**: Rate limiting
- **Flask-CORS**: Cross-origin resource sharing

### External Services
- **Google Gemini API**: AI chat responses
- **Google Places API**: Location and place data
- **Google Directions API**: Walking directions
- **OpenWeather API**: Weather data

### Utilities
- **Tenacity**: Retry logic with exponential backoff
- **Requests-Cache**: HTTP response caching
- **Python-dotenv**: Environment variable management

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Applications                        │
│  ┌──────────────┐              ┌──────────────┐              │
│  │  iOS App     │              │ React Native │              │
│  │  (SwiftUI)   │              │  (Expo)      │              │
│  └──────┬───────┘              └──────┬───────┘              │
└─────────┼──────────────────────────────┼─────────────────────┘
          │                              │
          │ HTTPS                        │ HTTPS
          │                              │
┌─────────▼──────────────────────────────▼─────────────────────┐
│              DigitalOcean App Platform                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Flask Application (Gunicorn)             │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │   │
│  │  │   Routes     │  │   Services   │  │   Utils    │ │   │
│  │  │  - Auth      │  │  - Places    │  │  - Config  │ │   │
│  │  │  - User      │  │  - Events    │  │  - Cache   │ │   │
│  │  │  - Chat      │  │  - Directions│  │  - Auth    │ │   │
│  │  │  - Quick     │  │  - LLM       │  │  - Retry   │ │   │
│  │  └──────────────┘  └──────────────┘  └────────────┘ │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────┬──────────────────────────┬─────────────────────────┘
          │                          │
          │                          │
┌─────────▼──────────┐    ┌──────────▼──────────┐
│   PostgreSQL       │    │      Redis          │
│   (Managed DB)     │    │  (State & Cache)    │
└────────────────────┘    └─────────────────────┘
          │                          │
          │                          │
┌─────────▼──────────────────────────▼──────────┐
│         External APIs                          │
│  - Google Gemini API                          │
│  - Google Places API                          │
│  - Google Directions API                      │
│  - OpenWeather API                            │
└───────────────────────────────────────────────┘
```

## Component Architecture

### Request Flow

1. **Client Request** → HTTPS → DigitalOcean App Platform
2. **Gunicorn Workers** → Receive request, route to Flask app
3. **Flask Application**:
   - Request ID generation
   - Rate limiting check
   - Authentication (if required)
   - Route handler execution
   - Service layer processing
   - Response generation
4. **Response** → Client

### State Management

**Conversation Context:**
- Stored in Redis (key: `conversation:user:{user_id}` or `conversation:session:{session_id}`)
- Falls back to in-memory storage if Redis unavailable
- 24-hour expiration

**Caching:**
- HTTP responses cached in Redis
- 5-minute expiration for GET requests
- Falls back to memory cache if Redis unavailable

**Rate Limiting:**
- Stored in Redis (distributed across workers)
- Falls back to memory (per-worker) if Redis unavailable

### Database Architecture

**PostgreSQL Schema:**
- `users` table: User accounts and preferences
- JSON columns for flexible data storage
- Connection pooling for performance

**Migration Strategy:**
- SQLite → PostgreSQL migration script
- Schema compatibility maintained
- Data export/import process

## Design Decisions

### Why Redis for State Management?

**Problem**: Global `ConversationContext` object not shared across Gunicorn workers.

**Solution**: Redis-backed context manager provides:
- Shared state across all workers
- Persistence across restarts
- Scalability for multiple instances

**Alternative Considered**: Database-backed storage (simpler but slower)

### Why PostgreSQL over SQLite?

**Production Requirements**:
- Concurrent connections
- Data persistence
- Scalability
- DigitalOcean managed database support

**Development**: SQLite remains for local development simplicity.

### Why Gunicorn?

**Production WSGI Server**:
- Multiple worker processes
- Better performance than Flask dev server
- Industry standard for Flask deployments

**Configuration**: 2 workers, 120s timeout, shared memory temp dir

### Why Rate Limiting?

**Security & Performance**:
- Prevents abuse and DoS attacks
- Protects external API quotas
- Ensures fair resource usage

**Implementation**: Flask-Limiter with Redis backend for distributed rate limiting.

### Why Retry Logic?

**Resilience**:
- External APIs can be unreliable
- Network issues are transient
- Exponential backoff prevents overwhelming services

**Implementation**: Tenacity library with configurable retry strategies.

## Scalability Considerations

### Horizontal Scaling

- **Stateless Application**: Each worker is independent
- **Shared State**: Redis provides shared state across instances
- **Database Pooling**: Connection pooling handles concurrent requests
- **Load Balancing**: DigitalOcean App Platform handles load distribution

### Performance Optimizations

- **Connection Pooling**: Database connections reused
- **Caching**: HTTP responses cached to reduce external API calls
- **Async Operations**: Non-blocking external API calls where possible
- **Worker Configuration**: Optimized worker count based on resources

### Resource Limits

- **Memory**: Configured per App Platform plan
- **CPU**: Shared or dedicated based on plan
- **Database**: Managed PostgreSQL with automatic backups
- **Redis**: Optional but recommended for production

## Security Architecture

### Authentication Flow

1. User signs up/logs in
2. Server validates credentials
3. JWT token generated (7-day expiration)
4. Token sent to client
5. Client includes token in Authorization header
6. Server validates token on each request

### Security Measures

- **Password Hashing**: bcrypt with salt
- **JWT Tokens**: Signed with secret key
- **CORS**: Restricted to specific origins
- **Rate Limiting**: Prevents abuse
- **Input Validation**: All inputs validated
- **Error Handling**: No internal errors exposed in production

### Secrets Management

- **Environment Variables**: All secrets in environment
- **No Hardcoded Secrets**: Production requires all secrets set
- **Validation**: Startup validation ensures required secrets present

## Monitoring & Observability

### Logging

- **Structured Logging**: JSON format in production
- **Request Tracking**: Request ID for tracing
- **Log Levels**: DEBUG (dev), INFO (production)
- **Output**: stdout (captured by App Platform)

### Health Checks

- **Endpoint**: `/health`
- **Checks**: Database connectivity, Redis connectivity
- **Response**: Detailed status for each component

### Metrics

- **App Platform Metrics**: CPU, memory, request count
- **Database Metrics**: Connection pool usage
- **Custom Metrics**: Can be added via logging

## Deployment Architecture

### DigitalOcean App Platform

- **Managed Service**: No server management required
- **Auto-scaling**: Automatic scaling based on load
- **SSL/TLS**: Automatic certificate management
- **Git Integration**: Automatic deployments on push

### Environment Management

- **Development**: Local with SQLite
- **Production**: DigitalOcean with PostgreSQL and Redis
- **Configuration**: Environment variables for all settings

## Future Considerations

### Potential Improvements

- **API Versioning**: For backward compatibility
- **GraphQL**: Alternative to REST for flexible queries
- **WebSockets**: Real-time chat functionality
- **Microservices**: Split into smaller services if needed
- **CDN**: For static assets
- **Message Queue**: For async task processing

### Scalability Path

1. **Current**: Single app instance, managed database
2. **Next**: Multiple app instances, Redis cluster
3. **Future**: Microservices, dedicated infrastructure

## Dependencies

See `requirements.txt` for complete dependency list.

Key dependencies:
- Flask ecosystem (Flask, Flask-SQLAlchemy, Flask-Bcrypt, Flask-CORS, Flask-Limiter)
- Database (SQLAlchemy, psycopg2-binary)
- External APIs (google-generativeai, google-api-python-client)
- Utilities (redis, tenacity, requests-cache)

