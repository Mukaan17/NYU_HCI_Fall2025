class ChatMemory:
    def __init__(self):
        self.history = []   # ← ALWAYS a list of dicts

    def add_message(self, role: str, content: str):
        self.history.append({"role": role, "content": content})

    def to_formatted_history(self) -> str:
        """Convert to text block for LLM prompt."""
        lines = []
        for msg in self.history:
            lines.append(f"{msg['role'].upper()}: {msg['content']}")
        return "\n".join(lines)

