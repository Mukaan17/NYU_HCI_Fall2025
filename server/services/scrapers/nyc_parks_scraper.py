# services/scrapers/nyc_parks_scraper.py
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timedelta

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/118.0.5993.90 Safari/537.36"
    ),
    "Referer": "https://www.google.com/"
}

URL = "https://www.nycgovparks.org/events"

def fetch_nyc_parks_events(limit=20):
    try:
        r = requests.get(URL, headers=HEADERS, timeout=10)
        r.raise_for_status()

        soup = BeautifulSoup(r.text, "html.parser")
        events = []

        # Events are now in <article class="event"> blocks
        blocks = soup.select("article.event") or soup.select("div.event")

        for ev in blocks[:limit]:
            title = ev.select_one(".event-title, h2, h3")
            name = title.get_text(strip=True) if title else None

            desc = ev.select_one(".event-description, p")
            description = desc.get_text(" ", strip=True) if desc else None

            date_el = ev.select_one(".event-date, time")
            start = date_el.get_text(strip=True) if date_el else None

            url_el = ev.select_one("a")
            url = "https://www.nycgovparks.org" + url_el["href"] if url_el else None

            img = ev.select_one("img")
            image = img["src"] if img else None

            events.append({
                "name": name,
                "description": description,
                "start": start,
                "end": None,
                "location": "NYC Park Event",
                "address": None,
                "url": url,
                "image": image
            })

        return events

    except Exception as e:
        print("NYC Parks scraper error:", e)
        return []

