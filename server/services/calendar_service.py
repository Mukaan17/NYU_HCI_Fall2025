# services/calendar_service.py

from datetime import datetime, timedelta
import google.auth.transport.requests
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build


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
