# routes/calendar_routes.py
# Calendar routes - System calendar only (Google Calendar removed)
from flask import Blueprint, jsonify

calendar_bp = Blueprint("calendar", __name__)

# All Google Calendar-dependent routes have been removed
# The app now uses system calendar only (handled client-side)
