#!/bin/bash
# Script to run database migration on DigitalOcean
# Usage: ./run_migration_digitalocean.sh

echo "============================================================"
echo "User Profile Fields Migration for DigitalOcean"
echo "============================================================"
echo ""

# Get the backend URL from environment or use default
BACKEND_URL="${BACKEND_URL:-https://violet-vibes-uf2g7.ondigitalocean.app}"
MIGRATION_TOKEN="${MIGRATION_TOKEN:-change-me-in-production}"

echo "Backend URL: $BACKEND_URL"
echo ""

# First, check migration status
echo "1. Checking current migration status..."
STATUS_RESPONSE=$(curl -s "${BACKEND_URL}/api/migrate/user-profile-fields/status")

if [ $? -eq 0 ]; then
    echo "   Status response: $STATUS_RESPONSE"
    MIGRATED=$(echo $STATUS_RESPONSE | grep -o '"migrated":[^,]*' | cut -d':' -f2)
    
    if [ "$MIGRATED" = "true" ]; then
        echo "   ✓ Migration already completed!"
        exit 0
    else
        echo "   ⚠ Migration not yet completed"
    fi
else
    echo "   ⚠ Could not check status (continuing anyway)"
fi

echo ""
echo "2. Running migration..."

# Run the migration
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -H "X-Migration-Token: ${MIGRATION_TOKEN}" \
    "${BACKEND_URL}/api/migrate/user-profile-fields")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "   HTTP Status: $HTTP_CODE"
echo "   Response: $BODY"

if [ "$HTTP_CODE" = "200" ]; then
    echo ""
    echo "============================================================"
    echo "✅ Migration completed successfully!"
    echo "============================================================"
    exit 0
else
    echo ""
    echo "============================================================"
    echo "❌ Migration failed!"
    echo "============================================================"
    echo ""
    echo "If you got a 401 error, set the MIGRATION_TOKEN:"
    echo "  export MIGRATION_TOKEN='your-secret-token'"
    echo ""
    echo "You can also run the SQL directly via DigitalOcean console:"
    echo "  See: migrations/add_user_profile_fields.sql"
    exit 1
fi
