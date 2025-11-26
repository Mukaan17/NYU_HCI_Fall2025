# services/scrapers/brooklyn_bridge_park_scraper.py

import requests
from bs4 import BeautifulSoup

API_URL = "https://www.brooklynbridgepark.org/wp-json/wp/v2/tribe_events"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15"
    ),
    "Accept": "application/json",
}


def fetch_brooklyn_bridge_park_events(limit=20):
    """
    Scrapes upcoming events from Brooklyn Bridge Park’s Tribe Events API.
    Works around their bot protection by using a real browser User-Agent.
    """

    try:
        r = requests.get(API_URL, params={"per_page": limit}, headers=HEADERS, timeout=10)
        r.raise_for_status()
        data = r.json()

        events = []

        for ev in data:
            title = ev.get("title", {}).get("rendered")
            url = ev.get("link")
            desc_html = ev.get("content", {}).get("rendered", "")
            desc = BeautifulSoup(desc_html, "html.parser").get_text().strip()
            meta = ev.get("meta", {})

            start = meta.get("_EventStartDate")
            end = meta.get("_EventEndDate")

            # featured image (Yoast)
            image = None
            yoast = ev.get("yoast_head_json", {})
            if yoast:
                imgs = yoast.get("og_image", [])
                if imgs:
                    image = imgs[0].get("url")

            events.append({
                "name": title,
                "description": desc[:300] + "..." if len(desc) > 300 else desc,
                "start": start,
                "end": end,
                "url": url,
                "image": image,
                "address": "Brooklyn Bridge Park, Brooklyn, NY",
                "location": "Brooklyn Bridge Park",
            })

        return events

    except Exception as e:
        print("Brooklyn Bridge Park scraper error:", e)
        return []
