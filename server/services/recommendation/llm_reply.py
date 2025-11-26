# services/recommendation/llm_reply.py

from typing import List, Dict, Any
import google.generativeai as genai


def format_items_for_prompt(items: List[Dict[str, Any]]) -> str:
    """
    Convert the card items into readable bullet lines for prompting the LLM.
    Each item is guaranteed to already be selected as an option.
    """
    lines = []
    for i, item in enumerate(items):
        name = item.get("name", "Unknown")
        distance = item.get("distance") or "distance unknown"
        walk = item.get("walk_time") or "walk time unknown"

        lines.append(f"{i+1}. {name} — {distance} ({walk})")

    return "\n".join(lines)


def generate_list_reply(user_message: str, items: List[Dict[str, Any]]) -> str:
    """
    Use Gemini to generate a friendly reply describing only the provided items.
    This never invents extra places, events, or details.
    """

    items_text = format_items_for_prompt(items)

    prompt = f"""
You are VioletVibes, the NYU student concierge.

Recommend ONLY the items provided below.

Available options:
{items_text}

User request: "{user_message}"

Rules:
- DO NOT invent new places or events.
- ONLY talk about the items above.
- Keep it short, friendly, and helpful.
- You may rearrange or summarize, but never add information not shown.
"""

    try:
        model = genai.GenerativeModel("models/gemini-2.5-flash")
        resp = model.generate_content(prompt)
        text = getattr(resp, "text", None)
        if not text:
            return "Here are some options nearby!"
        return text.strip()

    except Exception as e:
        print("LLM_REPLY ERROR:", e)
        # Always fall back to a simple deterministic reply
        fallback = "Here are some nearby options:\n" + items_text
        return fallback
