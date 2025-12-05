# services/calendar_service.py

from datetime import datetime, timedelta
import google.auth.transport.requests
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
import pytz
import logging

logger = logging.getLogger(__name__)


def get_today_times():
    """Return RFC-3339 timestamps for now → midnight."""
    now = datetime.utcnow()
    end_of_day = datetime.utcnow().replace(hour=23, minute=59, second=59, microsecond=0)

    return (
        now.isoformat() + "Z",
        end_of_day.isoformat() + "Z"
    )


def refresh_google_token(refresh_token: str, client_id: str, client_secret: str):
    """
    Exchanges refresh_token → new access_token.
    """
    creds = Credentials(
        None,
        refresh_token=refresh_token,
        token_uri="https://oauth2.googleapis.com/token",
        client_id=client_id,
        client_secret=client_secret,
        scopes=["https://www.googleapis.com/auth/calendar.readonly"],
    )

    request = google.auth.transport.requests.Request()
    creds.refresh(request)
    return creds


def fetch_today_events(refresh_token: str, client_id: str, client_secret: str):
    """
    Fetch all Google Calendar events from now → midnight.
    """
    creds = refresh_google_token(refresh_token, client_id, client_secret)
    service = build("calendar", "v3", credentials=creds)

    time_min, time_max = get_today_times()

    events_result = service.events().list(
        calendarId="primary",
        timeMin=time_min,
        timeMax=time_max,
        singleEvents=True,
        orderBy="startTime",
    ).execute()

    events = events_result.get("items", [])

    cleaned = []
    for e in events:
        cleaned.append({
            "id": e.get("id"),
            "name": e.get("summary"),
            "description": e.get("description"),
            "start": e.get("start", {}).get("dateTime"),
            "end": e.get("end", {}).get("dateTime"),
            "location": e.get("location"),
        })

    return cleaned


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
        except Exception as e:
            logger.warning(f"Failed parsing datetime: {dt_str} - {e}")
            return None


def fetch_free_time_blocks(refresh_token, client_id, client_secret):
    """
    Returns all free gaps in today's schedule.
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
