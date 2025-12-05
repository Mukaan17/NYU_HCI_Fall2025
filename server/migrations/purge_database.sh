#!/bin/bash
# Script to purge database via API endpoint
# Usage: ./purge_database.sh

echo "============================================================"
echo "⚠️  DATABASE PURGE SCRIPT - DANGEROUS OPERATION"
echo "============================================================"
echo ""
echo "This will DELETE ALL DATA from the database!"
echo "This action CANNOT be undone!"
echo ""

# Get the backend URL from environment or use default
BACKEND_URL="${BACKEND_URL:-https://violet-vibes-uf2g7.ondigitalocean.app}"
PURGE_TOKEN="${PURGE_TOKEN:-NEVER-USE-THIS-DEFAULT}"

echo "Backend URL: $BACKEND_URL"
echo ""

# First, check database status
echo "1. Checking current database status..."
STATUS_RESPONSE=$(curl -s "${BACKEND_URL}/api/purge/status")

if [ $? -eq 0 ]; then
    echo "   Status response: $STATUS_RESPONSE"
    USER_COUNT=$(echo $STATUS_RESPONSE | grep -o '"user_count":[^,]*' | cut -d':' -f2)
    echo "   Current user count: $USER_COUNT"
else
    echo "   ⚠ Could not check status"
fi

echo ""
echo "⚠️  WARNING: You are about to DELETE ALL DATA!"
echo ""
read -p "Type 'DELETE ALL DATA' to confirm: " CONFIRM

if [ "$CONFIRM" != "DELETE ALL DATA" ]; then
    echo ""
    echo "❌ Confirmation text did not match. Aborting."
    exit 1
fi

echo ""
echo "2. Purging database..."

# Run the purge
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -H "X-Purge-Token: ${PURGE_TOKEN}" \
    -d '{"confirm": true}' \
    "${BACKEND_URL}/api/purge/all")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "   HTTP Status: $HTTP_CODE"
echo "   Response: $BODY"

if [ "$HTTP_CODE" = "200" ]; then
    echo ""
    echo "============================================================"
    echo "✅ Database purged successfully!"
    echo "============================================================"
    exit 0
else
    echo ""
    echo "============================================================"
    echo "❌ Purge failed!"
    echo "============================================================"
    echo ""
    echo "If you got a 401 error, set the PURGE_TOKEN:"
    echo "  export PURGE_TOKEN='your-secret-token'"
    exit 1
fi
