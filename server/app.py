# server/app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
<<<<<<< HEAD
=======
import os
>>>>>>> main
from dotenv import load_dotenv
import google.generativeai as genai
import os
from services.directions_service import get_walking_directions
from utils.cache import init_requests_cache
from services.recommendation_service import build_chat_response, get_quick_recommendations
from services.nyc_events_service import events_near_bbox  # your existing file name
from utils.chat_memory import ChatMemory

# NYU Tandon-ish coordinates (for events bbox)
TANDON_LAT = 40.6942
TANDON_LNG = -73.9866

app = Flask(__name__)
<<<<<<< HEAD
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Load env + configure external libs
=======
CORS(app)  # Enable CORS for mobile app to connect
>>>>>>> main
load_dotenv()
init_requests_cache()

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))


<<<<<<< HEAD
# ─────────────────────────────────────────────────────────────
# CHAT
# ─────────────────────────────────────────────────────────────
memory = ChatMemory()
=======
Your goals:
1. Recommend nearby food, cafés, events, and activities within walking distance.
2. Consider weather, crowd levels, and time of day.
3. Keep responses short, friendly, and specific.
4. Avoid unrelated topics outside the NYU Tandon area.
5. Prioritize safe, reliable, and student-friendly places.
6. If the user asks for help planning a night, consider their mood & budget.
"""

# --------------------------------------------------------------------------------------
# WEATHER
# --------------------------------------------------------------------------------------
def get_weather_data(lat=None, lon=None):
    # Use provided location or default to NYU Tandon
    if lat is None or lon is None:
        lat, lon = 40.6942, -73.9866
    api_key = os.getenv("OPENWEATHER_API_KEY")

    url = (
        f"https://api.openweathermap.org/data/2.5/weather"
        f"?lat={lat}&lon={lon}&appid={api_key}&units=imperial"
    )

    resp = requests.get(url).json()
    return {
        "temp": resp["main"]["temp"],
        "feels_like": resp["main"]["feels_like"],
        "condition": resp["weather"][0]["main"],
        "description": resp["weather"][0]["description"]
    }

# --------------------------------------------------------------------------------------
# GOOGLE PLACES
# --------------------------------------------------------------------------------------
def fetch_nearby_places(place_type="restaurant", lat=None, lon=None):
    # Use provided location or default to NYU Tandon
    if lat is None or lon is None:
        lat, lon = 40.6942, -73.9866
    api_key = os.getenv("GOOGLE_PLACES_API_KEY")

    url = (
        f"https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        f"?location={lat},{lon}&radius=800&type={place_type}&key={api_key}"
    )

    resp = requests.get(url).json()

    results = []
    for p in resp.get("results", []):
        results.append({
            "name": p["name"],
            "rating": p.get("rating"),
            "open_now": p.get("opening_hours", {}).get("open_now"),
            "location": p["geometry"]["location"],
            "address": p.get("vicinity"),
            "user_ratings_total": p.get("user_ratings_total")
        })

    return results

# --------------------------------------------------------------------------------------
# DIRECTIONS
# --------------------------------------------------------------------------------------
def get_walking_directions(origin_lat, origin_lon, dest_lat, dest_lon):
    api_key = os.getenv("GOOGLE_PLACES_API_KEY")

    url = (
        "https://maps.googleapis.com/maps/api/directions/json"
        f"?origin={origin_lat},{origin_lon}"
        f"&destination={dest_lat},{dest_lon}"
        f"&mode=walking&key={api_key}"
    )

    resp = requests.get(url).json()

    if resp.get("status") != "OK":
        return None

    leg = resp["routes"][0]["legs"][0]

    return {
        "distance": leg["distance"]["text"],
        "duration": leg["duration"]["text"],
        "steps": [s["html_instructions"] for s in leg["steps"]],
        "maps_link": (
            f"https://www.google.com/maps/dir/?api=1"
            f"&origin={origin_lat},{origin_lon}"
            f"&destination={dest_lat},{dest_lon}"
            "&travelmode=walking"
        )
    }

# --------------------------------------------------------------------------------------
# SCRAPING — TimeOut + DowntownBK (works fine)
# --------------------------------------------------------------------------------------
def scrape_timeout_events():
    url = "https://www.timeout.com/newyork/things-to-do"
    resp = requests.get(url)
    soup = BeautifulSoup(resp.text, "html.parser")

    events = []

    cards = soup.select("article")
    for c in cards[:10]:
        title = c.select_one("h3").get_text(strip=True) if c.select_one("h3") else None
        link = "https://www.timeout.com" + c.select_one("a")["href"] if c.select_one("a") else None
        image = c.select_one("img")["src"] if c.select_one("img") else None
        desc = c.select_one("p").get_text(strip=True) if c.select_one("p") else None

        events.append({
            "source": "TimeOut NYC",
            "title": title,
            "description": desc,
            "link": link,
            "image": image
        })

    return events


def scrape_downtownbk_events():
    url = "https://www.downtownbrooklyn.com/events/"
    resp = requests.get(url)
    soup = BeautifulSoup(resp.text, "html.parser")

    events = []

    items = soup.select(".views-row")
    for e in items[:10]:
        title_tag = e.select_one(".node__title a")
        date_tag = e.select_one(".field--name-field-date-range")
        
        if not title_tag:
            continue

        link = "https://www.downtownbrooklyn.com" + title_tag["href"]

        events.append({
            "source": "Downtown Brooklyn",
            "title": title_tag.get_text(strip=True),
            "date": date_tag.get_text(strip=True) if date_tag else None,
            "link": link
        })

    return events

# --------------------------------------------------------------------------------------
# SCRAPING — Brooklyn Library via Puppeteer
# --------------------------------------------------------------------------------------
def scrape_bpl_events_puppeteer():
    """Call Node/Puppeteer script and return JSON."""
    try:
        result = subprocess.run(
            ["node", "scrape_bpl.js"],
            capture_output=True,
            text=True,
            timeout=50
        )

        if result.stderr:
            print("PUPPETEER ERROR:", result.stderr)

        return json.loads(result.stdout)

    except Exception as e:
        return {"error": str(e)}

# --------------------------------------------------------------------------------------
# AI CHAT ENDPOINT
# --------------------------------------------------------------------------------------
LAST_RECOMMENDATION = None
>>>>>>> main

@app.route("/api/chat", methods=["POST"])
def chat():
    try:
        data = request.get_json(force=True) or {}
        user_message = (data.get("message") or "").strip()

<<<<<<< HEAD
        if not user_message:
            return jsonify({"error": "Missing 'message'"}), 400

        # FIX: pass memory into build_chat_response
        print("MEMORY STATE:", memory.history)
        result = build_chat_response(user_message, memory)
        return jsonify(result)
=======
        data = request.get_json()
        user_message = data.get("message", "").lower()
        
        # Get user location from request, or use default NYU Tandon location
        user_lat = data.get("latitude", 40.6942)
        user_lon = data.get("longitude", -73.9866)

        weather = get_weather_data(user_lat, user_lon)

        FAST_TRIGGERS = ["quick", "rush", "10 minutes", "ten minutes", "little time", "short break"]
        fast_mode = any(t in user_message for t in FAST_TRIGGERS)

        if fast_mode:
            places = (
                fetch_nearby_places("meal_takeaway", user_lat, user_lon) +
                fetch_nearby_places("fast_food", user_lat, user_lon) +
                fetch_nearby_places("cafe", user_lat, user_lon)
            )
        else:
            places = fetch_nearby_places("restaurant", user_lat, user_lon)

        places = places[:10]

        enriched = []
        for p in places:
            d = get_walking_directions(
                user_lat, user_lon,
                p["location"]["lat"], p["location"]["lng"]
            )
            enriched.append({
                **p,
                "walk_time": d["duration"] if d else None,
                "distance": d["distance"] if d else None,
                "maps_link": d["maps_link"] if d else None
            })

        enriched = [p for p in enriched if p["open_now"] is True]

        def minutes(place):
            if place["walk_time"] is None:
                return 999
            return int(place["walk_time"].split()[0])

        enriched.sort(key=minutes)

        PRIORITY_PLACES = ["Chipotle", "5 Guys", "Starbucks", "Shake Shack"]

        def score_place(p):
            score = minutes(p)
            if any(name.lower() in p["name"].lower() for name in PRIORITY_PLACES):
                score -= 5
            return score
        
        enriched.sort(key=score_place)

        if LAST_RECOMMENDATION:
            enriched = [p for p in enriched if p["name"] != LAST_RECOMMENDATION] or enriched

        if enriched:
            LAST_RECOMMENDATION = enriched[0]["name"]

        model = genai.GenerativeModel("models/gemini-2.5-flash")

        prompt = {
            "parts": [
                {"text": VIOLET_SYSTEM_PROMPT},
                {"text": f"Current weather: {weather}"},
                {"text": f"Nearby options with walking time: {enriched}"},
                {"text": f"User message: {user_message}"},
                {"text": "Respond as VioletVibes in a short, friendly tone."}
            ]
        }

        response = model.generate_content(prompt)

        # Return both the AI reply and the enriched places data for recommendations
        return jsonify({
            "reply": response.text,
            "recommendations": enriched[:5]  # Return top 5 recommendations
        })
>>>>>>> main

    except Exception as e:
        print("CHAT ERROR:", e)
        return jsonify({"error": "Internal server error"}), 500

# ─────────────────────────────────────────────────────────────
# QUICK ACTION RECOMMENDATIONS
# ─────────────────────────────────────────────────────────────
@app.route("/api/quick_recs", methods=["GET"])
def quick_recs():
    """
    Lightweight, non-chat recommendations for Dashboard Quick Actions.

    Example:
      /api/quick_recs?category=quick_bites
      /api/quick_recs?category=chill_cafes
      /api/quick_recs?category=events
      /api/quick_recs?category=explore
    """
    try:
        category = (request.args.get("category") or "explore").lower()
        result = get_quick_recommendations(category, limit=10)
        return jsonify(result)
    except Exception as e:
        print("QUICK_RECS ERROR:", e)
        return jsonify({"error": "Unable to fetch quick recommendations"}), 500

# ─────────────────────────────────────────────────────────────
# EVENTS
# ─────────────────────────────────────────────────────────────

@app.route("/api/events", methods=["GET"])
def events():
    """
    Example: grab permitted events from NYC Open Data
    within a bounding box around Downtown Brooklyn.
    """
    try:
        lat_min = TANDON_LAT - 0.03
        lat_max = TANDON_LAT + 0.03
        lng_min = TANDON_LNG - 0.03
        lng_max = TANDON_LNG + 0.03

        data = events_near_bbox(lat_min, lat_max, lng_min, lng_max, limit=10)
        return jsonify({"nyc_permitted": data})
    except Exception as e:
        print("EVENTS ERROR:", e)
        return jsonify({"error": "Unable to fetch events"}), 500
    
#--------------------------------
# Directions
#--------------------------------
@app.route("/api/directions", methods=["GET"])
def directions():
    lat = float(request.args.get("lat"))
    lng = float(request.args.get("lng"))

    origin_lat = 40.693393   # 2 MetroTech
    origin_lng = -73.98555

    result = get_walking_directions(origin_lat, origin_lng, lat, lng)

    if not result:
        return jsonify({"error": "Directions failed"}), 500

    return jsonify(result)


# ─────────────────────────────────────────────────────────────
# HEALTH
# ─────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


# ─────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
<<<<<<< HEAD
    # When running directly: python app.py
    app.run(host="0.0.0.0", port=5001, debug=True)
=======
    # Allow connections from mobile devices on the same network
    # Using port 5001 because 5000 is often used by AirPlay Receiver on macOS
    app.run(debug=True, host='0.0.0.0', port=5001)
>>>>>>> main
