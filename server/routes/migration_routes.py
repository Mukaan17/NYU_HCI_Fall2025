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


@migration_bp.route("/migrate/user-profile-fields", methods=["POST"])
def migrate_user_profile_fields():
    """
    One-time migration endpoint to add first_name and home_address_encrypted columns.
    
    SECURITY: This endpoint should be protected or removed after migration.
    For now, it requires a secret token in the request header.
    """
    # Simple security: require a migration token
    migration_token = os.getenv("MIGRATION_TOKEN", "change-me-in-production")
    provided_token = request.headers.get("X-Migration-Token")
    
    if provided_token != migration_token:
        logger.warning("Migration attempt with invalid token")
        return jsonify({"error": "Unauthorized"}), 401
    
    try:
        logger.info("Starting user profile fields migration...")
        
        # Run migration SQL
        with db.engine.connect() as connection:
            # Add first_name column
            connection.execute(db.text("""
                ALTER TABLE users 
                ADD COLUMN IF NOT EXISTS first_name VARCHAR(100);
            """))
            logger.info("✓ Added first_name column")
            
            # Add home_address_encrypted column
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
            result = connection.execute(db.text("""
                SELECT column_name, data_type 
                FROM information_schema.columns 
                WHERE table_name = 'users' 
                AND column_name IN ('first_name', 'home_address_encrypted')
                ORDER BY column_name;
            """))
            
            columns = result.fetchall()
            found_columns = {col[0]: col[1] for col in columns}
            
            verification = {
                "first_name": "first_name" in found_columns,
                "home_address_encrypted": "home_address_encrypted" in found_columns,
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
        with db.engine.connect() as connection:
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
                "columns": found_columns
            }), 200
            
    except Exception as e:
        logger.error(f"Error checking migration status: {e}", exc_info=True)
        return jsonify({
            "error": str(e)
        }), 500
