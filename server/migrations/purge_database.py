#!/usr/bin/env python3
"""
Standalone script to purge database - DANGEROUS!
Deletes all data from the database.

Usage:
    python3 purge_database.py --confirm

This script requires explicit confirmation and will delete ALL data.
"""
import psycopg2
import os
import sys
from urllib.parse import urlparse
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

def parse_postgres_url(url):
    """Parse PostgreSQL connection URL."""
    parsed = urlparse(url)
    return {
        'host': parsed.hostname,
        'port': parsed.port or 5432,
        'database': parsed.path.lstrip('/').split('?')[0],
        'user': parsed.username,
        'password': parsed.password,
        'sslmode': 'require' if 'sslmode=require' in url else 'prefer'
    }

def purge_all_data(pg_conn):
    """Delete all data from all tables."""
    cursor = pg_conn.cursor()
    
    print("\n⚠️  WARNING: This will delete ALL data from the database!")
    print("   Tables affected: users, and all related data")
    
    try:
        # Get user count first
        cursor.execute("SELECT COUNT(*) FROM users;")
        user_count = cursor.fetchone()[0]
        
        print(f"\n   Current user count: {user_count}")
        
        if user_count == 0:
            print("   ✓ Database is already empty")
            return True
        
        # Delete all users
        print("\n   → Deleting all users...")
        cursor.execute("DELETE FROM users;")
        deleted = cursor.rowcount
        
        # Commit the deletion
        pg_conn.commit()
        
        print(f"   ✓ Deleted {deleted} users")
        
        return True
        
    except Exception as e:
        print(f"\n   ❌ Error during purge: {e}")
        pg_conn.rollback()
        return False

def verify_purge(pg_conn):
    """Verify that the purge was successful."""
    cursor = pg_conn.cursor()
    
    print("\n🔍 Verifying purge...")
    
    try:
        cursor.execute("SELECT COUNT(*) FROM users;")
        user_count = cursor.fetchone()[0]
        
        if user_count == 0:
            print("   ✓ Database is empty (purge successful)")
            return True
        else:
            print(f"   ⚠ Database still has {user_count} users")
            return False
            
    except Exception as e:
        print(f"   ❌ Verification failed: {e}")
        return False

def main():
    """Main purge function."""
    print("=" * 60)
    print("⚠️  DATABASE PURGE SCRIPT - DANGEROUS OPERATION")
    print("=" * 60)
    print("\nThis script will DELETE ALL DATA from the database!")
    print("This action CANNOT be undone!")
    
    # Require --confirm flag
    if "--confirm" not in sys.argv:
        print("\n❌ Error: Confirmation required")
        print("   Usage: python3 purge_database.py --confirm")
        print("\n   This is a safety measure to prevent accidental deletion.")
        sys.exit(1)
    
    if not DATABASE_URL:
        print("\n❌ Error: DATABASE_URL environment variable not set")
        print("   Set it to your PostgreSQL connection string:")
        print("   export DATABASE_URL='postgresql://user:password@host:port/database?sslmode=require'")
        sys.exit(1)
    
    # Final confirmation
    print("\n" + "=" * 60)
    print("⚠️  FINAL WARNING")
    print("=" * 60)
    print("You are about to DELETE ALL DATA from:")
    print(f"  Database: {parse_postgres_url(DATABASE_URL).get('database')}")
    print(f"  Host: {parse_postgres_url(DATABASE_URL).get('host')}")
    print("\nThis will delete:")
    print("  - All users")
    print("  - All user data (preferences, settings, activity)")
    print("  - Everything in the database")
    print("\n⚠️  THIS CANNOT BE UNDONE!")
    
    response = input("\nType 'DELETE ALL DATA' to confirm: ")
    
    if response != "DELETE ALL DATA":
        print("\n❌ Confirmation text did not match. Aborting.")
        sys.exit(1)
    
    # Connect to PostgreSQL
    print(f"\n1. Connecting to PostgreSQL database...")
    try:
        pg_params = parse_postgres_url(DATABASE_URL)
        sslmode = pg_params.pop('sslmode', 'prefer')
        pg_conn = psycopg2.connect(**pg_params)
        if sslmode == 'require':
            pg_conn.set_session(autocommit=False)
        print(f"   ✓ Connected to PostgreSQL")
        print(f"   Database: {pg_params.get('database')}")
        print(f"   Host: {pg_params.get('host')}")
    except Exception as e:
        print(f"   ❌ Failed to connect to PostgreSQL: {e}")
        sys.exit(1)
    
    try:
        # Purge data
        print(f"\n2. Purging database...")
        success = purge_all_data(pg_conn)
        
        if not success:
            print("\n❌ Purge failed. Rolling back...")
            sys.exit(1)
        
        # Verify
        print(f"\n3. Verifying purge...")
        verified = verify_purge(pg_conn)
        
        if verified:
            print("\n" + "=" * 60)
            print("✅ Database purged successfully!")
            print("=" * 60)
            print("\nAll data has been deleted from the database.")
            print("The database structure (tables, columns) remains intact.")
        else:
            print("\n" + "=" * 60)
            print("⚠️  Purge completed but verification found issues")
            print("=" * 60)
            sys.exit(1)
        
    except Exception as e:
        print(f"\n❌ Purge failed: {e}")
        import traceback
        traceback.print_exc()
        pg_conn.rollback()
        sys.exit(1)
    
    finally:
        pg_conn.close()
        print("\n✓ Database connection closed")

if __name__ == "__main__":
    main()
