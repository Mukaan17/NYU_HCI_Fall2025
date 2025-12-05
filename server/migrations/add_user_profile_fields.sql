-- Migration: Add user profile fields (first_name, home_address_encrypted)
-- Run this migration to add the new fields to the users table

-- Add first_name column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS first_name VARCHAR(100);

-- Add home_address_encrypted column (TEXT to store encrypted data)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS home_address_encrypted TEXT;

-- Create index on first_name for faster lookups (optional)
CREATE INDEX IF NOT EXISTS idx_users_first_name ON users(first_name);

-- Note: Existing users will have NULL values for these fields
-- They will be populated when users update their profile or on next login
