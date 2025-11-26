# server/services/recommendation/driver.py

from __future__ import annotations
from typing import List, Dict, Any, Optional
import time

from services.vibes import classify_vibe, vibe_to_place_types, PLACE_ONLY_VIBES, PLACE_AND_EVENT_VIBES
from services.recommendation.events import fetch_all_external_events
from services.recommendation.scoring import score_items_with_embeddings
from services.recommendation.llm_reply import generate_list_reply
from services.directions_service import walking_minutes
from services.places_service import nearby_places
from services.recommendation.context import ConversationContext


# -------------------------------------------------------------
# MAIN CHAT PIPELINE
# -------------------------------------------------------------

def build_chat_response(
    message: str,
    memory: ConversationContext,
    user_profile_text: Optional[str] = None
) -> Dict[str, Any]:

    start_t = time.time()

    # ---------------------------------------------------------
    # 1. Detect vibe from the message
    # ---------------------------------------------------------
    vibe = classify_vibe(message)
    memory.context = vibe

    # ---------------------------------------------------------
    # 2. Get place types + radius for this vibe
    # ---------------------------------------------------------
    place_types, radius = vibe_to_place_types(vibe)

    # ---------------------------------------------------------
    # 3. Fetch Google Places
    # ---------------------------------------------------------
    items: List[Dict[str, Any]] = []
    lat, lng = 40.6942, -73.9866  # Tandon

    for t in place_types:
        try:
            results = nearby_places(lat, lng, place_type=t, radius=radius, limit=12)
            for r in results:
                r["type"] = "place"
                r["source"] = "google_places"
                items.append(r)
        except Exception as e:
            print("Nearby error:", e)

    # ---------------------------------------------------------
    # 4. Add events ONLY if vibe supports events
    # ---------------------------------------------------------
    if vibe in PLACE_AND_EVENT_VIBES:
        try:
            events = fetch_all_external_events(limit=25)
            for ev in events:
                ev["type"] = "event"
                items.append(ev)
        except Exception as e:
            print("Events fetch error:", e)

    # Safety fallback
    if not items:
        return {
            "reply": "I’m having trouble finding places right now — try again!",
            "places": [],
        }

    # ---------------------------------------------------------
    # 5. Score + rerank items
    # ---------------------------------------------------------
    score_items_with_embeddings(
        query_text=message,
        items=items,
        user_profile_text=user_profile_text
    )

    items.sort(key=lambda x: x.get("score", 0), reverse=True)
    top_items = items[:3]

    # ---------------------------------------------------------
    # 6. Build LLM reply
    # ---------------------------------------------------------
    reply = generate_list_reply(message, top_items)

    # ---------------------------------------------------------
    # 7. Update memory
    # ---------------------------------------------------------
    memory.set_places(top_items)
    memory.set_results(items)

    # --------------------------------------------
    # 8. Return response
    # --------------------------------------------
    return {
        "reply": reply,
        "places": top_items,
        "weather": memory.latest_weather if hasattr(memory, "latest_weather") else None,
        "debug_vibe": vibe,
        "latency": round(time.time() - start_t, 2)
    }
