import os
from flask import Flask, jsonify, request
from dotenv import load_dotenv
from utils.cache import init_requests_cache
from services.weather_service import current_weather
from services.places_service import nearby_places
from services.nyc_events_service import events_near_bbox
from openai import OpenAI

load_dotenv()
init_requests_cache()
app = Flask(__name__)
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
DEFAULT_LAT = float(os.environ.get("DEFAULT_LAT", 40.7033))
DEFAULT_LNG = float(os.environ.get("DEFAULT_LNG", -73.9881))

@app.get("/")
def root():
    return jsonify({"status": "NYightOut backend running"})

@app.get("/api/recommendations")
def recommendations():
    mood = request.args.get("mood", "chill")
    lat = float(request.args.get("lat", DEFAULT_LAT))
    lng = float(request.args.get("lng", DEFAULT_LNG))

    wx = current_weather("Brooklyn,US")
    places = nearby_places(lat, lng, place_type="bar" if mood == "chill" else "restaurant")
    events = events_near_bbox(lat-0.01, lat+0.01, lng-0.015, lng+0.015, 3)

    return jsonify({"weather": wx, "places": places[:3], "events": events})

@app.post("/api/chat")
def chat():
    data = request.get_json()
    mood = data.get("mood", "chill")
    wx = current_weather("Brooklyn,US")
    places = nearby_places(DEFAULT_LAT, DEFAULT_LNG, place_type="bar")
    events = events_near_bbox(DEFAULT_LAT-0.01, DEFAULT_LAT+0.01, DEFAULT_LNG-0.015, DEFAULT_LNG+0.015, 2)

    prompt = f"""
Weather: {wx['desc']} {wx['temp_f']}°F
Nearby spots:
{[p['name'] for p in places]}
Events: {[e.get('event_name','Unknown') for e in events]}
Suggest a {mood} night out plan in DUMBO for a college student.
"""
    try:
        resp = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role":"user","content":prompt}]
        )
        return jsonify({"reply": resp.choices[0].message.content})
    except Exception as e:
        return jsonify({"error": str(e)})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
