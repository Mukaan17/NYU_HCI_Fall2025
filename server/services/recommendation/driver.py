# services/recommendation/driver.py
from __future__ import annotations
import time
import logging

from services.vibes import classify_vibe, vibe_to_place_types
from services.recommendation.scoring import score_items_with_embeddings
from services.recommendation.event_filter import filter_events
from services.recommendation.events import fetch_all_external_events
from services.recommendation.context import ConversationContext
from services.recommendation.places import normalize_place
from services.recommendation.event_normalizer import normalize_event

from services.places_service import nearby_places
from services.directions_service import get_walking_directions
from services.weather_service import current_weather

logger = logging.getLogger(__name__)

TANDON_LAT = 40.6942
TANDON_LNG = -73.9866


# ---------------------------------------------------------------------
# MAIN RESPONSE ENTRY
# ---------------------------------------------------------------------
def build_chat_response(
    message: str,
    memory: ConversationContext,
    user_profile=None,
):
    user_profile = user_profile or {}
    t0 = time.time()

    # STEP 0 — Check if this is a follow-up question about previous results
    from services.recommendation.intent import classify_intent_llm
    intent = classify_intent_llm(message, memory)
    
    # If it's general chat (greetings, thanks), return text-only response without cards
    if intent == "general_chat":
        from services.recommendation.llm_reply import generate_contextual_reply
        memory.add_message("user", message)
        reply = generate_contextual_reply(message, [], memory)
        memory.add_message("assistant", reply)
        return {
            "debug_vibe": intent,
            "latency": round(time.time() - t0, 2),
            "places": [],  # No cards for conversational messages
            "reply": reply,
            "weather": current_weather(),
        }
    
    # If it's a follow-up (place or general), use context-aware response WITHOUT new cards
    if intent in ["followup_place", "followup_general"] and memory.last_places:
        # User is asking about previous recommendations or context
        # Return text-only response - don't show cards again for follow-up questions
        from services.recommendation.llm_reply import generate_contextual_reply
        memory.add_message("user", message)
        reply = generate_contextual_reply(message, [], memory)  # Pass empty items to avoid showing cards
        memory.add_message("assistant", reply)
        return {
            "debug_vibe": intent,
            "latency": round(time.time() - t0, 2),
            "places": [],  # No cards for follow-up questions
            "reply": reply,
            "weather": current_weather(),
        }
    
    # If it's a request for new recommendations (alternatives), do a new search
    # This will return new cards with different results
    if intent == "new_recommendation" and memory.all_results:
        # User wants alternatives - exclude previously shown places
        previous_names = {p.get("name", "").lower() for p in memory.last_places}
        # This will be handled in the scoring/filtering step

    # STEP 1 — classify user vibe
    vibe = classify_vibe(message)
    place_types, radius = vibe_to_place_types(vibe)

    # STEP 2 — Load static events (safe if file missing)
    events = fetch_all_external_events()

    # STEP 3 — Filter appropriate events based on vibe + message
    filtered_events = filter_events(vibe, message, events)

    # STEP 4 — Query nearby places (OPEN NOW)
    raw_places = []
    for t in place_types:
        try:
            raw_places.extend(
                nearby_places(
                    lat=TANDON_LAT,
                    lng=TANDON_LNG,
                    place_type=t,
                    radius=radius,
                    open_now=True,
                )
            )
        except Exception as e:
            logger.warning(f"Error fetching nearby places for type {t}: {e}")

    # STEP 5 — Normalize places into unified cards
    seen = set()
    final_places = []

    for p in raw_places:
        key = p.get("place_id") or p.get("name")
        if key in seen:
            continue
        seen.add(key)

        loc = p.get("geometry", {}).get("location", {})
        lat = loc.get("lat")
        lng = loc.get("lng")
        if lat is None or lng is None:
            continue

        try:
            directions = get_walking_directions(TANDON_LAT, TANDON_LNG, lat, lng)
        except Exception:
            directions = None

        final_places.append(normalize_place(p, directions))

    # STEP 6 — Normalize events
    normalized_events = []
    for e in filtered_events:
        try:
            normalized_events.append(normalize_event(e))
        except Exception as ex:
            logger.warning(f"EVENT NORMALIZATION ERROR: {ex}")

    # STEP 7 — Combine places + events
    items = final_places + normalized_events

    # STEP 7.5 — Handle empty results with context-aware reply (no cards)
    if not items:
        # Add user message to history
        memory.add_message("user", message)
        
        # Generate context-aware empty response
        from services.recommendation.llm_reply import generate_contextual_reply
        reply = generate_contextual_reply(message, [], memory)
        
        # Add assistant reply to history
        memory.add_message("assistant", reply)
        
        return {
            "debug_vibe": vibe,
            "latency": round(time.time() - t0, 2),
            "places": [],  # No cards when no results found
            "reply": reply,
            "weather": current_weather(),
        }

    # STEP 8 — Score with query + profile + vibe
    score_items_with_embeddings(
        query_text=message,
        items=items,
        profile=user_profile,
    )

    # STEP 9 — Sort
    items.sort(key=lambda x: x.get("score", 0), reverse=True)
    
    # STEP 9.5 — Filter out previously shown places for "new_recommendation" intent
    if intent == "new_recommendation" and memory.last_places:
        previous_names = {p.get("name", "").lower() for p in memory.last_places}
        items = [item for item in items if item.get("name", "").lower() not in previous_names]
        
        # If all items were filtered out, return empty response
        if not items:
            memory.add_message("user", message)
            from services.recommendation.llm_reply import generate_contextual_reply
            reply = generate_contextual_reply(message, [], memory)
            memory.add_message("assistant", reply)
            return {
                "debug_vibe": vibe,
                "latency": round(time.time() - t0, 2),
                "places": [],  # No new alternatives found
                "reply": reply,
                "weather": current_weather(),
            }

    # Update memory with top results (for future follow-ups if needed)
    memory.set_places(items[:3])
    memory.set_results(items)

    # STEP 10 — Add current message to history for context
    memory.add_message("user", message)
    
    # STEP 11 — Build surface reply with context
    reply = build_surface_reply(message, items, memory)
    
    # STEP 12 — Add assistant reply to history
    memory.add_message("assistant", reply)
    
    # STEP 13 — Only return cards if this is an actual recommendation request
    # Don't show cards for conversational messages or follow-ups
    should_show_cards = intent in ["recommendation", "new_recommendation"] and len(items) > 0

    return {
        "debug_vibe": vibe,
        "latency": round(time.time() - t0, 2),
        "places": items[:3] if should_show_cards else [],  # Only show cards for actual recommendations
        "reply": reply,
        "weather": current_weather(),
    }


# ---------------------------------------------------------------------
# SURFACE REPLY
# ---------------------------------------------------------------------
def build_surface_reply(user_msg: str, items: list, memory: ConversationContext = None):
    """
    Build a natural, context-aware reply using LLM.
    Removes repetitive greetings and maintains conversation flow.
    """
    from services.recommendation.llm_reply import generate_list_reply, generate_contextual_reply
    
    if not items:
        # Use LLM for empty results too, with context awareness
        if memory and memory.history:
            # Follow-up context - acknowledge previous conversation
            return generate_contextual_reply(user_msg, [], memory)
        return "I couldn't find anything nearby right now. Try asking for something different!"

    # Use LLM to generate natural, context-aware replies
    # Include conversation history for better follow-up handling
    if memory and memory.history:
        # Use contextual LLM reply that considers previous messages
        return generate_contextual_reply(user_msg, items[:3], memory)
    else:
        # First message - use standard LLM reply
        return generate_list_reply(user_msg, items[:3])
