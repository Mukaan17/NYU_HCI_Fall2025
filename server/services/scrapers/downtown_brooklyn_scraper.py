import requests
from bs4 import BeautifulSoup

API_URL = "https://www.downtownbrooklyn.com/wp-json/tribe/events/v1/events"

def fetch_downtown_bk_events(limit: int = 20):
    """Fetch events from Downtown Brooklyn JSON API."""
    try:
        resp = requests.get(API_URL, timeout=10)
        resp.raise_for_status()
        data = resp.json()

        events = data.get("events", [])
        results = []

        for e in events[:limit]:
            title = e.get("title")
            url = e.get("url")
            image = (e.get("image") or {}).get("url")
            description_html = e.get("description") or ""

            # Clean description
            description = (
                BeautifulSoup(description_html, "html.parser")
                .get_text(separator=" ", strip=True)
            )

            results.append({
                "name": title,
                "url": url,
                "image": image,
                "description": description,
                "start": e.get("start_date"),
                "end": e.get("end_date"),
                "location": "Downtown Brooklyn",
                "address": None,
            })

        return results

    except Exception as err:
        print("Downtown Brooklyn scraper error:", err)
        return []
