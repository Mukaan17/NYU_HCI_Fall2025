# server/chat_test_suite.py

import requests
import json
import time

API_URL = "http://127.0.0.1:5001/api/chat"

TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzIiwiZW1haWwiOiJ0ZXN0QHRlc3QuY29tIiwiZXhwIjoxNzY1MTUzNzI4LCJpYXQiOjE3NjQ1NDg5Mjh9.p6c-DulU67JTywCdIEAgCjoyjdWpfT1B8RN5XZE0rS0"

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json",
}

# ---------------------------------------------
# Test messages
# ---------------------------------------------
TEST_MESSAGES = [
    "Find me a quiet study spot for 4 people",
    "I'm in a rush, need something fast to eat",
    "Where can I go shopping?",
    "Something fun or party vibes for tonight",
    "Find something to explore for 30 minutes",
    "What's a good chill bar nearby?",
    "Give me something similar",
    "Tell me more about the first place",
    "I'm bored, what's something quick to do?",
    "Where can I get coffee right now?",
]


# ---------------------------------------------
# Helper: send a message
# ---------------------------------------------
def send_message(msg: str):
    print("=" * 80)
    print(f"USER: {msg}")
    print("-" * 80)

    t0 = time.time()
    try:
        response = requests.post(
            API_URL,
            headers=HEADERS,
            data=json.dumps({"message": msg}),
            timeout=60,
        )
        latency = time.time() - t0

        if response.status_code != 200:
            print(f"❌ ERROR {response.status_code}: {response.text}")
        else:
            data = response.json()
            print(f"Reply: {data.get('reply')}")
            print("\nTop Results:")
            for i, p in enumerate(data.get("places", []), start=1):
                print(f"  {i}. {p.get('name')} — {p.get('address')} — score {p.get('score'):.3f}")

            print(f"\nLatency: {latency:.2f}s")

    except Exception as e:
        print(f"❌ Exception: {e}")


# ---------------------------------------------
# Run tests
# ---------------------------------------------
def run_tests():
    print("\n==============================")
    print(" VIOLETVIBES CHATBOT TEST SUITE")
    print("==============================\n")

    for msg in TEST_MESSAGES:
        send_message(msg)
        time.sleep(1)  # brief pause so you can read output


if __name__ == "__main__":
    run_tests()
