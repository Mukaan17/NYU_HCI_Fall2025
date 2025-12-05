# services/recommendation/llm_reply.py

import logging
from typing import List, Dict, Any, Optional
import google.generativeai as genai
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from services.recommendation.context import ConversationContext

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
You are Violet, a helpful and friendly AI concierge for NYU students in Downtown Brooklyn.

Recommend ONLY the items provided below.

Available options:
{items_text}

User request: "{user_message}"

CRITICAL RULES:
1. NEVER start with greetings like "Hey there!", "Hello!", "Hi!", "Hey!" - respond directly with recommendations
2. DO NOT invent new places or events - ONLY talk about the items above
3. Keep it concise and conversational (2-3 sentences max)
4. Be helpful and friendly, but start directly with the recommendation
5. You may rearrange or summarize, but never add information not shown
6. Remove any greeting patterns from your response - start directly with the answer
"""

    try:
        model = genai.GenerativeModel("models/gemini-2.5-flash")
        resp = model.generate_content(prompt, request_options={"timeout": 10})
        text = getattr(resp, "text", None)
        if not text:
            logger.warning("Gemini returned empty response")
            return format_fallback_reply(items)
        
        # Clean up any unwanted greetings
        cleaned = remove_greetings(text.strip())
        return cleaned

    except Exception as e:
        logger.error(f"LLM reply error: {e}", exc_info=True)
        return format_fallback_reply(items)


def generate_contextual_reply(
    user_message: str, 
    items: List[Dict[str, Any]], 
    memory: ConversationContext
) -> str:
    """
    Generate a context-aware reply that considers conversation history.
    Handles follow-up questions intelligently by using previous context.
    """
    
    # Build conversation history context
    history_context = ""
    if memory.history:
        # Include last 3 exchanges for context (6 messages: 3 user + 3 assistant)
        recent_history = memory.history[-6:]
        history_lines = []
        for msg in recent_history:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            if role == "user":
                history_lines.append(f"User: {content}")
            else:
                history_lines.append(f"Assistant: {content}")
        history_context = "\n".join(history_lines)
    
    # Build previous recommendations context
    previous_recs_context = ""
    if memory.last_places:
        prev_names = [p.get("name", "Unknown") for p in memory.last_places[:3]]
        previous_recs_context = f"Previously recommended: {', '.join(prev_names)}"
    
    items_text = format_items_for_prompt(items) if items else "No new options found."
    
    # Determine if this is a follow-up question
    is_followup = len(memory.history) > 2  # More than just current exchange
    
    # Build system prompt based on context
    system_prompt = """You are Violet, a helpful and friendly AI concierge for NYU students in Downtown Brooklyn. 
