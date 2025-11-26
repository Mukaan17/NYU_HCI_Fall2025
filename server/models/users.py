from models.db import db
from datetime import datetime
import json

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)

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
