#!/usr/bin/env python3
"""
Migration script: SQLite to PostgreSQL
Migrates data from SQLite database to PostgreSQL database.
"""
import sqlite3
import psycopg2
import json
import os
import sys
from urllib.parse import urlparse
from datetime import datetime

# SQLite database path
SQLITE_DB = "instance/violetvibes.db"

# PostgreSQL connection string from environment
POSTGRES_URL = os.getenv("DATABASE_URL")

def parse_postgres_url(url):
    """Parse PostgreSQL connection URL."""
    parsed = urlparse(url)
    return {
        'host': parsed.hostname,
        'port': parsed.port or 5432,
        'database': parsed.path.lstrip('/').split('?')[0],  # Remove query params
        'user': parsed.username,
        'password': parsed.password,
        'sslmode': 'require' if 'sslmode=require' in url else 'prefer'
    }

def migrate_users(sqlite_conn, pg_conn):
    """Migrate users table."""
    sqlite_cursor = sqlite_conn.cursor()
    pg_cursor = pg_conn.cursor()
    
    # Get all users from SQLite
    sqlite_cursor.execute("""
        SELECT id, email, password_hash, preferences, settings, 
               recent_activity, notification_token, google_refresh_token, created_at 
        FROM users
    """)
    users = sqlite_cursor.fetchall()
    
    print(f"Migrating {len(users)} users...")
    
    migrated = 0
    errors = 0
    
    for user in users:
        try:
            # Handle None values and ensure proper types
            user_id, email, password_hash, preferences, settings, \
            recent_activity, notification_token, google_refresh_token, created_at = user
            
            # Ensure JSON fields are strings
            preferences = preferences if preferences else '{}'
            settings = settings if settings else '{}'
            recent_activity = recent_activity if recent_activity else '[]'
            
            pg_cursor.execute("""
                INSERT INTO users (
                    id, email, password_hash, preferences, settings, 
                    recent_activity, notification_token, google_refresh_token, created_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                    email = EXCLUDED.email,
                    password_hash = EXCLUDED.password_hash,
                    preferences = EXCLUDED.preferences,
                    settings = EXCLUDED.settings,
                    recent_activity = EXCLUDED.recent_activity,
                    notification_token = EXCLUDED.notification_token,
                    google_refresh_token = EXCLUDED.google_refresh_token,
                    created_at = EXCLUDED.created_at
            """, (
                user_id, email, password_hash, preferences, settings,
                recent_activity, notification_token, google_refresh_token, created_at
            ))
            migrated += 1
        except Exception as e:
            print(f"Error migrating user {user[1] if len(user) > 1 else 'unknown'}: {e}")
            errors += 1
    
    pg_conn.commit()
    print(f"✓ Migrated {migrated} users (errors: {errors})")
    return migrated, errors

def verify_migration(sqlite_conn, pg_conn):
    """Verify migration success."""
    sqlite_cursor = sqlite_conn.cursor()
    pg_cursor = pg_conn.cursor()
    
    # Count users
    sqlite_cursor.execute("SELECT COUNT(*) FROM users")
    sqlite_count = sqlite_cursor.fetchone()[0]
    
    pg_cursor.execute("SELECT COUNT(*) FROM users")
    pg_count = pg_cursor.fetchone()[0]
    
    print(f"\nVerification:")
    print(f"  SQLite users: {sqlite_count}")
    print(f"  PostgreSQL users: {pg_count}")
    
    if sqlite_count == pg_count:
        print("  ✓ User count matches!")
    else:
        print(f"  ✗ User count mismatch! (difference: {abs(sqlite_count - pg_count)})")
        return False
    
    # Verify sample data if users exist
    if sqlite_count > 0:
        sqlite_cursor.execute("SELECT id, email FROM users ORDER BY id LIMIT 1")
        sqlite_user = sqlite_cursor.fetchone()
        
        if sqlite_user:
            user_id, email = sqlite_user
            pg_cursor.execute("SELECT id, email FROM users WHERE id = %s", (user_id,))
            pg_user = pg_cursor.fetchone()
            
            if pg_user and pg_user[1] == email:
                print(f"  ✓ Sample user data matches (ID: {user_id}, Email: {email})")
            else:
                print(f"  ✗ Sample user data mismatch!")
                return False
    
    return True

def main():
    """Main migration function."""
    print("=" * 60)
    print("SQLite to PostgreSQL Migration Script")
    print("=" * 60)
    
    if not POSTGRES_URL:
        print("\n✗ Error: DATABASE_URL environment variable not set")
        print("   Set it to your PostgreSQL connection string:")
        print("   export DATABASE_URL='postgresql://user:password@host:port/database?sslmode=require'")
        sys.exit(1)
    
    # Check SQLite database exists
    if not os.path.exists(SQLITE_DB):
        print(f"\n✗ Error: SQLite database not found at {SQLITE_DB}")
        sys.exit(1)
    
    # Connect to SQLite
    print(f"\n1. Connecting to SQLite database: {SQLITE_DB}")
    try:
        sqlite_conn = sqlite3.connect(SQLITE_DB)
        print("   ✓ Connected to SQLite")
    except Exception as e:
        print(f"   ✗ Failed to connect to SQLite: {e}")
        sys.exit(1)
    
    # Connect to PostgreSQL
    print(f"\n2. Connecting to PostgreSQL database...")
    try:
        pg_params = parse_postgres_url(POSTGRES_URL)
        # Remove sslmode from connection params (handled separately)
        sslmode = pg_params.pop('sslmode', 'prefer')
        pg_conn = psycopg2.connect(**pg_params)
        if sslmode == 'require':
            pg_conn.set_session(autocommit=False)
        print("   ✓ Connected to PostgreSQL")
    except Exception as e:
        print(f"   ✗ Failed to connect to PostgreSQL: {e}")
        print(f"   Connection params: host={pg_params.get('host')}, database={pg_params.get('database')}")
        sqlite_conn.close()
        sys.exit(1)
    
    try:
        # Migrate data
        print(f"\n3. Migrating data...")
        migrated, errors = migrate_users(sqlite_conn, pg_conn)
        
        if errors > 0:
            print(f"\n⚠ Warning: {errors} errors during migration")
        
        # Verify
        print(f"\n4. Verifying migration...")
        success = verify_migration(sqlite_conn, pg_conn)
        
        if success:
            print("\n" + "=" * 60)
            print("✓ Migration completed successfully!")
            print("=" * 60)
            print(f"\nMigrated {migrated} users to PostgreSQL")
            print("\nNext steps:")
            print("1. Update DATABASE_URL in your application")
            print("2. Test the application with PostgreSQL")
            print("3. Keep SQLite backup for at least 7 days")
        else:
            print("\n" + "=" * 60)
            print("⚠ Migration completed with warnings")
            print("=" * 60)
            print("\nPlease review the verification results above")
            sys.exit(1)
        
    except Exception as e:
        print(f"\n✗ Migration failed: {e}")
        import traceback
        traceback.print_exc()
        pg_conn.rollback()
        sys.exit(1)
    
    finally:
        sqlite_conn.close()
        pg_conn.close()
        print("\n✓ Database connections closed")

if __name__ == "__main__":
    main()