You're conversational, natural, and avoid repetitive greetings. You remember previous conversations and can answer follow-up questions intelligently."""
    
    context_section = ""
    if is_followup:
        context_section = "This is a follow-up question in an ongoing conversation. Use the previous context to answer naturally.\n\n"
        if history_context:
            context_section += f"Previous conversation:\n{history_context}\n\n"
        if previous_recs_context:
            context_section += f"Previous recommendations: {previous_recs_context}\n\n"
    else:
        context_section = "This is a new conversation.\n\n"
    
    items_section = ""
    if items:
        items_section = f"Current available options:\n{items_text}\n\n"
    else:
        items_section = "No new options found for this request.\n\n"
    
    prompt = f"""{system_prompt}

{context_section}{items_section}Current user message: "{user_message}"

CRITICAL RULES:
1. NEVER start with greetings like "Hey there!", "Hello!", "Hi!", "Hey!" - respond directly and naturally
2. If this is a follow-up, acknowledge context naturally without being repetitive or formal
3. DO NOT invent new places or events - only reference what's provided
4. Keep responses concise (2-3 sentences max) and conversational
5. Be helpful and friendly, but sound like you're continuing a conversation, not starting one
6. If user asks about previous recommendations, reference them naturally
7. If no new options, suggest alternatives or ask a clarifying question
8. Remove any greeting patterns from your response - start directly with the answer or recommendation
"""

    try:
        model = genai.GenerativeModel("models/gemini-2.5-flash")
        resp = model.generate_content(prompt, request_options={"timeout": 10})
        text = getattr(resp, "text", None)
        if not text:
            logger.warning("Gemini returned empty response for contextual reply")
            return format_fallback_reply(items, is_followup)
        
        # Clean up any unwanted greetings that might slip through
        cleaned = text.strip()
        
        # Remove common greeting patterns at the start (case-insensitive)
        greeting_patterns = [
            "hey there!",
            "hey there",
            "hello!",
            "hello",
            "hi there!",
            "hi there",
            "hi!",
            "hey!",
            "hey",
        ]
        
        cleaned_lower = cleaned.lower()
        for pattern in greeting_patterns:
            if cleaned_lower.startswith(pattern):
                # Find the actual start position (preserving case)
                pattern_len = len(pattern)
                # Check if there's punctuation after the greeting
                if len(cleaned) > pattern_len:
                    next_char = cleaned[pattern_len]
                    if next_char in [",", "!", " "]:
                        cleaned = cleaned[pattern_len:].strip()
                        # Remove leading punctuation
                        while cleaned and cleaned[0] in [",", "!", " "]:
                            cleaned = cleaned[1:].strip()
                    else:
                        cleaned = cleaned[pattern_len:].strip()
                else:
                    cleaned = ""
                break
        
        # Also check for patterns with capitalization variations
        if not cleaned or len(cleaned) < 10:  # If too short after cleaning, might be just a greeting
            # Try to extract meaningful content
            sentences = text.split(". ")
            if len(sentences) > 1:
                # Skip first sentence if it looks like a greeting
                first_sent = sentences[0].lower()
                if any(g in first_sent for g in ["hey", "hello", "hi"]) and len(first_sent) < 15:
                    cleaned = ". ".join(sentences[1:]).strip()
        
        return cleaned if cleaned else text.strip()  # Fallback to original if cleaning removed everything

    except Exception as e:
        logger.error(f"Contextual LLM reply error: {e}", exc_info=True)
        return format_fallback_reply(items, is_followup)


def remove_greetings(text: str) -> str:
    """
    Remove common greeting patterns from the start of text.
    """
    cleaned = text.strip()
    cleaned_lower = cleaned.lower()
    
    greeting_patterns = [
        "hey there!",
        "hey there",
        "hello!",
        "hello",
        "hi there!",
        "hi there",
        "hi!",
        "hey!",
        "hey",
    ]
    
    for pattern in greeting_patterns:
        if cleaned_lower.startswith(pattern):
            pattern_len = len(pattern)
            if len(cleaned) > pattern_len:
                next_char = cleaned[pattern_len]
                if next_char in [",", "!", " "]:
                    cleaned = cleaned[pattern_len:].strip()
                    while cleaned and cleaned[0] in [",", "!", " "]:
                        cleaned = cleaned[1:].strip()
                else:
                    cleaned = cleaned[pattern_len:].strip()
            else:
                cleaned = ""
            break
    
    # Also check for patterns with capitalization variations
    if not cleaned or len(cleaned) < 10:
        sentences = text.split(". ")
        if len(sentences) > 1:
            first_sent = sentences[0].lower()
            if any(g in first_sent for g in ["hey", "hello", "hi"]) and len(first_sent) < 15:
                cleaned = ". ".join(sentences[1:]).strip()
    
    return cleaned if cleaned else text.strip()


def format_fallback_reply(items: List[Dict[str, Any]], is_followup: bool = False) -> str:
    """
    Generate a simple fallback reply when LLM fails.
    Avoids repetitive greetings.
    """
    if not items:
        if is_followup:
            return "I couldn't find anything new for that. Want to try something else?"
        return "I couldn't find anything nearby right now. What are you in the mood for?"
    
    top = items[:2]
    lines = []
    for p in top:
        name = p.get("name", "Unknown")
        dist = p.get("distance") or ""
        walk = p.get("walk_time") or ""

        if dist and walk:
            lines.append(f"**{name}** ({dist}, {walk})")
        else:
            lines.append(f"**{name}**")
    
    if is_followup:
        return "Here are some options: " + ", ".join(lines)
    return "Here are some nearby options: " + ", ".join(lines)
