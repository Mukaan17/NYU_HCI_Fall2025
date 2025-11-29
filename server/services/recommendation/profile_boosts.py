# services/recommendation/profile_boosts.py
"""
Applies user profile preferences to item scores.
Preferences ONLY influence results for the relevant vibes.
They never override explicit user intent.
"""

def apply_profile_boosts(items, vibe: str, profile: dict | None):
    if not profile:
        return items

    # Example profile dictionary structure:
    # {
    #   "pref_study": True,
    #   "pref_events": False,
    #   "pref_food": True,
    #   "pref_nightlife": False,
    #   "pref_explore_all": True,
    #   "budget_min": 0,
    #   "budget_max": 20,
    #   "dietary_restrictions": ["vegetarian", "halal"],
    #   "max_walk_minutes_default": 15,
    #   "interests": "photography, fashion"
    # }

    # ----------------------------------------------
    # 1. CATEGORY BOOSTS (light boosts)
    # ----------------------------------------------
    CAT_BOOST = 0.10

    for item in items:
        t = item.get("type")  # "place" or "event"
        name = (item.get("name") or "").lower()

        # --- STUDY / COFFEE / QUIET ---
        if vibe in ("study", "quiet", "coffee"):
            if profile.get("pref_study"):
                # libraries, study lounges, cafés
                if any(k in name for k in ["library", "study", "cafe", "coffee"]):
                    item["score"] = item.get("score", 0) + CAT_BOOST

        # --- FOOD ---
        if vibe in ("food", "eat", "fast", "lunch", "dinner", "breakfast"):
            if profile.get("pref_food"):
                # restaurants, fast food, cafés
                if any(k in name for k in ["restaurant", "grill", "diner", "food", "express"]):
                    item["score"] = item.get("score", 0) + CAT_BOOST

        # --- NIGHTLIFE / PARTY ---
        if vibe in ("party", "fun", "nightlife"):
            if profile.get("pref_nightlife"):
                if any(k in name for k in ["bar", "club", "lounge", "social"]):
                    item["score"] = item.get("score", 0) + CAT_BOOST

        # --- EXPLORE / EVENTS ---
        if vibe == "explore":
            if profile.get("pref_events") and t == "event":
                item["score"] = item.get("score", 0) + CAT_BOOST

    # ----------------------------------------------
    # 2. WALKING DISTANCE PREFERENCE
    # ----------------------------------------------
    max_walk = profile.get("max_walk_minutes_default")
    if max_walk:
        for item in items:
            walk = item.get("walk_time")
            if walk and isinstance(walk, int):
                if walk > max_walk:
                    # small penalty, not a block
                    item["score"] -= 0.10

    # ----------------------------------------------
    # 3. DIETARY RESTRICTIONS (FOOD ONLY)
    # ----------------------------------------------
    restrictions = profile.get("dietary_restrictions") or []
    restrictions = [r.lower().strip() for r in restrictions]

    if restrictions and vibe in ("food", "eat", "breakfast", "lunch", "dinner", "fast"):
        for item in items:
            desc = (item.get("description") or "").lower()

            # Penalize restaurants not matching dietary safe terms
            if "vegan" in restrictions and "vegan" not in desc:
                item["score"] -= 0.20
            if "vegetarian" in restrictions and "vegetarian" not in desc:
                item["score"] -= 0.15
            if "halal" in restrictions and "halal" not in desc:
                item["score"] -= 0.15

    # ----------------------------------------------
    # 4. INTERESTS (semantic boost for explore vibe)
    # ----------------------------------------------
    interests = (profile.get("interests") or "").lower()
    if interests and vibe == "explore":
        for item in items:
            if any(word in (item.get("description") or "").lower() for word in interests.split(",")):
                item["score"] += 0.10

    return items
