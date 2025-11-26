# server/services/vibes.py
from typing import Tuple


# -------------------------------------------------------------
# SIMPLE RULE-BASED VIBE CLASSIFIER
# -------------------------------------------------------------

def classify_vibe(message: str) -> str:
    msg = message.lower().strip()

    fast_words = [
        "quick", "rush", "in a hurry", "10 minutes", "little time",
        "short break", "fast", "grab something fast", "between classes"
    ]

    drink_words = ["drink", "drinks", "bar", "beer", "cocktail", "wine", "pub"]

    party_words = ["party", "club", "clubbing", "dance", "turn up", "lit", "rager"]

    study_words = [
        "study", "homework", "assignment", "quiet", "coffee",
        "study spot", "chill cafe", "laptop friendly"
    ]

    food_words = [
        "eat", "dinner", "lunch", "food", "grab a bite", "restaurant"
    ]

    book_words = ["bookstore", "books", "comic shop", "manga", "library"]

    shopping_words = [
        "shopping", "shop", "stores", "mall", "clothes", "shoes", "jewelry"
    ]

    explore_words = [
        "explore", "walk around", "sightseeing", "landmark", "viewpoint",
        "photos", "pictures", "instagram", "lookout",
        "things to do", "kill time", "something to do"
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


# -------------------------------------------------------------
# MAPPING VIBE → GOOGLE PLACE TYPES + RADIUS
# -------------------------------------------------------------

def vibe_to_place_types(vibe: str) -> Tuple[list, int]:
    if vibe == "fast_bite":
        return ["meal_takeaway", "fast_food", "restaurant"], 600

    if vibe == "chill_drinks":
        return ["bar"], 1500

    if vibe == "party":
        return ["night_club", "bar"], 2000

    if vibe == "study":
        return ["cafe", "library"], 1200

    if vibe == "food_general":
        return ["restaurant", "cafe"], 1500

    if vibe == "bookstore":
        return ["book_store", "library"], 2000

    if vibe == "shopping":
        return [
            "shopping_mall", "clothing_store", "department_store",
            "shoe_store", "jewelry_store"
        ], 2000

    if vibe == "explore":
        return ["tourist_attraction", "point_of_interest"], 2500

    return ["restaurant", "cafe", "tourist_attraction"], 1800


# -------------------------------------------------------------
# NEW — EVENT FILTERING LOGIC
# -------------------------------------------------------------

# These vibes should NOT show events:
PLACE_ONLY_VIBES = {
    "study",
    "fast_bite",
    "chill_drinks",
    "food_general",
    "bookstore",
    "shopping",
    "generic",
}

# These vibes SHOULD include events:
PLACE_AND_EVENT_VIBES = {
    "explore",
    "party",
}

