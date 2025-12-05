# How to Run the User Profile Fields Migration

## Option 1: Run Migration Script (Recommended)

### For DigitalOcean Production Database:

1. **Get your DATABASE_URL from DigitalOcean:**
   - Go to your DigitalOcean dashboard
   - Navigate to your Managed PostgreSQL database
   - Copy the connection string (it will look like: `postgresql://user:password@host:port/database?sslmode=require`)

2. **Run the migration script:**
   ```bash
   cd server
   source venv/bin/activate  # If using virtual environment
   export DATABASE_URL='your-postgresql-connection-string-here'
   python3 migrations/migrate_user_profile_fields.py
   ```

### For Local Development:

If you have a local PostgreSQL database:

```bash
cd server
source venv/bin/activate
export DATABASE_URL='postgresql://user:password@localhost:5432/violetvibes'
python3 migrations/migrate_user_profile_fields.py
```

## Option 2: Run SQL Directly

If you prefer to run the SQL directly, connect to your PostgreSQL database and run:

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

### Using psql command line:

```bash
psql "your-postgresql-connection-string" -f migrations/add_user_profile_fields.sql
```

### Using DigitalOcean Database Console:

1. Go to your DigitalOcean dashboard
2. Navigate to your Managed PostgreSQL database
3. Click on "Console" or "Query" tab
4. Paste and run the SQL commands above

## Option 3: Use Flask-SQLAlchemy (Automatic)

Flask-SQLAlchemy will automatically create the columns when the app starts if you're using `db.create_all()`. However, this is not recommended for production as it may cause issues with existing data.

## Verification

After running the migration, verify it worked:

```sql
-- Check columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('first_name', 'home_address_encrypted');

-- Should return:
-- first_name | character varying
-- home_address_encrypted | text
```

## Notes

- The migration uses `IF NOT EXISTS`, so it's safe to run multiple times
- Existing users will have `NULL` for these fields initially
- Fields will be populated when users update their profile or on next login
- The migration script includes verification to confirm success
