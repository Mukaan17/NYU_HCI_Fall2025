# server/services/recommendation_service.py
from typing import List, Dict, Any

import google.generativeai as genai

from services.weather_service import current_weather
from services.places_service import nearby_places
from services.vibes import classify_vibe, vibe_to_place_types
from services.directions_service import get_walking_directions, walking_minutes

# NYU Tandon-ish coordinates
TANDON_LAT = 40.6942
TANDON_LNG = -73.9866

# Keep a short memory of recent recs to reduce repetition
RECENT_PLACES: List[str] = []  # list of place names
RECENT_LIMIT = 10

VIOLET_SYSTEM_PROMPT = """
You are VioletVibes — an AI concierge designed ONLY for NYU Tandon students
in Downtown Brooklyn. You NEVER answer like a generic assistant.

Core rules:
1. You only recommend places or events that are realistically walkable from NYU Tandon.
2. You keep responses short, friendly, and specific (2–4 sentences).
3. You ALWAYS base your suggestions ONLY on the places and events provided in the context.
   - Do NOT invent new venue names.
   - Do NOT hallucinate addresses or distances.
4. You consider:
   - Weather (cold / hot / raining / nice weather).
   - Time of day (if implied by the user).
   - Vibe and group size when present (e.g., “chill drinks”, “party”, “study break”, “in a rush”).
5. You avoid recommending the exact same place robotically:
   - If multiple places are good, vary your top picks.
6. Safety:
   - Prefer well-lit, busy, student-friendly locations.
   - Avoid sounding like you’re guaranteeing safety; instead say “feels safe” or “popular with students”.

When you answer:
- Mention 1–3 specific places by name.
- Briefly explain why each fits the user’s vibe.
- If appropriate, mention walking time/distance (“~7 min walk”) in a natural way.
"""


# ─────────────────────────────────────────────────────────────
# Busy-ness stub (upgrade later)
# ─────────────────────────────────────────────────────────────

def estimate_busyness(place: Dict[str, Any]) -> Dict[str, Any]:
    """
    Placeholder for real-time crowd data.
    For now, just return neutral values. Later we can plug in
    Google Popular Times or some other signal.
    """
    return {
        "busyness_label": "unknown",
        "busyness_score": 0.0,  # 0 = neutral; positive = crowded; negative = chill
    }


# ─────────────────────────────────────────────────────────────
# Scoring + recency
# ─────────────────────────────────────────────────────────────

def score_place(place: Dict[str, Any], recent_names: List[str]) -> float:
    """
    Compute a score that balances:
      - walk time (shorter is better)
      - rating (higher is better)
      - recency penalty (avoid spamming the same place)
      - busyness (stub for now)
    """
    rating = place.get("rating", 0) or 0
    duration_text = place.get("walk_time")
    mins = walking_minutes(duration_text) if duration_text else 999

    # base score: rating * 2 - minutes / 5  (so 10 extra minutes costs ~2 points)
    base = (rating * 2.0) - (mins / 5.0)

    # recency penalty: if in the last N recs, subtract a bit
    name = (place.get("name") or "").lower()
    recent_lower = [n.lower() for n in recent_names]
    penalty = -2.0 if name in recent_lower else 0.0

    busy_info = estimate_busyness(place)
    busy_score = -busy_info["busyness_score"]  # crowded => negative

    return base + penalty + busy_score


def update_recent_places(chosen: List[Dict[str, Any]]):
    """
    Append chosen place names into RECENT_PLACES, keeping only the last RECENT_LIMIT.
    """
    global RECENT_PLACES
    for p in chosen:
        name = p.get("name")
        if name and name not in RECENT_PLACES:
            RECENT_PLACES.append(name)

    if len(RECENT_PLACES) > RECENT_LIMIT:
        RECENT_PLACES = RECENT_PLACES[-RECENT_LIMIT:]


# ─────────────────────────────────────────────────────────────
# Main orchestration
# ─────────────────────────────────────────────────────────────

