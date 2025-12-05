# services/calendar_suggestion_service.py

from datetime import datetime, timedelta
import pytz
import logging

logger = logging.getLogger(__name__)


# ------------------------------------------------------------
# Normalize calendar event object (works with any calendar format)
# ------------------------------------------------------------
def normalize_event(ev):
    """
    Convert a calendar event dict (from system calendar or any source) into parsed start/end datetimes.
    Missing end → assume +1 hour.
    Works with both system calendar and other calendar formats.
    """
    start_str = ev.get("start")
    end_str = ev.get("end")

    if not start_str:
        return None

    try:
        start = datetime.fromisoformat(start_str)
    except Exception as e:
        logger.debug(f"Failed to parse event start time: {e}")
        return None

    if end_str:
        try:
            end = datetime.fromisoformat(end_str)
        except Exception as e:
            logger.debug(f"Failed to parse event end time, using default: {e}")
            end = start + timedelta(hours=1)
    else:
        end = start + timedelta(hours=1)

    return {"start": start, "end": end}


# ------------------------------------------------------------
# ORIGINAL: compute_next_free_block (used by /next_free)
# ------------------------------------------------------------
def compute_next_free_block(free_blocks):
    """
    free_blocks = [{start: ISO, end: ISO}, ...]

    Returns the block happening now or the next one.
    """

    tz = pytz.timezone("America/New_York")
    now = datetime.now(tz)

    parsed = []
    for b in free_blocks:
        try:
            s = datetime.fromisoformat(b["start"])
            e = datetime.fromisoformat(b["end"])
            parsed.append((s, e))
        except Exception as e:
            logger.debug(f"Failed to parse free block: {e}")
            continue

    if not parsed:
        logger.debug("No valid free blocks found")
        return None

    for (start, end) in parsed:
        if start <= now < end:
            return {"start": start.isoformat(), "end": end.isoformat()}
        if start > now:
            return {"start": start.isoformat(), "end": end.isoformat()}

    return None


# ------------------------------------------------------------
# NEW: find_next_free_block (used in /next_free_block)
# ------------------------------------------------------------
def find_next_free_block(events):
    """
    events = [{start: ISO, end: ISO}, ...]

    Returns the next free block between events.
    """

    tz = pytz.timezone("America/New_York")
    now = datetime.now(tz)

    today_events = []
    for ev in events:
        n = normalize_event(ev)
        if n and n["end"].date() == now.date():
            today_events.append(n)

    today_events.sort(key=lambda x: x["start"])

    if not today_events:
        end_of_day = datetime.combine(now.date(), datetime.max.time()).replace(tzinfo=tz)
        return {
            "start": now.isoformat(),
            "end": end_of_day.isoformat(),
            "duration_minutes": int((end_of_day - now).total_seconds() // 60),
        }

    first = today_events[0]
    if now < first["start"]:
        return {
            "start": now.isoformat(),
            "end": first["start"].isoformat(),
            "duration_minutes": int((first["start"] - now).total_seconds() // 60),
        }

    for i in range(len(today_events) - 1):
        cur = today_events[i]
        nxt = today_events[i + 1]

        gap_start = max(now, cur["end"])
        gap_end = nxt["start"]

        if gap_start < gap_end:
            return {
                "start": gap_start.isoformat(),
                "end": gap_end.isoformat(),
                "duration_minutes": int((gap_end - gap_start).total_seconds() // 60),
            }

    last = today_events[-1]
    gap_start = max(now, last["end"])
    end_of_day = datetime.combine(now.date(), datetime.max.time()).replace(tzinfo=tz)

    if gap_start < end_of_day:
        return {
            "start": gap_start.isoformat(),
            "end": end_of_day.isoformat(),
            "duration_minutes": int((end_of_day - gap_start).total_seconds() // 60),
        }

    return None


# ------------------------------------------------------------
# Build natural-language message
# ------------------------------------------------------------
def build_suggestion_message(block):
    if block is None:
        return "You're fully booked for the rest of today."

    tz = pytz.timezone("America/New_York")
    now = datetime.now(tz)

    try:
        start = datetime.fromisoformat(block["start"])
        end = datetime.fromisoformat(block["end"])
    except Exception as e:
        logger.debug(f"Failed to parse block timestamps: {e}")
        return "Unable to determine free time."

    if start <= now < end:
        return f"You're free until {end.strftime('%-I:%M %p')} — want a quick recommendation?"

    return f"Your next free time starts at {start.strftime('%-I:%M %p')}."

