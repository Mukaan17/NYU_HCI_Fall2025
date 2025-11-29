# Database Migration Guide

## Overview

This guide covers migrating from SQLite (development) to PostgreSQL (production) for the VioletVibes backend.

## Migration Overview

### Why Migrate?

- **Production Requirements**: SQLite doesn't support concurrent writes well
- **Scalability**: PostgreSQL handles multiple connections efficiently
- **DigitalOcean**: Managed PostgreSQL available on App Platform
- **Features**: PostgreSQL offers better features for production use

### Migration Strategy

1. **Export Data**: Export data from SQLite database
2. **Schema Migration**: Ensure PostgreSQL schema matches
3. **Data Import**: Import data to PostgreSQL
4. **Verification**: Verify data integrity
5. **Switch**: Update `DATABASE_URL` to PostgreSQL

## Pre-Migration Checklist

- [ ] Backup SQLite database
- [ ] PostgreSQL database created and accessible
- [ ] Connection string obtained
- [ ] Schema compatibility verified
- [ ] Migration script tested locally
- [ ] Rollback plan prepared

## Step 1: Backup SQLite Database

### Create Backup

```bash
# Navigate to server directory
cd server

# Create backup
cp instance/violetvibes.db instance/violetvibes.db.backup

# Or use SQLite backup command
sqlite3 instance/violetvibes.db ".backup instance/violetvibes.db.backup"
```

### Verify Backup

```bash
# Check backup exists and is readable
sqlite3 instance/violetvibes.db.backup "SELECT COUNT(*) FROM users;"
```

## Step 2: Set Up PostgreSQL Database

### Create Database

If using DigitalOcean Managed Database:

1. Create PostgreSQL database in DigitalOcean dashboard
2. Copy connection string
3. Format: `postgresql://user:password@host:port/database?sslmode=require`

### Local PostgreSQL Setup (for testing)

```bash
# Install PostgreSQL (if not installed)
# macOS: brew install postgresql
# Ubuntu: sudo apt-get install postgresql

# Create database
createdb violetvibes

# Create user (optional)
createuser -P violetvibes_user
```

## Step 3: Schema Migration

### Verify Schema Compatibility

The current schema uses SQLAlchemy, which is compatible with both SQLite and PostgreSQL. However, there are some differences:

**JSON Storage**:
- SQLite: `TEXT` column with JSON strings
- PostgreSQL: `JSONB` or `TEXT` (both work)

**Current Implementation**: Uses `TEXT` for JSON, compatible with both.

### Create Tables in PostgreSQL

The application will create tables automatically when `db.create_all()` runs, but you can also create them manually:

```python
# In Python shell or migration script
from app import app, db
with app.app_context():
    db.create_all()
```

## Step 4: Data Migration

### Option A: Using Migration Script

Create and run the migration script (see `migrate_to_postgresql.py` below).

### Option B: Manual Migration

1. Export data from SQLite
2. Transform data format if needed
3. Import to PostgreSQL

## Migration Script

Create `server/migrate_to_postgresql.py`:

```python
#!/usr/bin/env python3
"""
Migration script: SQLite to PostgreSQL
"""
import sqlite3
import psycopg2
import json
import os
from urllib.parse import urlparse

# SQLite database path
SQLITE_DB = "instance/violetvibes.db"

# PostgreSQL connection string
POSTGRES_URL = os.getenv("DATABASE_URL")

def parse_postgres_url(url):
    """Parse PostgreSQL connection URL."""
    parsed = urlparse(url)
    return {
        'host': parsed.hostname,
        'port': parsed.port or 5432,
        'database': parsed.path.lstrip('/'),
        'user': parsed.username,
        'password': parsed.password
    }

def migrate_users(sqlite_conn, pg_conn):
    """Migrate users table."""
    sqlite_cursor = sqlite_conn.cursor()
    pg_cursor = pg_conn.cursor()
    
    # Get all users from SQLite
    sqlite_cursor.execute("SELECT id, email, password_hash, preferences, settings, recent_activity, notification_token, google_refresh_token, created_at FROM users")
    users = sqlite_cursor.fetchall()
    
    print(f"Migrating {len(users)} users...")
    
    for user in users:
        try:
            pg_cursor.execute("""
                INSERT INTO users (id, email, password_hash, preferences, settings, recent_activity, notification_token, google_refresh_token, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING
            """, user)
        except Exception as e:
            print(f"Error migrating user {user[1]}: {e}")
    
    pg_conn.commit()
    print(f"Migrated {len(users)} users")

def verify_migration(sqlite_conn, pg_conn):
    """Verify migration success."""
    sqlite_cursor = sqlite_conn.cursor()
    pg_cursor = pg_conn.cursor()
    
    # Count users
    sqlite_cursor.execute("SELECT COUNT(*) FROM users")
    sqlite_count = sqlite_cursor.fetchone()[0]
    
    pg_cursor.execute("SELECT COUNT(*) FROM users")
    pg_count = pg_cursor.fetchone()[0]
    
    print(f"SQLite users: {sqlite_count}")
    print(f"PostgreSQL users: {pg_count}")
    
    if sqlite_count == pg_count:
        print("✓ User count matches!")
    else:
        print("✗ User count mismatch!")
    
    # Verify sample data
    if sqlite_count > 0:
        sqlite_cursor.execute("SELECT email FROM users LIMIT 1")
        sqlite_email = sqlite_cursor.fetchone()[0]
        
        pg_cursor.execute("SELECT email FROM users LIMIT 1")
        pg_email = pg_cursor.fetchone()[0]
        
        if sqlite_email == pg_email:
            print("✓ Sample data matches!")
        else:
            print("✗ Sample data mismatch!")

def main():
    """Main migration function."""
    if not POSTGRES_URL:
        print("Error: DATABASE_URL environment variable not set")
        return
    
    # Connect to SQLite
    print("Connecting to SQLite...")
    sqlite_conn = sqlite3.connect(SQLITE_DB)
    
    # Connect to PostgreSQL
    print("Connecting to PostgreSQL...")
    pg_params = parse_postgres_url(POSTGRES_URL)
    pg_conn = psycopg2.connect(**pg_params)
    
    try:
        # Migrate data
        migrate_users(sqlite_conn, pg_conn)
        
        # Verify
        verify_migration(sqlite_conn, pg_conn)
        
        print("\n✓ Migration completed successfully!")
        
    except Exception as e:
        print(f"\n✗ Migration failed: {e}")
        pg_conn.rollback()
        raise
    
    finally:
        sqlite_conn.close()
        pg_conn.close()

if __name__ == "__main__":
    main()
```

