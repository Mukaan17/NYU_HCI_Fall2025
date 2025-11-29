#!/bin/bash

# API Testing Script for VioletVibes Backend
# Usage: ./test_api.sh [base_url]

BASE_URL="${1:-http://localhost:5001}"
echo "=========================================="
echo "Testing VioletVibes API at $BASE_URL"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Test function
test_endpoint() {
    local name=$1
    local method=$2
    local url=$3
    local data=$4
    local expected_status=$5
    
    echo -e "\n${YELLOW}Testing: $name${NC}"
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (Status: $http_code)"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC} (Expected: $expected_status, Got: $http_code)"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        ((FAILED++))
        return 1
    fi
}

# 1. Health Check
test_endpoint "Health Check" "GET" "$BASE_URL/health" "" 200

# 2. Sign Up
SIGNUP_EMAIL="test$(date +%s)@example.com"
SIGNUP_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/signup" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$SIGNUP_EMAIL\",\"password\":\"test123\"}")

if echo "$SIGNUP_RESPONSE" | jq -e '.token' > /dev/null 2>&1; then
    TOKEN=$(echo "$SIGNUP_RESPONSE" | jq -r '.token')
    echo -e "${GREEN}✓ Signup passed, token received${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Signup failed${NC}"
    echo "$SIGNUP_RESPONSE" | jq '.' 2>/dev/null || echo "$SIGNUP_RESPONSE"
    ((FAILED++))
    TOKEN=""
fi

# 3. Login (if signup worked, try with same credentials)
if [ -n "$TOKEN" ]; then
    LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"$SIGNUP_EMAIL\",\"password\":\"test123\"}")
    
    if echo "$LOGIN_RESPONSE" | jq -e '.token' > /dev/null 2>&1; then
        TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
        echo -e "${GREEN}✓ Login passed${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ Login failed${NC}"
        ((FAILED++))
    fi
fi

# 4. Get User Profile (requires auth)
if [ -n "$TOKEN" ]; then
    test_endpoint "Get User Profile" "GET" "$BASE_URL/api/user/me" "" 200 \
        -H "Authorization: Bearer $TOKEN" || true
fi

# 5. Chat Endpoint (no auth)
test_endpoint "Chat (No Auth)" "POST" "$BASE_URL/api/chat" \
    '{"message":"I want coffee"}' 200

# 6. Chat Endpoint (with auth)
if [ -n "$TOKEN" ]; then
    CHAT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/chat" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d '{"message":"I want coffee","latitude":40.693393,"longitude":-73.98555}')
    
    if echo "$CHAT_RESPONSE" | jq -e '.reply' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Chat with auth passed${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ Chat with auth failed${NC}"
        ((FAILED++))
    fi
fi

# 7. Quick Recommendations
test_endpoint "Quick Recommendations" "GET" \
    "$BASE_URL/api/quick_recs?category=chill_cafes&limit=5" "" 200

# 8. Directions
test_endpoint "Directions" "GET" \
    "$BASE_URL/api/directions?lat=40.6942&lng=-73.9866" "" 200

# 9. Events
test_endpoint "NYU Engage Events" "GET" \
    "$BASE_URL/api/nyu_engage_events?days=7" "" 200

# 10. Error Handling - 404
test_endpoint "404 Not Found" "GET" "$BASE_URL/api/nonexistent" "" 404

# 11. Error Handling - 400 (missing field)
test_endpoint "400 Bad Request" "POST" "$BASE_URL/api/chat" '{}' 400

# Summary
echo -e "\n=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "=========================================="

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi

