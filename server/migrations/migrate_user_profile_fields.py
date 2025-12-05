#!/usr/bin/env python3
"""
Migration script: Add user profile fields (first_name, home_address_encrypted)
Adds the new columns to the users table in PostgreSQL.
"""
import psycopg2
import os
import sys
from urllib.parse import urlparse
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# PostgreSQL connection string from environment
DATABASE_URL = os.getenv("DATABASE_URL")

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

def run_migration(pg_conn):
    """Run the migration SQL commands."""
    cursor = pg_conn.cursor()
    
    print("\n📝 Running migration SQL commands...")
    
    try:
        # Add first_name column
        print("   → Adding first_name column...")
        cursor.execute("""
            ALTER TABLE users 
            ADD COLUMN IF NOT EXISTS first_name VARCHAR(100);
        """)
        print("   ✓ first_name column added")
        
        # Add home_address_encrypted column
        print("   → Adding home_address_encrypted column...")
        cursor.execute("""
            ALTER TABLE users 
            ADD COLUMN IF NOT EXISTS home_address_encrypted TEXT;
        """)
        print("   ✓ home_address_encrypted column added")
        
        # Create index on first_name (optional, for faster lookups)
        print("   → Creating index on first_name...")
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_users_first_name ON users(first_name);
        """)
        print("   ✓ Index created")
        
        # Commit the transaction
        pg_conn.commit()
        print("\n✅ Migration completed successfully!")
        return True
        
    except Exception as e:
        print(f"\n❌ Migration failed: {e}")
        pg_conn.rollback()
        return False

def verify_migration(pg_conn):
    """Verify that the migration was successful."""
    cursor = pg_conn.cursor()
    
    print("\n🔍 Verifying migration...")
    
    try:
        # Check if columns exist
        cursor.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'users' 
            AND column_name IN ('first_name', 'home_address_encrypted')
            ORDER BY column_name;
        """)
        
        columns = cursor.fetchall()
        
        expected_columns = {
            'first_name': 'character varying',
            'home_address_encrypted': 'text'
        }
        
        found_columns = {col[0]: col[1] for col in columns}
        
        print("\n   Column check:")
        all_found = True
        for col_name, expected_type in expected_columns.items():
            if col_name in found_columns:
                actual_type = found_columns[col_name]
                if actual_type == expected_type or (col_name == 'first_name' and 'varying' in actual_type):
                    print(f"   ✓ {col_name}: {actual_type}")
                else:
                    print(f"   ⚠ {col_name}: {actual_type} (expected {expected_type})")
                    all_found = False
            else:
                print(f"   ❌ {col_name}: NOT FOUND")
                all_found = False
        
        # Check index
        cursor.execute("""
            SELECT indexname 
            FROM pg_indexes 
            WHERE tablename = 'users' 
            AND indexname = 'idx_users_first_name';
        """)
        index_exists = cursor.fetchone() is not None
        
        if index_exists:
            print("   ✓ Index idx_users_first_name exists")
        else:
            print("   ⚠ Index idx_users_first_name not found (optional)")
        
        if all_found:
            print("\n✅ Verification passed!")
            return True
        else:
            print("\n⚠ Verification found issues")
            return False
            
    except Exception as e:
        print(f"\n❌ Verification failed: {e}")
        return False

def main():
    """Main migration function."""
    print("=" * 60)
    print("User Profile Fields Migration")
    print("=" * 60)
    print("\nThis migration adds:")
    print("  - first_name (VARCHAR(100))")
    print("  - home_address_encrypted (TEXT)")
    print("  - Index on first_name")
    
    if not DATABASE_URL:
        print("\n❌ Error: DATABASE_URL environment variable not set")
        print("   Set it to your PostgreSQL connection string:")
        print("   export DATABASE_URL='postgresql://user:password@host:port/database?sslmode=require'")
        sys.exit(1)
    
    # Connect to PostgreSQL
    print(f"\n1. Connecting to PostgreSQL database...")
    try:
        pg_params = parse_postgres_url(DATABASE_URL)
        # Remove sslmode from connection params (handled separately)
        sslmode = pg_params.pop('sslmode', 'prefer')
        pg_conn = psycopg2.connect(**pg_params)
        if sslmode == 'require':
            pg_conn.set_session(autocommit=False)
        print(f"   ✓ Connected to PostgreSQL")
        print(f"   Database: {pg_params.get('database')}")
        print(f"   Host: {pg_params.get('host')}")
    except Exception as e:
        print(f"   ❌ Failed to connect to PostgreSQL: {e}")
        print(f"   Connection params: host={pg_params.get('host')}, database={pg_params.get('database')}")
        sys.exit(1)
    
    try:
        # Run migration
        print(f"\n2. Running migration...")
        success = run_migration(pg_conn)
        
        if not success:
            print("\n❌ Migration failed. Rolling back...")
            sys.exit(1)
        
        # Verify
        print(f"\n3. Verifying migration...")
        verified = verify_migration(pg_conn)
        
        if verified:
            print("\n" + "=" * 60)
            print("✅ Migration completed and verified successfully!")
            print("=" * 60)
            print("\nNext steps:")
            print("1. Test the application - new users should save first_name")
            print("2. Test home address encryption - addresses should be encrypted")
            print("3. Verify data isolation - different users see different data")
            print("\nNote: Existing users will have NULL for these fields")
            print("      They will be populated when users update their profile")
        else:
            print("\n" + "=" * 60)
            print("⚠ Migration completed but verification found issues")
            print("=" * 60)
            print("\nPlease review the verification results above")
            sys.exit(1)
        
    except Exception as e:
        print(f"\n❌ Migration failed: {e}")
        import traceback
        traceback.print_exc()
        pg_conn.rollback()
        sys.exit(1)
    
    finally:
        pg_conn.close()
        print("\n✓ Database connection closed")

if __name__ == "__main__":
    main()
