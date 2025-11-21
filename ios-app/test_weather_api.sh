#!/bin/bash

# Test OpenWeather API Key
# Usage: ./test_weather_api.sh YOUR_API_KEY

API_KEY="${1:-YOUR_API_KEY_HERE}"

if [ "$API_KEY" == "YOUR_API_KEY_HERE" ]; then
    echo "❌ Please provide your API key as an argument:"
    echo "   ./test_weather_api.sh YOUR_API_KEY"
    echo ""
    echo "Or edit this script and replace YOUR_API_KEY_HERE with your actual key"
    exit 1
fi

# Test with Brooklyn coordinates (2 MetroTech Center)
LAT=40.693393
LON=-73.98555

echo "🌤️  Testing OpenWeather API with key: ${API_KEY:0:8}..."
echo "📍 Location: Brooklyn, NY ($LAT, $LON)"
echo ""

URL="https://api.openweathermap.org/data/2.5/weather?lat=$LAT&lon=$LON&appid=$API_KEY&units=imperial"

echo "📡 Making request to OpenWeather API..."
echo ""

response=$(curl -s -w "\n%{http_code}" "$URL")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

echo "HTTP Status Code: $http_code"
echo ""

if [ "$http_code" == "200" ]; then
    echo "✅ API Key is valid!"
    echo ""
    echo "Response:"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
    
    # Extract temperature and condition
    temp=$(echo "$body" | python3 -c "import sys, json; data=json.load(sys.stdin); print(int(data['main']['temp']))" 2>/dev/null)
    condition=$(echo "$body" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['weather'][0]['main'])" 2>/dev/null)
    
    if [ ! -z "$temp" ]; then
        echo ""
        echo "🌡️  Temperature: ${temp}°F"
        echo "☁️  Condition: $condition"
    fi
elif [ "$http_code" == "401" ]; then
    echo "❌ Invalid API Key (401 Unauthorized)"
    echo "   Please check your API key and make sure it's correct"
    echo ""
    echo "Response:"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
elif [ "$http_code" == "429" ]; then
    echo "⚠️  API Rate Limit Exceeded (429 Too Many Requests)"
    echo "   You've made too many requests. Wait a bit and try again."
else
    echo "❌ Error: HTTP $http_code"
    echo ""
    echo "Response:"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
fi

