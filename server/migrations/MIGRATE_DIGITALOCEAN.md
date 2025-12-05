# Migrate Database on DigitalOcean

This guide provides multiple ways to run the database migration on DigitalOcean.

## Option 1: Use Migration Endpoint (Easiest)

The app now includes a migration endpoint that you can call once to migrate the database.

### Step 1: Set Migration Token (Optional but Recommended)

In your DigitalOcean App Platform environment variables, add:
```
MIGRATION_TOKEN=your-secret-token-here
```

Or if running locally against production:
```bash
export MIGRATION_TOKEN='your-secret-token-here'
```

### Step 2: Run Migration

**Using curl:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Migration-Token: your-secret-token-here" \
  https://violet-vibes-uf2g7.ondigitalocean.app/api/migrate/user-profile-fields
```

**Using the provided script:**
```bash
cd server/migrations
export BACKEND_URL="https://violet-vibes-uf2g7.ondigitalocean.app"
export MIGRATION_TOKEN="your-secret-token-here"
./run_migration_digitalocean.sh
```

### Step 3: Verify Migration

Check migration status:
```bash
curl https://violet-vibes-uf2g7.ondigitalocean.app/api/migrate/user-profile-fields/status
```

## Option 2: Run SQL Directly via DigitalOcean Console

### Step 1: Access Database Console

1. Go to [DigitalOcean Dashboard](https://cloud.digitalocean.com)
2. Navigate to **Databases** → Your PostgreSQL database
3. Click on **Console** or **Query** tab

### Step 2: Run Migration SQL

Copy and paste this SQL:

```sql
-- Add first_name column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS first_name VARCHAR(100);

-- Add home_address_encrypted column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS home_address_encrypted TEXT;

-- Create index on first_name (optional, for faster lookups)
CREATE INDEX IF NOT EXISTS idx_users_first_name ON users(first_name);
```

### Step 3: Verify

Run this to verify the columns were added:

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('first_name', 'home_address_encrypted');
```

Should return:
```
first_name              | character varying
home_address_encrypted  | text
```

## Option 3: Use DigitalOcean CLI (doctl)

If you have `doctl` installed:

```bash
# Get database connection info
doctl databases connection your-database-id

# Connect and run migration
psql "your-connection-string" -f migrations/add_user_profile_fields.sql
```

## Option 4: Automatic via Flask-SQLAlchemy

If your app uses `db.create_all()` (which it does), the columns will be created automatically when the app restarts. However, this is less explicit and harder to verify.

To trigger this:
1. Restart your app on DigitalOcean
2. The columns will be created automatically

## Security Note

After migration is complete, you can:
1. Remove the migration endpoint (delete `routes/migration_routes.py`)
2. Or keep it but ensure `MIGRATION_TOKEN` is strong and secret
3. The endpoint requires the token, so it's reasonably secure

## Troubleshooting

### "Unauthorized" Error
- Make sure you set `MIGRATION_TOKEN` environment variable
- Make sure you're sending it in the `X-Migration-Token` header

### "Connection Refused"
- Check that your app is running on DigitalOcean
- Verify the BACKEND_URL is correct

### Columns Already Exist
- The migration uses `IF NOT EXISTS`, so it's safe to run multiple times
- You'll get a success message even if columns already exist

## What Gets Migrated

- ✅ `first_name` column (VARCHAR(100)) - stores user's first name
- ✅ `home_address_encrypted` column (TEXT) - stores encrypted home address
- ✅ Index on `first_name` - for faster lookups

## After Migration

1. ✅ Test signup - new users should save `first_name`
2. ✅ Test home address - addresses should be encrypted in database
3. ✅ Test login - should retrieve user data from database
4. ✅ Verify isolation - different users see different data

Existing users will have `NULL` for these fields until they update their profile.
