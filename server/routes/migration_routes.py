# server/routes/migration_routes.py

"""
One-time migration endpoint for adding user profile fields.
This endpoint should be called once to migrate the database, then removed or disabled.
"""
from flask import Blueprint, request, jsonify, g
from models.db import db
import logging
import os

logger = logging.getLogger(__name__)
migration_bp = Blueprint("migration", __name__)


def is_sqlite():
    """Check if the database is SQLite."""
    return db.engine.url.drivername == "sqlite"


def column_exists_sqlite(connection, table_name, column_name):
    """Check if a column exists in SQLite."""
    result = connection.execute(db.text(f"PRAGMA table_info({table_name})"))
    columns = result.fetchall()
    # SQLite PRAGMA returns: (cid, name, type, notnull, default_value, pk)
    return any(col[1] == column_name for col in columns)


def column_exists_postgres(connection, table_name, column_name):
    """Check if a column exists in PostgreSQL."""
    result = connection.execute(db.text("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = :table_name 
        AND column_name = :column_name;
    """), {"table_name": table_name, "column_name": column_name})
    return result.fetchone() is not None


@migration_bp.route("/migrate/user-profile-fields", methods=["POST"])
def migrate_user_profile_fields():
    """
    One-time migration endpoint to add first_name and home_address_encrypted columns.
    
    SECURITY: This endpoint should be protected or removed after migration.
    For now, it requires a secret token in the request header.
    """
    # Simple security: require a migration token (skip in development)
    env = os.getenv("FLASK_ENV", os.getenv("ENVIRONMENT", "development")).lower()
    is_production = env in ("production", "prod")
    
    if is_production:
        migration_token = os.getenv("MIGRATION_TOKEN", "change-me-in-production")
        provided_token = request.headers.get("X-Migration-Token")
        
        if provided_token != migration_token:
            logger.warning("Migration attempt with invalid token")
            return jsonify({"error": "Unauthorized"}), 401
    else:
        logger.info("Running migration in development mode (token check skipped)")
    
    try:
        logger.info("Starting user profile fields migration...")
        is_sqlite_db = is_sqlite()
        logger.info(f"Database type: {'SQLite' if is_sqlite_db else 'PostgreSQL'}")
        
        # Run migration SQL
        with db.engine.connect() as connection:
            # Add first_name column (check if exists first for SQLite)
            if is_sqlite_db:
                if not column_exists_sqlite(connection, "users", "first_name"):
                    connection.execute(db.text("""
                        ALTER TABLE users 
                        ADD COLUMN first_name VARCHAR(100);
                    """))
                    logger.info("✓ Added first_name column")
                else:
                    logger.info("✓ first_name column already exists")
            else:
                # PostgreSQL supports IF NOT EXISTS
                connection.execute(db.text("""
                    ALTER TABLE users 
                    ADD COLUMN IF NOT EXISTS first_name VARCHAR(100);
                """))
                logger.info("✓ Added first_name column")
            
            # Add home_address_encrypted column
            if is_sqlite_db:
                if not column_exists_sqlite(connection, "users", "home_address_encrypted"):
                    connection.execute(db.text("""
                        ALTER TABLE users 
                        ADD COLUMN home_address_encrypted TEXT;
                    """))
                    logger.info("✓ Added home_address_encrypted column")
                else:
                    logger.info("✓ home_address_encrypted column already exists")
            else:
                connection.execute(db.text("""
                    ALTER TABLE users 
                    ADD COLUMN IF NOT EXISTS home_address_encrypted TEXT;
                """))
                logger.info("✓ Added home_address_encrypted column")
            
            # Create index on first_name
            connection.execute(db.text("""
                CREATE INDEX IF NOT EXISTS idx_users_first_name ON users(first_name);
            """))
            logger.info("✓ Created index on first_name")
            
            connection.commit()
        
        # Verify migration
        with db.engine.connect() as connection:
            if is_sqlite_db:
                # SQLite verification
                first_name_exists = column_exists_sqlite(connection, "users", "first_name")
                home_address_exists = column_exists_sqlite(connection, "users", "home_address_encrypted")
                found_columns = {}
                if first_name_exists:
                    found_columns["first_name"] = "VARCHAR(100)"
                if home_address_exists:
                    found_columns["home_address_encrypted"] = "TEXT"
            else:
                # PostgreSQL verification
                result = connection.execute(db.text("""
                    SELECT column_name, data_type 
                    FROM information_schema.columns 
                    WHERE table_name = 'users' 
                    AND column_name IN ('first_name', 'home_address_encrypted')
                    ORDER BY column_name;
                """))
                columns = result.fetchall()
                found_columns = {col[0]: col[1] for col in columns}
                first_name_exists = "first_name" in found_columns
                home_address_exists = "home_address_encrypted" in found_columns
            
            verification = {
                "first_name": first_name_exists,
                "home_address_encrypted": home_address_exists,
                "columns": found_columns
            }
        
        logger.info("Migration completed successfully")
        
        return jsonify({
            "status": "success",
            "message": "Migration completed successfully",
            "verification": verification
        }), 200
        
    except Exception as e:
        logger.error(f"Migration failed: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({
            "status": "error",
            "error": str(e)
        }), 500


@migration_bp.route("/migrate/user-profile-fields/status", methods=["GET"])
def check_migration_status():
    """
    Check if migration has been completed.
    """
    try:
        is_sqlite_db = is_sqlite()
        with db.engine.connect() as connection:
            if is_sqlite_db:
                # SQLite verification
                first_name_exists = column_exists_sqlite(connection, "users", "first_name")
                home_address_exists = column_exists_sqlite(connection, "users", "home_address_encrypted")
                found_columns = {}
                if first_name_exists:
                    found_columns["first_name"] = "VARCHAR(100)"
                if home_address_exists:
                    found_columns["home_address_encrypted"] = "TEXT"
            else:
                # PostgreSQL verification
                result = connection.execute(db.text("""
                    SELECT column_name, data_type 
                    FROM information_schema.columns 
                    WHERE table_name = 'users' 
                    AND column_name IN ('first_name', 'home_address_encrypted')
                    ORDER BY column_name;
                """))
                columns = result.fetchall()
                found_columns = {col[0]: col[1] for col in columns}
                first_name_exists = "first_name" in found_columns
                home_address_exists = "home_address_encrypted" in found_columns
            
            return jsonify({
                "migrated": first_name_exists and home_address_exists,
                "first_name": first_name_exists,
                "home_address_encrypted": home_address_exists,
                "columns": found_columns,
                "database_type": "SQLite" if is_sqlite_db else "PostgreSQL"
            }), 200
            
    except Exception as e:
        logger.error(f"Error checking migration status: {e}", exc_info=True)
        return jsonify({
            "error": str(e)
        }), 500
