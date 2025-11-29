# services/recommendation/llm_reply.py

import logging
from typing import List, Dict, Any
import google.generativeai as genai
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

logger = logging.getLogger(__name__)


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


@retry(
    stop=stop_after_attempt(2),
    wait=wait_exponential(multiplier=1, min=1, max=3),
    retry=retry_if_exception_type((Exception,)),
    reraise=False
)
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
        resp = model.generate_content(prompt, request_options={"timeout": 10})
        text = getattr(resp, "text", None)
        if not text:
            logger.warning("Gemini returned empty response")
            return "Here are some options nearby!"
        return text.strip()

    except Exception as e:
        logger.error(f"LLM reply error: {e}", exc_info=True)
        # Always fall back to a simple deterministic reply
        fallback = "Here are some nearby options:\n" + items_text
        return fallback
