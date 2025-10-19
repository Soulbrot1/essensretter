-- ============================================================================
-- Share Codes Migration
-- ============================================================================
-- Purpose: Replace direct RetterId sharing with Share Codes
--
-- Why Share Codes?
-- - Users never expose their real RetterId when adding friends
-- - Users can regenerate their Share Code anytime (like changing a lock)
-- - Old Share Codes become invalid when regenerated
-- - Existing friendships remain unaffected
--
-- Example:
-- 1. User has RetterId "ER-A1B2C3D4"
-- 2. System generates Share Code "K8M5P2" (shorter, random)
-- 3. User shares "K8M5P2" with friends instead of RetterId
-- 4. If friend is removed, user clicks "Regenerate" -> new code "X9Q3R7"
-- 5. Old code "K8M5P2" no longer works
-- ============================================================================

-- Drop table if exists (for clean re-runs during development)
DROP TABLE IF EXISTS share_codes;

-- ============================================================================
-- Table: share_codes
-- ============================================================================
-- Maps Share Codes to RetterId (one-to-one relationship)
CREATE TABLE share_codes (
  -- The RetterId of the user (format: ER-XXXXXXXX)
  user_id TEXT PRIMARY KEY,

  -- The Share Code (format: 6 random alphanumeric characters, e.g., "A3F9B2")
  -- UNIQUE constraint ensures no two users have the same Share Code
  share_code TEXT UNIQUE NOT NULL,

  -- When this Share Code was created (for analytics/debugging)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraint: Share Code must be exactly 6 characters
  CONSTRAINT share_code_length CHECK (LENGTH(share_code) = 6),

  -- Constraint: Share Code must be alphanumeric uppercase
  CONSTRAINT share_code_format CHECK (share_code ~ '^[A-Z0-9]{6}$')
);

-- ============================================================================
-- Indexes
-- ============================================================================
-- Fast lookup by Share Code (most common operation: "find user by Share Code")
CREATE INDEX idx_share_codes_code ON share_codes(share_code);

-- ============================================================================
-- Row Level Security (RLS)
-- ============================================================================
-- Disable RLS for now (same strategy as backups table)
-- Share Codes act like public phone numbers - anyone can look them up
-- The actual friendship connection still requires both users to exist
ALTER TABLE share_codes DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Function: generate_share_code()
-- Generates a random 6-character Share Code (format: A3F9B2)
-- Uses Base36 charset (0-9, A-Z) for human-readability
CREATE OR REPLACE FUNCTION generate_share_code()
RETURNS TEXT AS $$
DECLARE
  charset TEXT := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  result TEXT := '';
  i INTEGER;
BEGIN
  -- Generate 6 random characters
  FOR i IN 1..6 LOOP
    result := result || substr(charset, floor(random() * length(charset) + 1)::int, 1);
  END LOOP;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function: ensure_unique_share_code()
-- Generates a unique Share Code (retries if collision detected)
-- Maximum 10 retries to prevent infinite loops
CREATE OR REPLACE FUNCTION ensure_unique_share_code()
RETURNS TEXT AS $$
DECLARE
  new_code TEXT;
  code_exists BOOLEAN;
  retry_count INTEGER := 0;
  max_retries INTEGER := 10;
BEGIN
  LOOP
    -- Generate candidate code
    new_code := generate_share_code();

    -- Check if code already exists
    SELECT EXISTS(SELECT 1 FROM share_codes WHERE share_code = new_code) INTO code_exists;

    -- If unique, return it
    IF NOT code_exists THEN
      RETURN new_code;
    END IF;

    -- Increment retry counter
    retry_count := retry_count + 1;

    -- Prevent infinite loop (extremely unlikely with 36^6 = 2.1 billion combinations)
    IF retry_count >= max_retries THEN
      RAISE EXCEPTION 'Failed to generate unique Share Code after % retries', max_retries;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Trigger: auto_create_share_code
-- ============================================================================
-- Automatically creates a Share Code when a user is registered in user_profiles
-- This ensures every user has a Share Code from the start
CREATE OR REPLACE FUNCTION auto_create_share_code()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert Share Code for new user
  INSERT INTO share_codes (user_id, share_code)
  VALUES (NEW.user_id, ensure_unique_share_code())
  ON CONFLICT (user_id) DO NOTHING; -- Ignore if already exists

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to user_profiles table
-- Note: Only creates trigger if user_profiles table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles') THEN
    DROP TRIGGER IF EXISTS trigger_auto_create_share_code ON user_profiles;
    CREATE TRIGGER trigger_auto_create_share_code
      AFTER INSERT ON user_profiles
      FOR EACH ROW
      EXECUTE FUNCTION auto_create_share_code();
  END IF;
END $$;

-- ============================================================================
-- Migration: Create Share Codes for existing users
-- ============================================================================
-- Backfill Share Codes for users who registered before this migration
DO $$
DECLARE
  user_record RECORD;
BEGIN
  -- Only if user_profiles exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles') THEN
    -- For each existing user without a Share Code
    FOR user_record IN
      SELECT user_id
      FROM user_profiles
      WHERE user_id NOT IN (SELECT user_id FROM share_codes)
    LOOP
      -- Create Share Code
      INSERT INTO share_codes (user_id, share_code)
      VALUES (user_record.user_id, ensure_unique_share_code());
    END LOOP;
  END IF;
END $$;

-- ============================================================================
-- Test Data (for development only - remove in production)
-- ============================================================================
-- Uncomment to test Share Code generation:
-- INSERT INTO share_codes (user_id, share_code)
-- VALUES ('ER-TEST0001', ensure_unique_share_code());
