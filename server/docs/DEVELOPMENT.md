# Development Guide

## Local Setup

### Prerequisites

- Python 3.11+
- pip
- SQLite (for local database)
- Redis (optional, for local state management)

### Installation

1. **Clone Repository**:
   ```bash
   git clone <repository-url>
   cd server
   ```

2. **Create Virtual Environment**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Set Up Environment Variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your API keys and configuration
   ```

5. **Initialize Database**:
   ```bash
   export INIT_DB=true
   python app.py
   ```

### Running the Application

**Development Server**:
```bash
python app.py
```

Server runs on `http://localhost:5001`

**With Gunicorn** (production-like):
```bash
gunicorn --workers 2 --timeout 120 --bind 0.0.0.0:5001 app:app
```

## Project Structure

```
server/
├── app.py                 # Main application file
├── requirements.txt       # Python dependencies
├── runtime.txt           # Python version
├── app.yaml              # DigitalOcean App Platform config
├── migrate_to_postgresql.py  # Database migration script
├── models/               # Database models
│   ├── db.py            # Database initialization
│   └── users.py         # User model
├── routes/               # API route handlers
│   ├── auth_routes.py  # Authentication endpoints
│   └── user_routes.py  # User management endpoints
├── services/             # Business logic
│   ├── places_service.py
│   ├── directions_service.py
│   ├── recommendation/  # Recommendation engine
│   └── scrapers/        # Web scrapers
├── utils/                # Utility functions
│   ├── auth.py         # JWT authentication
│   ├── cache.py        # Caching utilities
│   ├── config.py       # Configuration management
│   ├── logging_config.py  # Logging setup
│   ├── context_manager.py  # Conversation context
│   └── retry.py        # Retry utilities
└── docs/                # Documentation
    ├── API.md
    ├── ARCHITECTURE.md
    ├── CONFIGURATION.md
    ├── DEPLOYMENT.md
    └── ...
```

## Development Workflow

### Code Standards

**Python Style**:
- Follow PEP 8
- Use type hints where appropriate
- Document functions with docstrings
- Keep functions focused and small

**Example**:
```python
def get_user_preferences(user_id: int) -> dict:
    """
    Get user preferences by user ID.
    
    Args:
        user_id: The user's ID
        
    Returns:
        Dictionary of user preferences
    """
    # Implementation
```

### Git Workflow

**Branching Strategy**:
- `main`: Production-ready code
- `develop`: Development branch
- `feature/*`: Feature branches
- `fix/*`: Bug fix branches

**Commit Messages**:
- Use clear, descriptive messages
- Format: `type: description`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`

**Example**:
```
feat: Add rate limiting to auth endpoints
fix: Resolve database connection pool issue
docs: Update API documentation
```

### Testing

**Manual Testing**:
```bash
# Test health endpoint
curl http://localhost:5001/health

# Test chat endpoint
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"I want coffee"}'
```

**API Testing**:
- Use Postman or similar tools
- Test all endpoints
- Verify error handling
- Check rate limiting

### Local Database

**SQLite Database**:
- Location: `instance/violetvibes.db`
- Created automatically on first run
- Reset: Delete `instance/violetvibes.db`

**Using PostgreSQL Locally** (optional):
```bash
# Install PostgreSQL
brew install postgresql  # macOS
sudo apt-get install postgresql  # Ubuntu

# Create database
createdb violetvibes

# Set DATABASE_URL
export DATABASE_URL="postgresql://user:password@localhost:5432/violetvibes"
```

### Local Redis (Optional)

**Install Redis**:
```bash
brew install redis  # macOS
sudo apt-get install redis  # Ubuntu
```

**Start Redis**:
```bash
redis-server
```

**Set REDIS_URL**:
```bash
export REDIS_URL="redis://localhost:6379/0"
```

## Environment Variables

### Development Setup

Create `.env` file:
```bash
# Required
JWT_SECRET=dev-secret-change-me
GEMINI_API_KEY=your-gemini-key
DATABASE_URL=sqlite:///violetvibes.db  # or PostgreSQL URL

