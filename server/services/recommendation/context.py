# services/recommendation/context.py

from typing import List, Dict, Any


class ConversationContext:
    """
    Minimal memory object used by the recommendation engine.
    Stores:
      - recent chat messages (for LLM)
      - last_places: last shown cards (places/events)
      - all_results: full ranked list for rotation
      - result_index: current rotation index
      - context: the detected vibe/category from last query
      - last_intent: what the last step was used for
    """
    def __init__(self):
        self.history: List[Dict[str, str]] = []       # {"role": "user/assistant", "content": "..."}
        self.last_places: List[Dict[str, Any]] = []   # last shown places/events
        self.all_results: List[Dict[str, Any]] = []   # full ranked list
        self.result_index: int = 0                    # pointer for rotating recommendations
        self.context: str | None = None               # last vibe or category
        self.last_intent: str | None = None           # recommendation / followup / rotation

    # -----------------------------
    # HISTORY HANDLING
    # -----------------------------
    def add_message(self, role: str, content: str):
        self.history.append({"role": role, "content": content})

    # -----------------------------
    # LAST PLACES / RESULTS
    # -----------------------------
    def set_places(self, places: List[Dict[str, Any]]):
        self.last_places = places

    def set_results(self, results: List[Dict[str, Any]]):
        self.all_results = results
        self.result_index = 0  # reset rotation
