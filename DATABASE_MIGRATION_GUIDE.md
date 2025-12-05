# Database Migration Guide: User Profile Data

## Overview

User data (first_name, home_address, preferences) is now stored in PostgreSQL database with encryption for sensitive fields. This ensures complete isolation between users and proper session management.

## Changes Made

### Backend Changes

1. **Database Model Updates** (`server/models/users.py`):
   - Added `first_name` column (VARCHAR(100))
   - Added `home_address_encrypted` column (TEXT) - stores encrypted home address
   - Added encryption/decryption methods for home address

2. **Encryption Utility** (`server/utils/encryption.py`):
   - Uses Fernet (symmetric encryption) from `cryptography` library
   - Key derived from `JWT_SECRET` using PBKDF2
   - Encrypts/decrypts home address data

3. **API Endpoints**:
   - `POST /api/auth/signup` - Now accepts `first_name` in request body
   - `GET /api/auth/login` - Returns `first_name` and `home_address` (decrypted) in response
   - `GET /api/auth/signup` - Returns `first_name` and `home_address` (decrypted) in response
   - `GET /api/user/me` - Returns `first_name` and `home_address` (decrypted)
   - `GET /api/user/profile` - Get user profile (first_name, home_address)
   - `POST /api/user/profile` - Update user profile (first_name, home_address)

4. **Dependencies**:
   - Added `cryptography==42.0.5` to `requirements.txt`

### iOS App Changes

1. **API Models**:
   - `AuthUserPayload` now includes `first_name` and `home_address`
   - Added `UserProfileResponse` model

2. **API Service**:
   - `signup()` now accepts optional `firstName` parameter
   - Added `fetchUserProfile()` method
   - Added `saveUserProfile()` method

3. **Login/Signup Flow**:
   - On signup: Sends `first_name` to backend
   - On login/signup: Fetches `first_name` and `home_address` from backend response
   - Saves user data to local storage (for offline access)
   - Checks onboarding status from backend preferences

4. **Account Settings**:
   - Home address is saved to backend when changed
   - Falls back to local storage if backend unavailable

5. **Onboarding Survey**:
   - Preferences are saved to backend
   - Onboarding completion is determined by presence of meaningful preferences

## Database Migration

### Step 1: Run Migration SQL

Connect to your PostgreSQL database and run:

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

### Step 2: Verify Migration

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

### Step 3: Test

1. Sign up a new user - should save `first_name` to database
2. Set home address - should be encrypted and stored
3. Log out and log back in - should retrieve data from database
4. Verify data isolation - different users should see different data

## Security

### Encryption

- **Home Address**: Encrypted using Fernet (AES-128 in CBC mode)
- **Key Derivation**: PBKDF2-HMAC-SHA256 from `JWT_SECRET`
- **Password**: Already encrypted with bcrypt (unchanged)

### Data Isolation

- Each user's data is stored in separate database rows
- User identification via `id` (primary key) and `email` (unique)
- No shared storage between users
- Onboarding status is user-specific (determined by preferences)

## Testing Checklist

- [ ] Database migration SQL executed successfully
- [ ] New user signup saves `first_name` to database
- [ ] Home address is encrypted in database
- [ ] Home address is decrypted when retrieved
- [ ] Login retrieves user data from database
- [ ] Different users see different data (isolation)
- [ ] Onboarding survey doesn't show for returning users
- [ ] Preferences are saved to backend
- [ ] Profile updates (first_name, home_address) work

## Rollback Plan

If issues occur, you can:

1. **Remove new columns** (data will be lost):
   ```sql
   ALTER TABLE users DROP COLUMN IF EXISTS first_name;
   ALTER TABLE users DROP COLUMN IF EXISTS home_address_encrypted;
   ```

2. **Revert code changes** to previous version

3. **Data will fall back to local storage** (iOS app has fallback logic)

## Notes

- Existing users will have `NULL` for `first_name` and `home_address_encrypted`
- These will be populated when users update their profile
- The code handles missing columns gracefully (for gradual migration)
- Encryption key is derived from `JWT_SECRET` - ensure it's strong and secure
