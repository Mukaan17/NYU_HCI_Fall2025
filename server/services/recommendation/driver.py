# -*- coding: utf-8 -*-
# @Author: Mukhil Sundararaj
# @Date:   2025-12-04 14:08:22
# @Last Modified by:   Mukhil Sundararaj
# @Last Modified time: 2025-12-06 02:26:28
# services/recommendation/driver.py
from __future__ import annotations
import time
import logging
import re
from typing import List, Dict, Any

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
# HELPER: Extract place names from text and match to items
# ---------------------------------------------------------------------
def extract_places_from_reply(
    reply_text: str, 
    items: List[Dict[str, Any]], 
    origin_lat: float | None = None,
    origin_lng: float | None = None
) -> List[Dict[str, Any]]:
    """
    Extract place names mentioned in the LLM reply text and match them to items.
    If a place isn't found in items, search for it using Google Places API.
    Returns a list of matched place items, ordered by how prominently they appear in the reply.
    
    Args:
        reply_text: The LLM-generated reply text
        items: List of items from memory to check first
        origin_lat: User's latitude for distance calculations and location bias
        origin_lng: User's longitude for distance calculations and location bias
    """
    if not reply_text:
        return []
    
    reply_lower = reply_text.lower()
    matched_places = []
    seen_names = set()
    
    # First, try to match places from memory (items)
    if items:
        for item in items:
            name = item.get("name", "")
            if not name:
                continue
            
            name_lower = name.lower()
            
            # Skip if we've already matched this place
            if name_lower in seen_names:
                continue
            
            # Check if the full name appears in the reply (with or without "the")
            name_without_the = name_lower.replace("the ", "").strip()
            if name_lower in reply_lower or name_without_the in reply_lower:
                matched_places.append(item)
                seen_names.add(name_lower)
                continue
            
            # Try matching significant words from the place name
            # Extract words longer than 3 characters (to avoid "the", "of", etc.)
            # Also handle "The X" format
            name_words = [w for w in name_lower.split() if len(w) > 3 and w != "the"]
            
            if not name_words:
                continue
            
            # If at least 2 significant words match, consider it a match
            # This handles cases like "go to Bern Dibner Library" matching "Bern Dibner Library"
            # Or "The Stonewall Inn" matching "Stonewall Inn"
            matched_words = sum(1 for word in name_words if word in reply_lower)
            if matched_words >= 2 or (len(name_words) == 1 and matched_words == 1):
                matched_places.append(item)
                seen_names.add(name_lower)
    
    # Extract potential place names from the reply that weren't found in memory
    # Look for phrases like "go to X", "check out X", "try X", "at X", "from X", etc.
    import re
    place_indicators = [
        r"go to\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\.|,|!|\?|$|;|:|\s+and|\s+or|\s+is|\s+was|\s+has)",
        r"check out\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\.|,|!|\?|$|;|:|\s+and|\s+or|\s+is|\s+was)",
        r"try\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\.|,|!|\?|$|;|:|\s+and|\s+or|\s+is)",
        r"visit\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\.|,|!|\?|$|;|:|\s+and|\s+or|\s+is)",
        r"head to\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\.|,|!|\?|$|;|:|\s+and|\s+or)",
        r"stop by\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\.|,|!|\?|$|;|:|\s+and|\s+or)",
        r"recommend\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\.|,|!|\?|$|;|:|\s+and|\s+or)",
        r"suggest\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\.|,|!|\?|$|;|:|\s+and|\s+or)",
        r"at\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\.|,|!|\?|$|;|:|\s+and|\s+or|\s+\?|\s+is|\s+was|\s+has)",  # "at Artichoke Basille's Pizza"
        r"from\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\.|,|!|\?|$|;|:|\s+and|\s+or)",
        r"grabbing\s+(?:a\s+)?(?:slice|bite|drink|coffee|meal)\s+at\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\.|,|!|\?|$|;|:|\s+and|\s+or)",  # "grabbing a slice at X"
        r"how about\s+(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)(?:\?|\.|,|!|$|;|:|\s+is|\s+was)",  # "How about X?"
        r"(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)\s+is\s+(?:a|an|the)\s+",  # "The Stonewall Inn is a historic spot"
        r"(?:the\s+)?([A-Z][a-zA-Z\s&'\-]+?)\s+is\s+(?:definitely|just|really|perfect|great|good|close|near)",  # "Artichoke Basille's Pizza is definitely a place"
    ]
    
    # Also look for capitalized phrases that might be place names
    # (Place names typically start with capital letters)
    potential_place_names = []
    for pattern in place_indicators:
        matches = re.finditer(pattern, reply_text, re.IGNORECASE)
        for match in matches:
            place_name = match.group(1).strip()
            # Clean up common trailing words
            place_name = re.sub(r'\s+(Pizza|Restaurant|Cafe|Bar|Shop|Store|Place|Inn|Square|Garden|Park)$', '', place_name, flags=re.IGNORECASE)
            # Filter out very short names or common words
            if len(place_name) > 3 and place_name.lower() not in ["the", "a", "an", "this", "that", "it", "there", "here"]:
                potential_place_names.append(place_name)
    
    # Extract capitalized phrases that look like place names
    # Pattern: Sequences of capitalized words (2-5 words, handles apostrophes)
    # This catches "The Stonewall Inn", "Artichoke Basille's Pizza", etc.
    capitalized_pattern = r'\b(?:The\s+)?([A-Z][a-zA-Z]+(?:\'[a-z]+)?(?:\s+[A-Z][a-zA-Z]+(?:\'[a-z]+)?){1,4})\b'
    capitalized_matches = re.finditer(capitalized_pattern, reply_text)
    
    for match in capitalized_matches:
        phrase = match.group(1).strip()
        phrase_lower = phrase.lower()
        
        # Skip if already seen
        if phrase_lower in seen_names:
            continue
        
        # Skip very short phrases
        if len(phrase) < 5:
            continue
        
        # Skip common non-place phrases (locations, common words)
        common_phrases = {
            "new york", "new jersey", "how about", "what about", "just a", "just the",
            "just the", "for a", "for the", "from here", "from there", "close by",
            "near by", "right now", "just now", "a place", "the place", "this place",
            "that place", "some place", "any place", "every place", "no place"
        }
        
        if phrase_lower in common_phrases:
            continue
        
        # Skip if it's just common words (articles, prepositions, etc.)
        # Check if it contains at least one substantial word (4+ chars)
        words = phrase.split()
        substantial_words = [w for w in words if len(w) > 3 and w.lower() not in ["the", "and", "for", "from", "with", "that", "this"]]
        
        if len(substantial_words) < 1:
            continue
        
        # If it appears near place-indicating verbs/adjectives, it's likely a place
        # Check context around the match
        start_pos = match.start()
        end_pos = match.end()
        context_start = max(0, start_pos - 30)
        context_end = min(len(reply_text), end_pos + 30)
        context = reply_text[context_start:context_end].lower()
        
        # Place indicators in context (general patterns, not specific places)
        place_indicators_in_context = [
            "is a", "is an", "is the", "is definitely", "is just", "is really",
            "is perfect", "is great", "is good", "is close", "is near", "is historic",
            "is iconic", "was a", "was an", "at", "from", "to", "near", "close to",
            "walk", "minute", "minutes", "mile", "miles", "distance", "location",
            "spot", "place", "venue", "restaurant", "cafe", "bar", "shop", "store"
        ]
        
        # If the phrase appears near place indicators, it's likely a place name
        is_likely_place = any(indicator in context for indicator in place_indicators_in_context)
        
        # Also check if it follows common place name patterns
        # Place names often end with: Inn, Pizza, Cafe, Bar, Restaurant, Square, Garden, Park, etc.
        place_suffixes = ["inn", "pizza", "cafe", "bar", "restaurant", "square", "garden", 
                          "park", "shop", "store", "place", "spot", "location", "venue",
                          "tavern", "grill", "diner", "bistro", "lounge", "club", "hall",
                          "center", "centre", "plaza", "market", "bakery", "deli"]
        has_place_suffix = any(phrase_lower.endswith(suffix) for suffix in place_suffixes)
        
        # If it has 2+ substantial words, it's more likely to be a place name
        # (single words are less likely to be places unless they have context/suffix)
        if is_likely_place or has_place_suffix or len(substantial_words) >= 2:
            potential_place_names.append(phrase)
    
    # Search for places that weren't found in memory using Google Places API
    # This is the robust validation: if Google Places API finds it, it's a valid place
    if potential_place_names and (origin_lat is not None and origin_lng is not None):
        from services.places_service import search_place_by_name, build_photo_url
        
        # Deduplicate potential place names (case-insensitive)
        unique_place_names = []
        seen_candidates = set()
        for place_name in potential_place_names:
            place_name_lower = place_name.lower().strip()
            if place_name_lower not in seen_candidates and place_name_lower not in seen_names:
                unique_place_names.append(place_name)
                seen_candidates.add(place_name_lower)
        
        # Try to find each potential place via Google Places API
        # The API validation is what makes this robust - no hardcoded checks needed
        for place_name in unique_place_names[:5]:  # Limit to 5 to avoid too many API calls
            place_name_lower = place_name.lower().strip()
            
            # Skip if we already have this place
            if place_name_lower in seen_names:
                continue
            
            try:
                # Search for the place - if Google Places finds it, it's valid
                raw_place = search_place_by_name(place_name, lat=origin_lat, lng=origin_lng)
                
                if raw_place:
                    # Normalize the place
                    geom = raw_place.get("geometry", {}).get("location", {})
                    place_lat = geom.get("lat")
                    place_lng = geom.get("lng")
                    
                    if place_lat and place_lng:
                        # Get accurate directions using Distance Matrix API
                        directions = get_walking_directions(origin_lat, origin_lng, place_lat, place_lng)
                        
                        # Build photo URL
                        photos = raw_place.get("photos", [])
                        photo_ref = photos[0].get("photo_reference") if photos else None
                        photo_url = build_photo_url(photo_ref)
                        
                        # Create normalized place item
                        normalized_place = {
                            "name": raw_place.get("name"),
                            "address": raw_place.get("formatted_address") or raw_place.get("vicinity"),
                            "location": {"lat": place_lat, "lng": place_lng},
                            "walk_time": directions["duration_text"] if directions else None,
                            "distance": directions["distance_text"] if directions else None,
                            "maps_link": directions["maps_link"] if directions else None,
                            "photo_url": photo_url,
                            "rating": raw_place.get("rating", 0),
                            "type": "place",
                            "source": "google_places",
                            "place_id": raw_place.get("place_id"),
                        }
                        
                        matched_places.append(normalized_place)
                        seen_names.add(place_name_lower)
                        logger.debug(f"✅ Found and validated place '{place_name}' via Google Places API")
            except Exception as e:
                logger.debug(f"Error searching for place '{place_name}': {e}")
                continue
    
    # Sort by position in reply (earlier mentions are more relevant)
    def get_first_position(item):
        name = item.get("name", "").lower()
        if name in reply_lower:
            return reply_lower.index(name)
        # If full name not found, find first significant word
        name_words = [w for w in name.split() if len(w) > 3]
        if name_words:
            for word in name_words:
                if word in reply_lower:
                    return reply_lower.index(word)
        return len(reply_lower)  # Put unmatched items at the end
    
    matched_places.sort(key=get_first_position)
    
    return matched_places


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
    # UNLESS the reply mentions a place - then include that place's card
    if intent == "general_chat":
        from services.recommendation.llm_reply import generate_contextual_reply
        memory.add_message("user", message)
        reply = generate_contextual_reply(message, [], memory)
        memory.add_message("assistant", reply)
        
        # Check if reply mentions any places from memory and include their cards
        # Also search for places not in memory
        matched_places = []
        items_to_check = memory.last_places or memory.all_results or []
        # Use user location from memory or function parameters
        origin_lat = (memory.user_location.get("lat") if memory.user_location else None) or user_lat
        origin_lng = (memory.user_location.get("lng") if memory.user_location else None) or user_lng
        matched_places = extract_places_from_reply(reply, items_to_check, origin_lat=origin_lat, origin_lng=origin_lng)
        
        return {
            "debug_vibe": intent,
            "latency": round(time.time() - t0, 2),
            "places": matched_places[:3],  # Include cards if reply mentions places
            "reply": reply,
            "weather": current_weather(),
        }
    
    # If it's a follow-up (place or general), use context-aware response WITHOUT new cards
    # Only treat as follow-up if there's actual conversation history (not a new session)
    # EXCEPTION: If asking about location/where, always return recommendation cards
    location_keywords = ["where is", "where's", "where are", "location of", "location", 
                        "where can i find", "where to find", "show me where", "directions to",
                        "how to get to", "navigate to", "take me to", "go to"]
    is_location_query = any(k in message.lower() for k in location_keywords)
    
    if intent in ["followup_place", "followup_general"] and memory.last_places and memory.history and len(memory.history) > 2 and not is_location_query:
        # User is asking about previous recommendations or context within the same session
        # Return text-only response - don't show cards again for follow-up questions
        # UNLESS the reply mentions a place - then include that place's card
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
        
        # Check if reply mentions any places and include their cards
        # Also search for places not in memory
        matched_places = []
        items_to_check = memory.last_places or memory.all_results or []
        # Use user location from memory or function parameters
        origin_lat = (memory.user_location.get("lat") if memory.user_location else None) or user_lat
        origin_lng = (memory.user_location.get("lng") if memory.user_location else None) or user_lng
        matched_places = extract_places_from_reply(reply, items_to_check, origin_lat=origin_lat, origin_lng=origin_lng)
        
        return {
            "debug_vibe": intent,
            "latency": round(time.time() - t0, 2),
            "places": matched_places[:3],  # Include cards if reply mentions places
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
            normalized_events.append(normalize_event(e, origin_lat=origin_lat, origin_lng=origin_lng))
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
    
    # STEP 13 — Extract places mentioned in the reply (ALWAYS check, even if no initial cards)
    # This ensures places suggested by the LLM (like "Artichoke Basille's Pizza", "The Stonewall Inn") get cards
    places_to_return = []
    
    # First, include items from search results if this is a recommendation
    location_keywords = ["where is", "where's", "where are", "location of", "location", 
                        "where can i find", "where to find", "show me where", "directions to",
                        "how to get to", "navigate to", "take me to", "go to"]
    is_location_query = any(k in message.lower() for k in location_keywords)
    should_show_cards = (intent in ["recommendation", "new_recommendation"] or is_location_query) and len(items) > 0
    
    if should_show_cards:
        places_to_return = items[:3]
    
    # ALWAYS check if reply mentions places (even if no initial cards)
    # This handles cases where LLM suggests a place in conversational responses
    if reply:
        reply_places = extract_places_from_reply(reply, items, origin_lat=origin_lat, origin_lng=origin_lng)
        
        # Add places from reply that aren't already in the return list
        existing_names = {p.get("name", "").lower() for p in places_to_return}
        for place in reply_places:
            place_name = place.get("name", "").lower()
            if place_name and place_name not in existing_names:
                places_to_return.append(place)
                existing_names.add(place_name)
                # Limit to 3 total places
                if len(places_to_return) >= 3:
                    break

    return {
        "debug_vibe": vibe,
        "latency": round(time.time() - t0, 2),
        "places": places_to_return,  # Always include places from reply if mentioned
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
