# services/scrapers/nyc_parks_scraper.py
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Cache-Control": "max-age=0"
}

URL = "https://www.nycgovparks.org/events"

def fetch_nyc_parks_events(limit=20):
    try:
        r = requests.get(URL, headers=HEADERS, timeout=10, allow_redirects=True)
        
        # Handle 403 Forbidden errors gracefully
        if r.status_code == 403:
            logger.warning(f"NYC Parks scraper: 403 Forbidden - website may be blocking automated requests")
            return []
        
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
            url = "https://www.nycgovparks.org" + url_el["href"] if url_el and url_el.get("href") else None

            img = ev.select_one("img")
            image = img["src"] if img and img.get("src") else None

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

    except requests.exceptions.HTTPError as e:
        if e.response and e.response.status_code == 403:
            logger.warning(f"NYC Parks scraper: 403 Forbidden - website may be blocking automated requests")
        else:
            logger.warning(f"NYC Parks scraper HTTP error: {e}")
        return []
    except requests.exceptions.RequestException as e:
        logger.warning(f"NYC Parks scraper request error: {e}")
        return []
    except Exception as e:
        logger.warning(f"NYC Parks scraper error: {e}")
        return []

