#!/bin/bash

# Simple test script for VioletVibes API endpoints
# Usage: ./test_api.sh
# Note: Using port 5001 because 5000 is often used by AirPlay Receiver on macOS

BASE_URL="http://localhost:5001"

echo "🧪 Testing VioletVibes API Endpoints"
echo "===================================="
echo ""

echo "1️⃣  Testing Events API..."
echo "GET $BASE_URL/api/events"
curl -s "$BASE_URL/api/events" | python3 -m json.tool | head -30
echo ""
echo ""

echo "2️⃣  Testing Chat API..."
echo "POST $BASE_URL/api/chat"
echo "Message: 'Find quiet café'"
curl -s -X POST "$BASE_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "Find quiet café"}' | python3 -m json.tool
echo ""
echo ""

echo "✅ API tests complete!"
echo ""
echo "💡 Tip: If you see connection errors, make sure the Flask server is running:"
echo "   python app.py"
echo "   (Server should be running on port 5001)"

