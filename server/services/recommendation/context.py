# services/recommendation/context.py
from typing import List, Dict, Any


class ConversationContext:
    """
    Minimal memory used by the recommendation engine.
    """

    def __init__(self):
        self.history: List[Dict[str, str]] = []
        self.last_places: List[Dict[str, Any]] = []
        self.all_results: List[Dict[str, Any]] = []
        self.result_index: int = 0
        self.context: str | None = None
        self.last_intent: str | None = None
        self.user_profile_dict = {}
        self.user_location: Dict[str, Any] | None = None  # {"lat": float, "lng": float, "campus": str}

    # HISTORIES
    def add_message(self, role: str, content: str):
        self.history.append({"role": role, "content": content})

    # RESULTS
    def set_places(self, places: List[Dict[str, Any]]):
        self.last_places = places

    def set_results(self, results: List[Dict[str, Any]]):
        self.all_results = results
        self.result_index = 0
