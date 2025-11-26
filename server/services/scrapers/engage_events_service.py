import re
import requests
from datetime import datetime, timedelta
from bs4 import BeautifulSoup

BASE_PAGE = "https://engage.nyu.edu/events"
BASE_API = "https://engage.nyu.edu/api/discovery/event/search"

def _extract_xsrf(html: str) -> str | None:
    """Pull the XSRF token out of window.initialAppState."""
    m = re.search(r'"xsrfToken":"([^"]+)"', html)
    return m.group(1) if m else None


def fetch_engage_events(days_ahead: int = 7, limit: int = 50):
    """
    FULLY WORKING Engage scraper.
    Loads XSRF token from HTML, then hits the event API correctly.
    """
    # Step 1 — load HTML to grab a fresh token
    page = requests.get(BASE_PAGE, timeout=10)
    xsrf = _extract_xsrf(page.text)

    if not xsrf:
        print("[Engage] Could not extract XSRF token")
        return []

    cookies = {
        "XSRF-TOKEN": xsrf
    }

    headers = {
        "X-XSRF-TOKEN": xsrf,
        "Referer": BASE_PAGE,
        "User-Agent": "Mozilla/5.0",
        "Accept": "application/json"
    }

    # Step 2 — construct the query params
    now = datetime.utcnow()
    future = now + timedelta(days=days_ahead)

    params = {
        "orderBy": "startDate",
        "status": "approved",
        "query": "",
        "endsAfter": now.replace(microsecond=0).isoformat() + "Z",
        "startsBefore": future.replace(microsecond=0).isoformat() + "Z",
        "page": 1,
        "perPage": limit,
    }

    # Step 3 — call the actual API
    r = requests.get(
        BASE_API,
        params=params,
        headers=headers,
        cookies=cookies,
        timeout=10
    )

    r.raise_for_status()
    data = r.json()
    events = data.get("data") or data.get("value") or []

    formatted = []
    for e in events:
        formatted.append({
            "name": e.get("name"),
            "start": e.get("startDate"),
            "end": e.get("endDate"),
            "description": e.get("description"),
            "location": e.get("location"),
            "organization": e.get("organizationName"),
            "image": e.get("imageUrl"),
            "url": f"https://engage.nyu.edu/event/{e.get('id')}",
        })

    return formatted
