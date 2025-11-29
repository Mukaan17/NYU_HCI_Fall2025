# services/recommendation/event_filter.py
from datetime import datetime, timedelta

# vibes/messages that should NEVER show events
BLOCK_EVENTS_FOR = [
    "study", "quiet", "coffee", "breakfast", "lunch", "dinner",
    "food", "eat", "restaurant", "fast", "rush"
]


def filter_events(vibe: str, message: str, events: list):
    msg = message.lower()

    # HARD BLOCK — never show events for certain queries
    if any(word in msg for word in BLOCK_EVENTS_FOR):
        return []

    allowed_vibes = ["party", "fun", "explore", "shopping"]

    # STRICT MODE — only events happening right now
    if vibe not in allowed_vibes:
        return [e for e in events if _is_happening_now(e)]

    # OPEN MODE — events happening soon
    return [e for e in events if _is_within_next_few_hours(e)]


# ---------------------------------------------------------------------
# SAFE DATETIME PARSING  (FIXED)
# ---------------------------------------------------------------------
def _parse(event, key):
    """
    Always return datetime or None.
    Accepts ISO, ISO-with-Z, or already-normalized datetime.
    """
    value = event.get(key)
    if not value:
        return None

    # Already a datetime? return safely
    if isinstance(value, datetime):
        return value

    # Handle strings
    if isinstance(value, str):
        try:
            # Remove Z if present
            cleaned = value.replace("Z", "").strip()
            return datetime.fromisoformat(cleaned)
        except:
            return None

    return None


# ---------------------------------------------------------------------
# When is the event REALLY happening?
# ---------------------------------------------------------------------
def _is_happening_now(event):
    start = _parse(event, "start")
    end = _parse(event, "end")

    # Must have both to be “currently happening”
    if not start or not end:
        return False

    now = datetime.now()
    return start <= now <= end


def _is_within_next_few_hours(event):
    start = _parse(event, "start")
    if not start:
        return False

    now = datetime.now()
    soon = now + timedelta(hours=2)

    # Event starts now → 2hrs from now
    return now <= start <= soon