def build_chat_response(user_message: str, memory) -> Dict[str, Any]:
    """
    Multi-turn VioletVibes rec engine with:
    - memory awareness
    - recency rotation
    - fallback if user wants "new places"
    """

    # ---------------------------------------------------------
    # 1) Add user message to memory
    # ---------------------------------------------------------
    memory.add_message("user", user_message)

    # Detect "give me something else" intent
    followup_request = any(
        phrase in user_message.lower()
        for phrase in [
            "something else",
            "anything else",
            "new place",
            "new places",
            "more places",
            "been there",
            "i've already been",
            "give me more",
        ]
    )

    # 2) Weather
    try:
        weather = current_weather("Brooklyn,US")
    except Exception:
        weather = None

    # 3) Vibe classification
    vibe = classify_vibe(user_message)

    # 4) Place types + search radius
    place_types, radius = vibe_to_place_types(vibe)

    # ---------------------------------------------------------
    # 5) Pull Google Places candidates
    # ---------------------------------------------------------
    raw = []
    for p_type in place_types:
        try:
            raw.extend(
                nearby_places(
                    lat=TANDON_LAT,
                    lng=TANDON_LNG,
                    place_type=p_type,
                    radius=radius,
                )
            )
        except Exception as e:
            print("Places error:", e)

    # Deduplicate
    dedup = {}
    for p in raw:
        key = p.get("place_id") or p.get("name")
        if key:
            dedup[key] = p

    candidates = list(dedup.values())

    if not candidates:
        fallback = (
            "I’m having trouble pulling live spots, but you could always walk through "
            "MetroTech Commons or head toward Dumbo for something low-key!"
        )
        memory.add_message("assistant", fallback)
        return {"reply": fallback, "places": [], "vibe": vibe, "weather": weather}

    # ---------------------------------------------------------
    # 6) Enrich with walking directions
    # ---------------------------------------------------------
    enriched = []
    for p in candidates:
        geom = p.get("geometry", {}).get("location", {})
        lat, lng = geom.get("lat"), geom.get("lng")
        if lat is None or lng is None:
            continue

        d = get_walking_directions(TANDON_LAT, TANDON_LNG, lat, lng)

        enriched.append({
            "name": p.get("name"),
            "rating": p.get("rating", 0),
            "address": p.get("vicinity"),
            "location": {"lat": lat, "lng": lng},
            "walk_time": d["duration_text"] if d else None,
            "distance": d["distance_text"] if d else None,
            "maps_link": d["maps_link"] if d else None,
        })

    # ---------------------------------------------------------
    # 7) Scoring + optional follow-up rotation
    # ---------------------------------------------------------
    global RECENT_PLACES
    recent_lower = [x.lower() for x in RECENT_PLACES]

    # base scoring
    for p in enriched:
        if p["name"].lower() in recent_lower:
            p["score"] = p["rating"] * 2 - 3     # mild penalty
        else:
            p["score"] = p["rating"] * 2 + 1     # slight boost

    enriched.sort(key=lambda x: x["score"], reverse=True)

    # If user asked "give me something else" → rotate list
    if followup_request:
        enriched = enriched[3:] + enriched[:3]

    # pick top 3
    top = enriched[:3]

    # update recency only with newly selected ones
    update_recent_places(top)

    # ---------------------------------------------------------
    # 8) Build Gemini context
    # ---------------------------------------------------------
    weather_str = (
        f"{weather['temp_f']}°F, {weather['desc']}"
        if weather else "unavailable"
    )

    places_context = "\n".join(
        f"{i+1}. {p['name']} — {p['distance']} (~{p['walk_time']}), {p['address']}"
        for i, p in enumerate(top)
    )

    history = memory.to_formatted_history()

    prompt = f"""
You are VioletVibes, the NYU Tandon campus concierge.

SYSTEM RULES:
- Short, friendly replies (2–4 sentences).
- Use ONLY the provided places.
- Consider weather, vibe, and safety.
- NEVER invent venue names.

Chat History:
{history}

Latest User Message:
"{user_message}"

Weather near Tandon: {weather_str}

Candidate Places:
{places_context}

Respond as VioletVibes.
"""

    model = genai.GenerativeModel("models/gemini-2.5-flash")
    response = model.generate_content(prompt)

    reply_text = getattr(response, "text", "Here's something nearby!")

    memory.add_message("assistant", reply_text)

    return {
        "reply": reply_text,
        "places": top,
        "vibe": vibe,
        "weather": weather,
    }
