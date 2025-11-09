import json
import os
from flask import Flask, jsonify, send_from_directory, request
from datetime import datetime, date
from dotenv import load_dotenv # New Import

# Load environment variables from .env file
load_dotenv()

# --- CONFIGURATION & INITIALIZATION ---

app = Flask(__name__, static_folder='.', static_url_path='')

# IMPORTANT: Load sensitive keys from environment variables.
# These variables must be set in a local .env file (which is excluded from Git).
GOOGLE_PLACES_API_KEY = os.environ.get("GOOGLE_PLACES_API_KEY", "MOCK_KEY_FOR_LOCAL_RUNNING")
# FIREBASE_CONFIG = os.environ.get("FIREBASE_CONFIG") # We don't need this in Flask as it's only used client-side

# Mock student calendar structure (24-hour format)
MOCK_SCHEDULE = [
    {"day": 4, "start": 900, "end": 1030, "event": "HCI Class", "location": "Rogers Hall 101"},
    {"day": 4, "start": 1030, "end": 1100, "event": "Downtime Slot 1", "location": "NYU Tandon Library"},
    {"day": 4, "start": 1100, "end": 1230, "event": "Systems Lecture", "location": "Wunsch Building B302"},
    {"day": 4, "start": 1230, "end": 1400, "event": "Downtime Slot 2", "location": "Wunsch Building Exit"},
    {"day": 4, "start": 1400, "end": 1600, "event": "Lab Session", "location": "2 Metrotech Center Lab"},
    {"day": 4, "start": 1600, "end": 1700, "event": "Downtime Slot 3", "location": "Home Bound"},
]

# --- SECURE SERVER LOGIC FUNCTIONS ---

def determine_downtime_status():
    """
    Simulates fetching and analyzing Google Calendar data on the server.
    """
    # NOTE: We force time to be Thursday at 10:45 AM (1045) to hit the Downtime Slot 1
    mock_day = 4  # Thursday
    mock_time = 1045

    # In a real app, this would use the current datetime:
    # now = datetime.now()
    # current_day = now.weekday() # Monday 0 - Sunday 6 (Python)
    # current_time = now.hour * 100 + now.minute
    
    current_event = next(
        (e for e in MOCK_SCHEDULE if e["day"] == mock_day and e["start"] <= mock_time and e["end"] > mock_time),
        None
    )

    if current_event and "Downtime" in current_event["event"]:
        return {
            "is_downtime": True,
            "event": current_event["event"],
            "location": current_event["location"],
            "until": current_event["end"],
            "current_time": mock_time,
        }
    else:
        # Returns status for a class/lab or general free time
        return {
            "is_downtime": False,
            "event": current_event["event"] if current_event else "Free Block",
            "location": current_event["location"] if current_event else "Unknown",
            "until": current_event["end"] if current_event else 2400,
            "current_time": mock_time,
        }

def get_live_recommendations(status):
    """
    Simulates secure call to Google Places API (Busyness/POI data) 
    and filtering based on calendar status.
    """
    if not status["is_downtime"]:
        return []

    # In a real scenario, we'd use the GOOGLE_PLACES_API_KEY here to check busyness.
    # For now, we return the client-side mock list, but this is where the 
    # crucial filtering and API calls happen securely.

    return [
        {"name": "Coffee Lab", "type": "Coffee", "time": "morning/noon", "vibe": "Quick break, great views", "walk": "5 min", "busyness": "Medium"},
        {"name": "Brooklyn Bridge Park", "type": "Outdoor", "time": "afternoon/evening", "vibe": "Relaxing walk, photo op", "walk": "10 min", "busyness": "Low"},
        {"name": "The Book Nook", "type": "Study/Chill", "time": "any", "vibe": "Quiet, good for reading", "walk": "3 min", "busyness": "Low"}
    ]

# --- FLASK ROUTES (API Endpoints) ---

@app.route('/')
def serve_index():
    """Serves the main HTML file."""
    # This assumes index.html is in the same directory as app.py
    return send_from_directory('.', 'index.html')

@app.route('/<path:filename>')
def serve_static(filename):
    """Serves other static files like app.js and style.css."""
    return send_from_directory('.', filename)

@app.route('/api/status', methods=['GET'])
def get_concierge_status():
    """
    The secure backend endpoint that performs all external API logic (mocked here).
    The client will call this instead of talking to Google services directly.
    """
    try:
        # 1. Check Calendar Status (securely)
        status = determine_downtime_status()

        # 2. Get Recommendations (securely fetching live busyness)
        recommendations = get_live_recommendations(status)

        # 3. Combine results and send back to the client
        return jsonify({
            "status": status,
            "recommendations": recommendations,
            "message": f"Status fetched using API Key: {GOOGLE_PLACES_API_KEY[:4]}..."
        })
    except Exception as e:
        app.logger.error(f"Error processing status request: {e}")
        return jsonify({"error": "Server failed to process the request."}), 500

# --- RUN SERVER ---

if __name__ == '__main__':
    # Running in debug mode for development
    # In production, use a WSGI server like Gunicorn
    print("Flask server running at http://127.0.0.1:5000/")
    # If the API key is the mock key, remind the user.
    if GOOGLE_PLACES_API_KEY == "MOCK_KEY_FOR_LOCAL_RUNNING":
        print("WARNING: Using MOCK_KEY for API. Remember to set GOOGLE_PLACES_API_KEY in your .env file.")
    app.run(debug=True)