# Optional
REDIS_URL=redis://localhost:6379/0
OPENWEATHER_KEY=your-key
FLASK_ENV=development
LOG_LEVEL=DEBUG
PORT=5001
```

### Testing Different Configurations

**With Redis**:
```bash
export REDIS_URL="redis://localhost:6379/0"
python app.py
```

**Without Redis** (memory fallback):
```bash
unset REDIS_URL
python app.py
```

**With PostgreSQL**:
```bash
export DATABASE_URL="postgresql://user:pass@localhost:5432/violetvibes"
python app.py
```

## Debugging

### Enable Debug Logging

```bash
export LOG_LEVEL=DEBUG
python app.py
```

### View Logs

Logs go to stdout. For file logging, configure in `utils/logging_config.py`.

### Debugging Tools

**Python Debugger**:
```python
import pdb
pdb.set_trace()  # Breakpoint
```

**Request Tracking**:
- Each request has a unique `request_id`
- Check logs for request ID to trace requests

### Common Debugging Scenarios

**Database Issues**:
```python
from app import app, db
with app.app_context():
    from models.users import User
    users = User.query.all()
    print(f"Users: {len(users)}")
```

**Redis Issues**:
```python
import redis
r = redis.from_url("redis://localhost:6379/0")
r.ping()  # Should return True
```

**API Testing**:
```python
from app import app
with app.test_client() as client:
    response = client.post('/api/chat', json={'message': 'test'})
    print(response.json)
```

## Code Review Process

### Before Submitting

1. **Run Linters**:
   ```bash
   flake8 .  # If configured
   ```

2. **Test Locally**:
   - Test all affected endpoints
   - Verify error handling
   - Check logs for warnings

3. **Update Documentation**:
   - Update API docs if endpoints change
   - Update CHANGELOG.md
   - Update relevant guides

### Review Checklist

- [ ] Code follows style guidelines
- [ ] Functions are documented
- [ ] Error handling is comprehensive
- [ ] Logging is appropriate
- [ ] No hardcoded secrets
- [ ] Tests pass (if applicable)
- [ ] Documentation updated

## Dependencies

### Adding New Dependencies

1. **Install Package**:
   ```bash
   pip install package-name
   ```

2. **Pin Version**:
   ```bash
   pip freeze | grep package-name >> requirements.txt
   ```

3. **Update requirements.txt**:
   - Add with version: `package-name==1.2.3`
   - Test installation: `pip install -r requirements.txt`

### Updating Dependencies

1. **Check for Updates**:
   ```bash
   pip list --outdated
   ```

2. **Update Carefully**:
   - Test updates in development
   - Check for breaking changes
   - Update requirements.txt

3. **Security Updates**:
   - Prioritize security patches
   - Test thoroughly before deploying

## Performance Considerations

### Development vs Production

**Development**:
- Single worker
- Debug mode enabled
- Verbose logging
- SQLite database

**Production**:
- Multiple workers (Gunicorn)
- Debug mode disabled
- Structured logging
- PostgreSQL database
- Redis for state/cache

### Optimization Tips

1. **Database Queries**:
   - Use connection pooling
   - Avoid N+1 queries
   - Use indexes appropriately

2. **Caching**:
   - Cache expensive operations
   - Use Redis for shared cache
   - Set appropriate TTLs

3. **External APIs**:
   - Use retry logic
   - Set timeouts
   - Cache responses when possible

## Troubleshooting Development Issues

### Import Errors

**Issue**: Module not found

**Solution**:
- Ensure virtual environment is activated
- Install dependencies: `pip install -r requirements.txt`
- Check Python path

### Database Locked

**Issue**: SQLite database locked

**Solution**:
- Close other connections
- Check for hanging processes
- Restart application

### Port Already in Use

**Issue**: Port 5001 already in use

**Solution**:
```bash
# Find process using port
lsof -i :5001

# Kill process or use different port
export PORT=5002
```

## Resources

### Documentation

- [Flask Documentation](https://flask.palletsprojects.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [DigitalOcean App Platform Docs](https://docs.digitalocean.com/products/app-platform/)

### Internal Documentation

- [API Reference](./API.md)
- [Architecture](./ARCHITECTURE.md)
- [Configuration](./CONFIGURATION.md)
- [Deployment](./DEPLOYMENT.md)

## Getting Help

1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Review application logs
3. Check documentation
4. Ask team members

