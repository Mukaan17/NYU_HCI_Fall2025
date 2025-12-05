# Database Purge Scripts

⚠️ **WARNING: These scripts will DELETE ALL DATA from your database!**

## Available Methods

### Method 1: API Endpoint (Remote)

Purge the database via HTTP endpoint (for DigitalOcean).

#### Step 1: Set Purge Token

In DigitalOcean App Platform environment variables:
```
PURGE_TOKEN=your-secret-token-here
```

#### Step 2: Run Purge

**Using curl:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Purge-Token: your-secret-token-here" \
  -d '{"confirm": true}' \
  https://violet-vibes-uf2g7.ondigitalocean.app/api/purge/all
```

**Using the provided script:**
```bash
cd server/migrations
export BACKEND_URL="https://violet-vibes-uf2g7.ondigitalocean.app"
export PURGE_TOKEN="your-secret-token-here"
./purge_database.sh
```

#### Step 3: Check Status

Before/after purge, check database status:
```bash
curl https://violet-vibes-uf2g7.ondigitalocean.app/api/purge/status
```

### Method 2: Standalone Python Script (Local)

Run the purge script directly against the database.

#### Step 1: Set DATABASE_URL

```bash
export DATABASE_URL='postgresql://user:password@host:port/database?sslmode=require'
```

#### Step 2: Run Script

```bash
cd server/migrations
source ../venv/bin/activate  # If using virtual environment
python3 purge_database.py --confirm
```

The script will:
1. Require `--confirm` flag
2. Ask you to type "DELETE ALL DATA" to confirm
3. Show current user count
4. Delete all data
5. Verify the purge

### Method 3: SQL Direct (Most Dangerous)

Connect directly to PostgreSQL and run:

```sql
DELETE FROM users;
```

**⚠️ This has NO safety checks!**

## Available Endpoints

### `POST /api/purge/all`
Deletes ALL data from the database.

**Requirements:**
- `X-Purge-Token` header matching `PURGE_TOKEN` env var
- `{"confirm": true}` in request body

### `POST /api/purge/users`
Deletes all users (same as `/purge/all` for now).

**Requirements:**
- `X-Purge-Token` header matching `PURGE_TOKEN` env var
- `{"confirm": true}` in request body

### `GET /api/purge/status`
Get current database status (user count, etc.).

**No authentication required** (read-only).

## Safety Features

1. **Token Authentication**: Requires `PURGE_TOKEN` environment variable
2. **Explicit Confirmation**: Must send `{"confirm": true}` in request body
3. **Status Check**: Can check database status before purging
4. **Verification**: Scripts verify the purge was successful

## What Gets Deleted

- ✅ All users
- ✅ All user data (preferences, settings, activity)
- ✅ All encrypted home addresses
- ✅ Everything in the `users` table

**What Remains:**
- ✅ Database structure (tables, columns, indexes)
- ✅ Table schema

## Security Recommendations

1. **Set Strong Token**: Use a long, random string for `PURGE_TOKEN`
2. **Remove After Use**: Delete the purge endpoints after migration/testing
3. **Backup First**: Always backup your database before purging
4. **Use in Development Only**: Never use in production unless absolutely necessary

## Example: Full Purge Workflow

```bash
# 1. Check current status
curl https://violet-vibes-uf2g7.ondigitalocean.app/api/purge/status

# 2. Set token
export PURGE_TOKEN="my-secret-token-12345"

# 3. Run purge
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Purge-Token: my-secret-token-12345" \
  -d '{"confirm": true}' \
  https://violet-vibes-uf2g7.ondigitalocean.app/api/purge/all

# 4. Verify
curl https://violet-vibes-uf2g7.ondigitalocean.app/api/purge/status
```

## Troubleshooting

### "Unauthorized" Error
- Set `PURGE_TOKEN` environment variable
- Use the same token in `X-Purge-Token` header

### "Confirmation required" Error
- Make sure request body includes `{"confirm": true}`

### Connection Issues
- Verify your `DATABASE_URL` is correct
- Check that the app is running on DigitalOcean

## ⚠️ Final Warning

**This will permanently delete all data. There is no undo.**
**Always backup your database before running purge operations.**
