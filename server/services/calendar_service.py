# services/calendar_service.py

import requests
from datetime import datetime, timedelta
import pytz
import logging

logger = logging.getLogger(__name__)


# ------------------------------------------------------------
# GOOGLE OAUTH: REFRESH ACCESS TOKEN
# ------------------------------------------------------------
def refresh_access_token(refresh_token, client_id, client_secret):
    """
    Exchange refresh token for a new access token.
    """
    url = "https://oauth2.googleapis.com/token"
    data = {
        "refresh_token": refresh_token,
        "client_id": client_id,
        "client_secret": client_secret,
        "grant_type": "refresh_token",
    }

    resp = requests.post(url, data=data).json()

    if "access_token" not in resp:
        logger.error(f"Google OAuth refresh failed: {resp}")
        raise Exception(f"Google OAuth refresh failed: {resp}")

    return resp["access_token"]


# ------------------------------------------------------------
# HELPER: PARSE ISO TIME (Google returns microseconds sometimes)
# ------------------------------------------------------------
def parse_google_datetime(dt_str):
    """
    Safely parses Google Calendar RFC3339/ISO datetime strings.
    Handles timezone offsets and microseconds.
    """
    try:
        return datetime.fromisoformat(dt_str)
    except ValueError:
        # e.g. "2025-02-11T13:00:00-05:00"
        try:
            return datetime.strptime(dt_str, "%Y-%m-%dT%H:%M:%S%z")
        except Exception:
            logger.warning(f"Failed parsing datetime: {dt_str}")
            return None


# ------------------------------------------------------------
# FETCH TODAY'S EVENTS
# ------------------------------------------------------------
def fetch_today_events(refresh_token, client_id, client_secret):
    """
    Returns a list of today's Google Calendar events:
    [
      {id, name, start, end, location}
    ]
    """

    access_token = refresh_access_token(refresh_token, client_id, client_secret)

    tz = pytz.timezone("America/New_York")
    now = datetime.now(tz)

    start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_day = now.replace(hour=23, minute=59, second=59, microsecond=0)

    params = {
        "timeMin": start_of_day.isoformat(),
        "timeMax": end_of_day.isoformat(),
        "singleEvents": "true",
        "orderBy": "startTime",
    }

    headers = {"Authorization": f"Bearer {access_token}"}

    resp = requests.get(
        "https://www.googleapis.com/calendar/v3/calendars/primary/events",
        params=params,
        headers=headers,
    ).json()

    if "items" not in resp:
        logger.error(f"Google Calendar error: {resp}")
        return []

    events = []

    for ev in resp["items"]:
        start = ev.get("start", {}).get("dateTime")
        end = ev.get("end", {}).get("dateTime")
        if not start or not end:
            continue

        events.append({
            "id": ev.get("id"),
            "name": ev.get("summary", "No title"),
            "start": start,
            "end": end,
            "location": ev.get("location"),
        })

    return events


# ------------------------------------------------------------
# CALCULATE FREE TIME BLOCKS
# ------------------------------------------------------------
def fetch_free_time_blocks(refresh_token, client_id, client_secret):
    """
    Returns all free gaps in today’s schedule.
    Output:
    [
      {"start": "...", "end": "..."},
      ...
    ]
    """

    events = fetch_today_events(refresh_token, client_id, client_secret)

    tz = pytz.timezone("America/New_York")
    now = datetime.now(tz)

    start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_day = now.replace(hour=23, minute=59, second=59, microsecond=0)

    # Convert events into (start, end) datetime tuples
    busy_blocks = []
    for ev in events:
        s = parse_google_datetime(ev["start"])
        e = parse_google_datetime(ev["end"])
        if s and e:
            busy_blocks.append((s, e))

    # Sort chronologically
    busy_blocks.sort(key=lambda x: x[0])

    free_blocks = []
    cursor = start_of_day

    for start, end in busy_blocks:
        # If there is a gap BEFORE this event
        if start > cursor:
            free_blocks.append({
                "start": cursor.isoformat(),
                "end": start.isoformat()
            })

        # Move pointer forward
        cursor = max(cursor, end)

    # Last free time of the day
    if cursor < end_of_day:
        free_blocks.append({
            "start": cursor.isoformat(),
            "end": end_of_day.isoformat()
        })

    return free_blocks
