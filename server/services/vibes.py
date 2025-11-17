# server/services/vibes.py
from typing import List, Tuple


def classify_vibe(message: str) -> str:
    """
    Very lightweight rule-based vibe classifier.
    Returns one of:
      - 'fast_bite'
      - 'chill_drinks'
      - 'party'
      - 'study'
      - 'food_general'
      - 'bookstore'
      - 'shopping'
      - 'explore'
      - 'generic'
    """
    msg = message.lower()

    fast_words = [
        "quick", "rush", "in a hurry", "hurry",
        "10 minutes", "ten minutes", "little time",
        "short break", "fast", "grab something fast",
        "between classes", "only have"
    ]

    drink_words = [
        "drink", "drinks", "bar", "beer", "cocktail",
        "wine", "pub"
    ]

    party_words = [
        "party", "club", "clubbing", "dance", "dancing",
        "turn up", "lit", "rager"
    ]

    study_words = [
        "study", "study break", "homework", "assignment",
        "chill cafe", "coffee shop", "coffee", "laptop friendly",
        "study spot"
    ]

    food_words = [
        "eat", "dinner", "lunch", "food",
        "grab a bite", "grab food", "restaurant"
    ]

    book_words = [
        "bookstore", "book store", "books", "comic shop",
        "manga", "library"
    ]

    shopping_words = [
        "shopping", "shop", "stores", "store",
        "mall", "clothes", "clothing", "shoe store",
        "sneakers", "jewelry"
    ]

    explore_words = [
        "explore", "walk around", "sightseeing", "sight seeing",
        "landmark", "viewpoint", "view point", "view",
        "photos", "pictures", "instagram", "insta", "lookout",
        "bridge", "things to do", "something to do",
        "kill time", "killing time", "free time", "for 30 minutes",
        "for half an hour"
    ]

    if any(w in msg for w in fast_words):
        return "fast_bite"
    if any(w in msg for w in party_words):
        return "party"
    if any(w in msg for w in drink_words):
        return "chill_drinks"
    if any(w in msg for w in study_words):
        return "study"
    if any(w in msg for w in book_words):
        return "bookstore"
    if any(w in msg for w in shopping_words):
        return "shopping"
    if any(w in msg for w in explore_words):
        return "explore"
    if any(w in msg for w in food_words):
        return "food_general"

    return "generic"


def vibe_to_place_types(vibe: str) -> Tuple[list, int]:
    """
    Map a vibe to:
      - a list of Google Places types
      - search radius in meters
    """
    if vibe == "fast_bite":
        # Very close to campus
        return ["meal_takeaway", "fast_food", "restaurant"], 600

    if vibe == "chill_drinks":
        # Chill bars / pubs, walkable
        return ["bar"], 1500

    if vibe == "party":
        # Louder nightlife
        return ["night_club", "bar"], 2000

    if vibe == "study":
        # Cafés that are laptop-friendly-ish
        return ["cafe"], 1200

    if vibe == "food_general":
        return ["restaurant", "cafe"], 1500

    if vibe == "bookstore":
        # Book shops and similar
        return ["book_store"], 2000

    if vibe == "shopping":
        # General shopping cluster near Fulton/Downtown Brooklyn
        return [
            "shopping_mall",
            "clothing_store",
            "department_store",
            "shoe_store",
            "jewelry_store",
        ], 2000

    if vibe == "explore":
        # Landmarks, viewpoints, photo spots, “things to do”
        return [
            "tourist_attraction",
            "point_of_interest",
        ], 2500

    # generic – lean towards a mix
    return ["restaurant", "cafe", "tourist_attraction"], 1800
