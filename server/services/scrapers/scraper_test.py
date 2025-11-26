import os, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../"))
sys.path.insert(0, ROOT)

# scraper_test.py

from pprint import pprint

# --- Import all scrapers ---
from services.scrapers.downtown_brooklyn_scraper import fetch_downtown_bk_events
from services.scrapers.brooklyn_bridge_park_scraper import fetch_brooklyn_bridge_park_events
from services.scrapers.dumbo_scraper import fetch_dumbo_events
from services.scrapers.nyc_parks_scraper import fetch_nyc_parks_events
from services.scrapers.timeout_rss import fetch_timeout_rss
from services.scrapers.nyc_events_service import events_near_bbox
from services.scrapers.nyc_tourism_scraper import fetch_nyc_tourism_events
from services.scrapers.engage_events_service import fetch_engage_events

# NEW SCRAPERS
from services.scrapers.brooklyn_popup_scraper import fetch_brooklyn_popup
from services.scrapers.nycforfree_scraper import fetch_nycforfree_events
from services.scrapers.donyc_scraper import fetch_donyc_popups

SCRAPERS = [
    ("Downtown Brooklyn", fetch_downtown_bk_events),
    ("Brooklyn Bridge Park", fetch_brooklyn_bridge_park_events),
    ("DUMBO", fetch_dumbo_events),
    ("NYC Parks", fetch_nyc_parks_events),
    ("TimeOut RSS", fetch_timeout_rss),
    ("NYC Events (permits)", events_near_bbox),
    ("NYC Tourism", fetch_nyc_tourism_events),
    ("Engage (on-campus)", fetch_engage_events),

    # New ones
    ("Brooklyn Pop-Up", fetch_brooklyn_popup),
    ("NYCforFree", fetch_nycforfree_events),
    ("DoNYC Pop-ups RSS", fetch_donyc_popups),
]

def test_all_scrapers():
    print("\n=============================")
    print(" SCRAPER TEST RUNNING ")
    print("=============================\n")

    for name, func in SCRAPERS:
        print(f"--- Testing: {name} ---")

        try:
            data = func(limit=10)
        except Exception as e:
            print(f"ERROR running {name}: {e}\n")
            continue

        count = len(data)
        print(f"Returned: {count} results")

        if count == 0:
            print(f"⚠️ WARNING: {name} returned 0 results\n")
            continue

        # Print a sample
        print("Sample result:")
        pprint(data[0])
        print("\n")

    print("=== Test complete ===")


if __name__ == "__main__":
    test_all_scrapers()
