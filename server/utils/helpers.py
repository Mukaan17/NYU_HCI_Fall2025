# server/utils/helpers.py
import polyline

def decode_polyline(encoded: str):
    """
    Decodes a Google Maps encoded polyline string into a list
    of { latitude, longitude } dicts usable by React Native Maps.
    """
    if not encoded:
        return []

    decoded = polyline.decode(encoded)
    return [{"latitude": lat, "longitude": lng} for lat, lng in decoded]
