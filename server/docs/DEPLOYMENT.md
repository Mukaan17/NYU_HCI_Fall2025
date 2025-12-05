# Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the VioletVibes backend to DigitalOcean App Platform.

## Prerequisites

- DigitalOcean account with $200 credit (or active billing)
- GitHub repository with the backend code
- Access to required API keys:
  - Google Gemini API key
  - Google Places API key (optional, for enhanced features)
  - OpenWeather API key (optional)

## Pre-Deployment Checklist

- [ ] All code changes committed to GitHub
- [ ] `requirements.txt` includes all dependencies
- [ ] `runtime.txt` specifies Python version
- [ ] `app.yaml` configured (optional but recommended)
- [ ] Environment variables documented
- [ ] Database migration strategy planned
- [ ] Health check endpoint tested locally

## Step 1: Create DigitalOcean App Platform App

1. Log in to [DigitalOcean Control Panel](https://cloud.digitalocean.com/apps)
2. Click **Create App**
3. Select **GitHub** as source
4. Choose your repository and branch (typically `main`)
5. Enable **Autodeploy** to automatically deploy on push

## Step 2: Configure App Settings

### Build Configuration

- **Build Command**: `pip install -r requirements.txt`
- **Run Command**: `gunicorn --worker-tmp-dir /dev/shm --workers 2 --timeout 120 --bind 0.0.0.0:$PORT app:app`

### Environment Variables

Configure the following environment variables in the App Platform dashboard:

**Required:**
- `JWT_SECRET`: Secret key for JWT tokens (generate a strong random string)
- `GEMINI_API_KEY`: Your Google Gemini API key
- `DATABASE_URL`: PostgreSQL connection string (from managed database)
- `FLASK_ENV`: Set to `production`

**Optional but Recommended:**
- `REDIS_URL`: Redis connection string (for state management and caching)
- `OPENWEATHER_KEY`: OpenWeather API key
- `ALLOWED_ORIGINS`: Comma-separated list of allowed CORS origins
- `LOG_LEVEL`: Set to `INFO` for production

### Health Check Configuration

- **HTTP Path**: `/health`
- **Initial Delay**: 10 seconds
- **Period**: 10 seconds
- **Timeout**: 5 seconds
- **Success Threshold**: 1
- **Failure Threshold**: 3

## Step 3: Set Up Database

### Option A: Dev Database (Free, Limited)

1. In App Platform, add a **Dev Database** component
2. Select **PostgreSQL**
3. Database will be automatically connected via `DATABASE_URL`

**Limitations:**
- Same region as app only
- No additional databases
- Not recommended for production

### Option B: Managed Database (Recommended)

1. Create a **Managed Database** in DigitalOcean
2. Select **PostgreSQL** version 15
3. Choose region (same as app for best performance)
4. Select plan (Basic plan sufficient for most use cases)
5. Copy connection string
6. Set `DATABASE_URL` environment variable in App Platform

**Connection String Format:**
```
postgresql://user:password@host:port/database?sslmode=require
```

## Step 4: Set Up Redis/Valkey (Optional but Recommended)

### Option A: Managed Valkey (Redis-Compatible)

DigitalOcean now offers **Valkey** (a Redis-compatible fork) instead of Redis. Valkey is fully compatible with Redis clients and protocols.

1. Create **Managed Valkey** database in DigitalOcean
2. Copy connection string (format: `redis://user:password@host:port/db`)
3. Set `REDIS_URL` environment variable with the Valkey connection string

**Note**: The `redis` Python client library works perfectly with Valkey since it uses the same protocol.

### Option B: Skip Redis/Valkey

If Redis/Valkey is not configured:
- Conversation context will use in-memory storage (not shared across workers)
- Cache will use memory backend
- Rate limiting will use memory backend

## Step 5: Configure CORS

Set `ALLOWED_ORIGINS` environment variable with comma-separated list:

```
ALLOWED_ORIGINS=https://your-frontend.com,https://another-domain.com
```

For development, localhost origins are automatically allowed.

## Step 6: Deploy

1. Review all settings
2. Select app plan (Basic plan sufficient for most use cases)
3. Click **Launch Basic/Pro App**
4. Wait for deployment to complete (typically 5-10 minutes)

## Step 7: Verify Deployment

### Check Health Endpoint

```bash
curl https://your-app-name.ondigitalocean.app/health
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

```bash
# Test chat endpoint
curl -X POST https://your-app-name.ondigitalocean.app/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "I want coffee"}'

# Test quick recommendations
curl https://your-app-name.ondigitalocean.app/api/quick_recs?category=chill_cafes
```

### Check Logs

1. Navigate to **Activity** tab in App Platform
2. View build and runtime logs
3. Check for any errors or warnings

## Step 8: Update Frontend Configuration

### React Native/Expo App

Update `.env` or app configuration:
```
EXPO_PUBLIC_API_URL=https://your-app-name.ondigitalocean.app
```

### iOS App

Update `Config.plist`:
```xml
<key>API_URL</key>
<string>https://your-app-name.ondigitalocean.app</string>
```

## Post-Deployment

### Monitor Application

- Check **Metrics** tab for CPU, memory, and request metrics
- Set up alerts for high error rates
- Monitor database connections

### Database Migration

If migrating from SQLite to PostgreSQL:

1. Export data from SQLite:
   ```bash
   sqlite3 violetvibes.db .dump > backup.sql
   ```

2. Import to PostgreSQL (adjust schema as needed):
   ```bash
   psql $DATABASE_URL < backup.sql
   ```

3. Verify data integrity

### Rollback Procedure

If deployment fails:

1. Go to **Deployments** tab
2. Find previous successful deployment
3. Click **Rollback**
4. Investigate issues in logs

## Troubleshooting

### Common Issues

**Build Fails:**
- Check `requirements.txt` for all dependencies
- Verify Python version in `runtime.txt`
- Check build logs for specific errors

**App Won't Start:**
- Verify all required environment variables are set
- Check runtime logs for errors
- Ensure `PORT` environment variable is set (auto-set by App Platform)

**Database Connection Fails:**
- Verify `DATABASE_URL` is correct
- Check database firewall rules
- Ensure database is in same region as app

**Health Check Fails:**
- Check `/health` endpoint manually
- Verify database and Redis connectivity
- Review application logs

### Getting Help

- Check [DigitalOcean App Platform Documentation](https://docs.digitalocean.com/products/app-platform/)
- Review application logs in App Platform dashboard
- Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues

## Cost Estimation

With $200 credit:
- Basic App: ~$5-12/month
- Managed PostgreSQL: ~$15/month
- Managed Valkey (Redis-compatible): ~$15/month (optional)
- **Total**: ~$20-42/month
- **Credit Duration**: ~5-10 months

## Next Steps

- Set up monitoring and alerts
- Configure custom domain (optional)
- Set up CI/CD for automated deployments
- Review [SECURITY.md](./SECURITY.md) for security best practices

