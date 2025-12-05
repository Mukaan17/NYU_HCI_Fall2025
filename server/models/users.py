from models.db import db
from datetime import datetime
import json
import logging
from utils.encryption import encrypt_data, decrypt_data

logger = logging.getLogger(__name__)

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    
    # User profile data
    first_name = db.Column(db.String(100), nullable=True)  # User's first name
    home_address_encrypted = db.Column(db.Text, nullable=True)  # Encrypted home address

    # Flexible JSON blobs
    preferences = db.Column(db.Text, default='{}')   # e.g. vibes, distance, etc.
    settings = db.Column(db.Text, default='{}')      # e.g. notification toggles
    recent_activity = db.Column(db.Text, default='[]')  # list of actions

    notification_token = db.Column(db.String(255), nullable=True)
    google_refresh_token = db.Column(db.String(255), nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Helpers for JSON fields
    def get_preferences(self):
        try:
            return json.loads(self.preferences or "{}")
        except Exception:
            return {}

    def set_preferences(self, prefs: dict):
        self.preferences = json.dumps(prefs or {})

    def get_settings(self):
        try:
            return json.loads(self.settings or "{}")
        except Exception:
            return {}

    def set_settings(self, settings: dict):
        self.settings = json.dumps(settings or {})

    def get_recent_activity(self):
        try:
            return json.loads(self.recent_activity or "[]")
        except Exception:
            return []

    def add_activity(self, activity: dict):
        log = self.get_recent_activity()
        log.append(activity)
        # keep last 100 actions max
        log = log[-100:]
        self.recent_activity = json.dumps(log)

    def get_profile_text(self):
        """
        Converts stored preferences into a natural-language blurb
        used to influence embeddings.
        """
        prefs = self.get_preferences()

        parts = []

        vibes = prefs.get("preferred_vibes", [])
        if vibes:
            parts.append("User enjoys: " + ", ".join(vibes))

        diets = prefs.get("dietary_restrictions", [])
        if diets:
            parts.append("Diet: " + ", ".join(diets))

        dist = prefs.get("max_walk_minutes_default")
        if dist:
            parts.append(f"Prefers walking under {dist} minutes")

        interests = prefs.get("interests")
        if interests:
            parts.append(f"Interests include: {interests}")

        return ". ".join(parts)
    
    # Home address encryption/decryption
    def get_home_address(self) -> str:
        """Get decrypted home address."""
        # Handle case where column doesn't exist yet (graceful migration)
        if not hasattr(self, 'home_address_encrypted') or not self.home_address_encrypted:
            return ""
        try:
            return decrypt_data(self.home_address_encrypted)
        except Exception as e:
            logger.warning(f"Failed to decrypt home address for user {self.id}: {e}")
            return ""
    
    def set_home_address(self, address: str):
        """Set encrypted home address."""
        # Handle case where column doesn't exist yet (graceful migration)
        if not hasattr(self, 'home_address_encrypted'):
            logger.warning(f"home_address_encrypted column not found - migration may be needed")
            return  # Skip if column doesn't exist
        
        if address:
            try:
                self.home_address_encrypted = encrypt_data(address)
            except Exception as e:
                logger.error(f"Failed to encrypt home address for user {self.id}: {e}")
                raise
        else:
            self.home_address_encrypted = None

