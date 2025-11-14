import os, requests
OPENWEATHER_KEY = os.environ.get("OPENWEATHER_KEY")

def current_weather(city="Brooklyn,US"):
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