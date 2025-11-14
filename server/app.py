from flask import Flask, request, jsonify
import os
from dotenv import load_dotenv
import google.generativeai as genai
import subprocess
import json
import requests
import datetime
from bs4 import BeautifulSoup

app = Flask(__name__)
load_dotenv()

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

VIOLET_SYSTEM_PROMPT = """
You are VioletVibes — an AI concierge designed ONLY for NYU Tandon students
in Downtown Brooklyn. You never answer like a generic assistant.

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
def get_weather_data():
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
def fetch_nearby_places(place_type="restaurant"):
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

@app.route("/api/chat", methods=["POST"])
def chat():
    try:
        global LAST_RECOMMENDATION

        data = request.get_json()
        user_message = data.get("message", "").lower()

        weather = get_weather_data()

        FAST_TRIGGERS = ["quick", "rush", "10 minutes", "ten minutes", "little time", "short break"]
        fast_mode = any(t in user_message for t in FAST_TRIGGERS)

        if fast_mode:
            places = (
                fetch_nearby_places("meal_takeaway") +
                fetch_nearby_places("fast_food") +
                fetch_nearby_places("cafe")
            )
        else:
            places = fetch_nearby_places("restaurant")

        places = places[:10]

        enriched = []
        for p in places:
            d = get_walking_directions(
                40.6942, -73.9866,
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

        return jsonify({"reply": response.text})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --------------------------------------------------------------------------------------
# EVENTS API — Now uses Puppeteer for BPL
# --------------------------------------------------------------------------------------
@app.route("/api/events", methods=["GET"])
def events():
    return jsonify({
        "timeout": scrape_timeout_events(),
        "downtown_bk": scrape_downtownbk_events(),
        "bpl": scrape_bpl_events_puppeteer()
    })

# --------------------------------------------------------------------------------------
# RUN SERVER
# --------------------------------------------------------------------------------------
if __name__ == "__main__":
    app.run(debug=True)
