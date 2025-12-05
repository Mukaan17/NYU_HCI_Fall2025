import os
import requests
import logging

logger = logging.getLogger(__name__)

OPENWEATHER_KEY = os.environ.get("OPENWEATHER_KEY")


def current_weather(city="Brooklyn,US"):
    """Get current weather by city name."""
    if not OPENWEATHER_KEY:
        logger.error("OPENWEATHER_KEY not configured")
        raise ValueError("Weather API key not configured")
    
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {"q": city, "appid": OPENWEATHER_KEY, "units": "imperial"}
    r = requests.get(url, params=params, timeout=10)
    r.raise_for_status()
    j = r.json()
    return {
        "temp_f": j["main"]["temp"],
        "desc": j["weather"][0]["description"],
        "icon": j["weather"][0]["icon"]
    }


def get_weather_by_coords(lat: float, lon: float):
    """Get current weather by latitude and longitude."""
    if not OPENWEATHER_KEY:
        logger.error("OPENWEATHER_KEY not configured")
        raise ValueError("Weather API key not configured")
    
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "lat": lat,
        "lon": lon,
        "appid": OPENWEATHER_KEY,
        "units": "imperial"
    }
    
    try:
        r = requests.get(url, params=params, timeout=10)
        r.raise_for_status()
        j = r.json()
        
        # Extract main weather condition
        main_condition = j["weather"][0]["main"] if j.get("weather") else "Clear"
        
        return {
            "temp": round(j["main"]["temp"]),
            "temp_f": j["main"]["temp"],
            "desc": j["weather"][0]["description"] if j.get("weather") else "Clear",
            "icon": j["weather"][0]["icon"] if j.get("weather") else "",
            "main": main_condition,
            "humidity": j["main"].get("humidity", 0),
            "wind_speed": j.get("wind", {}).get("speed", 0)
        }
    except requests.exceptions.RequestException as e:
        logger.error(f"Weather API request failed: {e}")
        raise


def get_forecast_by_coords(lat: float, lon: float):
    """Get weather forecast by latitude and longitude."""
    if not OPENWEATHER_KEY:
        logger.error("OPENWEATHER_KEY not configured")
        raise ValueError("Weather API key not configured")
    
    url = "https://api.openweathermap.org/data/2.5/forecast"
    params = {
        "lat": lat,
        "lon": lon,
        "appid": OPENWEATHER_KEY,
        "units": "imperial"
    }
    
    try:
        r = requests.get(url, params=params, timeout=10)
        r.raise_for_status()
        j = r.json()
        
        # Return the list of forecast items
        return j.get("list", [])
    except requests.exceptions.RequestException as e:
        logger.error(f"Weather forecast API request failed: {e}")
        raise