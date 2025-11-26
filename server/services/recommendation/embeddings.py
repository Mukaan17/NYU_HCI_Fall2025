# server/services/recommendation/embeddings.py

import google.generativeai as genai

EMBED_MODEL = "models/text-embedding-004"

# In-memory cache
_EMBED_CACHE = {}


def get_embedding(text: str):
    """
    Returns an embedding vector for text, with aggressive caching.
    """
    text = (text or "").strip()
    if not text:
        return []

    if text in _EMBED_CACHE:
        return _EMBED_CACHE[text]

    try:
        resp = genai.embed_content(
            model=EMBED_MODEL,
            content=text,
        )
        vec = resp["embedding"]
    except Exception:
        vec = []

    _EMBED_CACHE[text] = vec
    return vec


def cosine_similarity(a, b):
    """
    Basic cosine similarity.
    """
    if not a or not b or len(a) != len(b):
        return 0.0

    dot = sum(x * y for x, y in zip(a, b))
    norm_a = sum(x * x for x in a) ** 0.5
    norm_b = sum(x * x for x in b) ** 0.5

    if norm_a == 0 or norm_b == 0:
        return 0.0

    return dot / (norm_a * norm_b)
