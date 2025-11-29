# services/recommendation/preference_utils.py

def sanitize_preferences(prefs: dict) -> dict:
    """Validate & clean user-submitted preference payload."""
    cleaned = {}

    # Allowed vibes for onboarding
    valid_vibes = {
        "study", "free_events", "food", "nightlife", "explore"
    }

    if "preferred_vibes" in prefs:
        cleaned["preferred_vibes"] = [
            v for v in prefs.get("preferred_vibes", [])
            if v in valid_vibes
        ]

    # Budget
    if "budget" in prefs:
        b = prefs["budget"]
        cleaned["budget"] = {
            "min": max(0, int(b.get("min", 0))),
            "max": max(0, int(b.get("max", 999)))
        }

    # Dietary restrictions
    allowed_diets = {
        "vegetarian", "vegan", "halal", "kosher",
        "gluten-free", "dairy-free", "pork-free", "seafood-allergy"
    }

    if "dietary_restrictions" in prefs:
        cleaned["dietary_restrictions"] = [
            d for d in prefs.get("dietary_restrictions", [])
            if d in allowed_diets
        ]

    # Walking distance
    if "max_walk_minutes_default" in prefs:
        cleaned["max_walk_minutes_default"] = max(
            5, min(60, int(prefs["max_walk_minutes_default"]))
        )

    # Free text interests
    if "interests" in prefs:
        cleaned["interests"] = str(prefs["interests"]).strip()

    return cleaned
