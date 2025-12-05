# server/routes/purge_routes.py

"""
Database purge endpoint - DANGEROUS: Deletes all data!
This endpoint should be used with extreme caution and removed after use.
"""
from flask import Blueprint, request, jsonify
from models.db import db
from models.users import User
import logging
import os

logger = logging.getLogger(__name__)
purge_bp = Blueprint("purge", __name__)


@purge_bp.route("/purge/all", methods=["POST"])
def purge_all_data():
    """
    DANGEROUS: Deletes ALL data from the database.
    
    Requires:
    - X-Purge-Token header matching PURGE_TOKEN environment variable
    - confirm=true in request body
    
    This will delete:
    - All users
    - All user data (preferences, settings, activity)
    - Everything in the database
    
    SECURITY: This endpoint should be removed after use or heavily protected.
    """
    # Security: require a purge token
    purge_token = os.getenv("PURGE_TOKEN", "NEVER-USE-THIS-DEFAULT")
    provided_token = request.headers.get("X-Purge-Token")
    
    if provided_token != purge_token:
        logger.warning("Purge attempt with invalid token")
        return jsonify({"error": "Unauthorized"}), 401
    
    # Require explicit confirmation
    data = request.get_json(force=True) or {}
    if data.get("confirm") != True:
        return jsonify({
            "error": "Confirmation required",
            "message": "You must set 'confirm': true in the request body to proceed"
        }), 400
    
    try:
        logger.warning("⚠️ PURGE REQUEST RECEIVED - DELETING ALL DATA")
        
        # Get counts before deletion
        user_count = User.query.count()
        
        # Delete all users (this will cascade if foreign keys are set up)
        deleted = User.query.delete()
        db.session.commit()
        
        logger.warning(f"⚠️ PURGED {deleted} users from database")
        
        return jsonify({
            "status": "success",
            "message": f"Database purged successfully. Deleted {deleted} users.",
            "deleted_users": deleted
        }), 200
        
    except Exception as e:
        logger.error(f"Purge failed: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({
            "status": "error",
            "error": str(e)
        }), 500


@purge_bp.route("/purge/users", methods=["POST"])
def purge_users_only():
    """
    DANGEROUS: Deletes all users but keeps table structure.
    
    Requires:
    - X-Purge-Token header matching PURGE_TOKEN environment variable
    - confirm=true in request body
    """
    purge_token = os.getenv("PURGE_TOKEN", "NEVER-USE-THIS-DEFAULT")
    provided_token = request.headers.get("X-Purge-Token")
    
    if provided_token != purge_token:
        logger.warning("Purge users attempt with invalid token")
        return jsonify({"error": "Unauthorized"}), 401
    
    data = request.get_json(force=True) or {}
    if data.get("confirm") != True:
        return jsonify({
            "error": "Confirmation required",
            "message": "You must set 'confirm': true in the request body to proceed"
        }), 400
    
    try:
        logger.warning("⚠️ PURGE USERS REQUEST - DELETING ALL USERS")
        
        deleted = User.query.delete()
        db.session.commit()
        
        logger.warning(f"⚠️ PURGED {deleted} users from database")
        
        return jsonify({
            "status": "success",
            "message": f"All users deleted. Deleted {deleted} users.",
            "deleted_users": deleted
        }), 200
        
    except Exception as e:
        logger.error(f"Purge users failed: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({
            "status": "error",
            "error": str(e)
        }), 500


@purge_bp.route("/purge/status", methods=["GET"])
def purge_status():
    """
    Get current database status (user count, etc.)
    """
    try:
        user_count = User.query.count()
        
        return jsonify({
            "user_count": user_count,
            "database": "connected"
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting purge status: {e}", exc_info=True)
        return jsonify({
            "error": str(e)
        }), 500