### Run Migration Script

```bash
# Set PostgreSQL connection string
export DATABASE_URL="postgresql://user:password@host:port/database?sslmode=require"

# Run migration
cd server
python migrate_to_postgresql.py
```

## Step 5: Update Application Configuration

### Update Environment Variable

In DigitalOcean App Platform:

1. Go to App Settings
2. Navigate to Environment Variables
3. Update `DATABASE_URL` to PostgreSQL connection string
4. Save and redeploy

### Verify Connection

```bash
# Test connection
curl https://your-app.ondigitalocean.app/health
```

Should return:
```json
{
  "status": "ok",
  "database": "connected",
  "redis": "connected"
}
```

## Step 6: Post-Migration Verification

### Data Verification

1. **Count Records**: Verify record counts match
2. **Sample Data**: Check sample records
3. **Functionality**: Test API endpoints
4. **Performance**: Monitor query performance

### Test Endpoints

```bash
# Test authentication
curl -X POST https://your-app.ondigitalocean.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Test user endpoints
curl -X GET https://your-app.ondigitalocean.app/api/user/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Rollback Procedure

If migration fails or issues occur:

### Option 1: Revert to SQLite

1. Update `DATABASE_URL` back to SQLite (or remove it)
2. Redeploy application
3. Application will use SQLite again

### Option 2: Restore from Backup

1. Restore SQLite backup
2. Continue using SQLite until issues resolved

### Option 3: Database Restore

If using managed PostgreSQL:

1. Use database backup/restore feature
2. Restore to pre-migration state
3. Investigate and fix issues
4. Retry migration

## Common Issues

### Schema Differences

**Issue**: PostgreSQL stricter with data types

**Solution**: Ensure all data types compatible, use SQLAlchemy types

### JSON Column Handling

**Issue**: JSON stored differently in SQLite vs PostgreSQL

**Solution**: Current implementation uses TEXT, compatible with both

### Connection String Format

**Issue**: Incorrect connection string format

**Solution**: Use format: `postgresql://user:password@host:port/database?sslmode=require`

### SSL/TLS Requirements

**Issue**: PostgreSQL requires SSL in production

**Solution**: Include `?sslmode=require` in connection string

### Character Encoding

**Issue**: Encoding issues with special characters

**Solution**: Ensure UTF-8 encoding throughout

## Migration Timeline

**Estimated Time**: 30-60 minutes

1. Backup: 2 minutes
2. PostgreSQL setup: 5-10 minutes
3. Schema creation: 1 minute
4. Data migration: 5-30 minutes (depends on data size)
5. Verification: 5-10 minutes
6. Configuration update: 5 minutes
7. Testing: 10-15 minutes

## Best Practices

### Before Migration

- Test migration script locally
- Backup everything
- Schedule during low-traffic period
- Have rollback plan ready

### During Migration

- Monitor migration progress
- Check for errors
- Verify data as you go
- Keep SQLite database until verified

### After Migration

- Monitor application logs
- Check error rates
- Verify all endpoints work
- Keep backup for at least 7 days

## Troubleshooting

### Migration Script Errors

**Check**:
- Database connection strings
- Table schemas match
- Data types compatible
- Permissions correct

### Connection Issues

**Check**:
- Database firewall rules
- Connection string format
- SSL/TLS settings
- Network connectivity

### Data Issues

**Check**:
- Record counts
- Sample data integrity
- JSON parsing
- Date/time formats

For more troubleshooting, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

## Support

If migration issues occur:
1. Check logs for specific errors
2. Verify connection strings
3. Test database connectivity
4. Review migration script output
5. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

