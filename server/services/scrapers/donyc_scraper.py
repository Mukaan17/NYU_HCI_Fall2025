import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

BASE_URL = "https://donyc.com"
POPUPS_URL = "https://donyc.com/pop-ups-nyc"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0 Safari/537.36"
    )
}


def fetch_donyc_popups(limit=40, debug=False):
    """
    Scrapes DoNYC's Pop-Ups page.
    They use dynamic JS, but server returns enough HTML for basic data.
    Supports wide selectors so changes won't break everything.
    """
    try:
        r = requests.get(POPUPS_URL, headers=HEADERS, timeout=12)
        if debug:
            print("DoNYC status:", r.status_code)
        if r.status_code != 200:
            return []
    except Exception as e:
        if debug:
            print("DoNYC error:", e)
        return []

    soup = BeautifulSoup(r.text, "lxml")

    # DoNYC uses multiple card formats
    cards = (
        soup.select(".event-card") or
        soup.select(".ds-listing") or
        soup.select(".vevent") or
        soup.find_all("article") or
        []
    )

    events = []
    for c in cards[:limit]:
        # Title
        title_el = (
            c.select_one(".event-title") or
            c.select_one(".ds-listing-event-title") or
            c.find("h3") or
            c.find("h2")
        )
        name = title_el.get_text(strip=True) if title_el else None

        # Link
        link_el = c.find("a", href=True)
        url = urljoin(BASE_URL, link_el["href"]) if link_el else None

        # Date
        date_el = (
            c.select_one(".ds-listing-event-date") or
            c.select_one(".dtstart") or
            c.select_one("time")
        )
        date = date_el.get_text(strip=True) if date_el else None

        # Image
        img_el = c.find("img")
        image = img_el.get("src") if img_el else None

        # Description (fallback to card teaser text)
        desc_el = (
            c.select_one(".ds-listing-event-description") or
            c.select_one("p") or
            c.find("p")
        )
        desc = desc_el.get_text(strip=True) if desc_el else None

        # Only store if it has a real name AND a link
        if not name or not url:
            continue

        events.append({
            "name": name,
            "start": date,
            "end": None,
            "location": "DoNYC Pop-Up Location (varies)",
            "address": None,
            "image": image,
            "url": url,
            "description": desc,
        })

    return events
