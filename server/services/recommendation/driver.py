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

# NYU Campus Locations
TANDON_LAT = 40.6942
TANDON_LNG = -73.9866
WASHINGTON_SQUARE_LAT = 40.7298
WASHINGTON_SQUARE_LNG = -73.9973


# ---------------------------------------------------------------------
# MAIN RESPONSE ENTRY
# ---------------------------------------------------------------------
def build_chat_response(
    message: str,
    memory: ConversationContext,
    user_profile=None,
    user_lat: float = None,
    user_lng: float = None,
    selected_vibe: str = None,
    commute_preference: str = None,
):
    """
    Build chat response with recommendations.
    
    Args:
        message: User's message
        memory: Conversation context
        user_profile: User preferences dict
        user_lat: User's current latitude (optional)
        user_lng: User's current longitude (optional)
        selected_vibe: Selected vibe from vibe picker (optional)
        commute_preference: Commute preference ("walking", "transit", "both") (optional)
    """
    user_profile = user_profile or {}
    t0 = time.time()
    
    # Determine origin location based on user location or preference
    # If user is near Washington Square, use that; otherwise default to Tandon
    origin_lat = TANDON_LAT
    origin_lng = TANDON_LNG
    campus_name = "Tandon"
    
    if user_lat and user_lng:
        # Calculate distance to both campuses
        import math
        
        def haversine_distance(lat1, lon1, lat2, lon2):
            """Calculate distance between two points in km"""
            R = 6371  # Earth radius in km
            dlat = math.radians(lat2 - lat1)
            dlon = math.radians(lon2 - lon1)
            a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
            c = 2 * math.asin(math.sqrt(a))
            return R * c
        
        dist_to_tandon = haversine_distance(user_lat, user_lng, TANDON_LAT, TANDON_LNG)
        dist_to_washington = haversine_distance(user_lat, user_lng, WASHINGTON_SQUARE_LAT, WASHINGTON_SQUARE_LNG)
        
        # Use the closer campus, or Washington Square if within reasonable distance
        if dist_to_washington < dist_to_tandon or dist_to_washington < 2.0:  # Within 2km of Washington Square
            origin_lat = WASHINGTON_SQUARE_LAT
            origin_lng = WASHINGTON_SQUARE_LNG
            campus_name = "Washington Square"
        else:
            origin_lat = TANDON_LAT
            origin_lng = TANDON_LNG
            campus_name = "Tandon"
    
    # Store origin in memory for context
    memory.user_location = {
        "lat": origin_lat,
        "lng": origin_lng,
        "campus": campus_name
    }

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
    # Only treat as follow-up if there's actual conversation history (not a new session)
    if intent in ["followup_place", "followup_general"] and memory.last_places and memory.history and len(memory.history) > 2:
        # User is asking about previous recommendations or context within the same session
        # Return text-only response - don't show cards again for follow-up questions
        from services.recommendation.llm_reply import generate_contextual_reply
        memory.add_message("user", message)
        reply = generate_contextual_reply(
            message, [], memory,
            user_location=memory.user_location,
            user_profile=user_profile,
            selected_vibe=selected_vibe,
            commute_preference=commute_preference
        )
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

    # STEP 1 — classify user vibe (use selected vibe if provided, otherwise classify from message)
    if selected_vibe:
        vibe = selected_vibe
    else:
        vibe = classify_vibe(message)
    place_types, radius = vibe_to_place_types(vibe)
    
    # Adjust radius based on commute preference
    if commute_preference == "transit":
        # Allow larger radius for transit users
        radius = min(radius * 2, 5000)  # Max 5km for transit
    elif commute_preference == "walking":
        # Keep walking radius (already set by vibe)
        pass
    # "both" or None: use default radius

    # STEP 2 — Load static events (safe if file missing)
    events = fetch_all_external_events()

    # STEP 3 — Filter appropriate events based on vibe + message
    filtered_events = filter_events(vibe, message, events)

    # STEP 4 — Query nearby places (OPEN NOW) from user's origin location
    raw_places = []
    for t in place_types:
        try:
            raw_places.extend(
                nearby_places(
                    lat=origin_lat,
                    lng=origin_lng,
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
            # Get directions from user's origin location
            if commute_preference == "transit":
                # For transit preference, get transit directions
                directions = get_walking_directions(origin_lat, origin_lng, lat, lng)  # This already tries transit
            else:
                # For walking or both, get walking directions
                directions = get_walking_directions(origin_lat, origin_lng, lat, lng)
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
        reply = generate_contextual_reply(
            message, [], memory,
            user_location=memory.user_location,
            user_profile=user_profile,
            selected_vibe=selected_vibe,
            commute_preference=commute_preference
        )
        
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
            reply = generate_contextual_reply(
                message, [], memory,
                user_location=memory.user_location,
                user_profile=user_profile,
                selected_vibe=selected_vibe,
                commute_preference=commute_preference
            )
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
    
    # STEP 11 — Build surface reply with context (include location, preferences, vibe)
    reply = build_surface_reply(
        message, 
        items, 
        memory,
        user_location=memory.user_location,
        user_profile=user_profile,
        selected_vibe=selected_vibe,
        commute_preference=commute_preference
    )
    
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
def build_surface_reply(
    user_msg: str, 
    items: list, 
    memory: ConversationContext = None,
    user_location: dict = None,
    user_profile: dict = None,
    selected_vibe: str = None,
    commute_preference: str = None
):
    """
    Build a natural, context-aware reply using LLM.
    Removes repetitive greetings and maintains conversation flow.
    
    Args:
        user_msg: User's message
        items: List of recommendation items
        memory: Conversation context
        user_location: User's location dict with lat, lng, campus
        user_profile: User preferences dict
        selected_vibe: Selected vibe from vibe picker
        commute_preference: Commute preference ("walking", "transit", "both")
    """
    from services.recommendation.llm_reply import generate_list_reply, generate_contextual_reply
    
    if not items:
        # Use LLM for empty results too, with context awareness
        if memory and memory.history:
            # Follow-up context - acknowledge previous conversation
            return generate_contextual_reply(
                user_msg, [], memory,
                user_location=user_location,
                user_profile=user_profile,
                selected_vibe=selected_vibe,
                commute_preference=commute_preference
            )
        return "I couldn't find anything nearby right now. Try asking for something different!"

    # Use LLM to generate natural, context-aware replies
    # Include conversation history for better follow-up handling
    if memory and memory.history:
        # Use contextual LLM reply that considers previous messages
        return generate_contextual_reply(
            user_msg, items[:3], memory,
            user_location=user_location,
            user_profile=user_profile,
            selected_vibe=selected_vibe,
            commute_preference=commute_preference
        )
    else:
        # First message - use standard LLM reply
        return generate_list_reply(
            user_msg, items[:3],
            user_location=user_location,
            user_profile=user_profile,
            selected_vibe=selected_vibe,
            commute_preference=commute_preference
        )
