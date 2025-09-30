-- SUPABASE RESET SCRIPT
-- Removes all existing tables and data before applying new schema

-- Drop all existing tables (in reverse dependency order)
DROP TABLE IF EXISTS activity_log CASCADE;
DROP TABLE IF EXISTS shared_sessions CASCADE;
DROP TABLE IF EXISTS shared_foods CASCADE;
DROP TABLE IF EXISTS access_keys CASCADE;
DROP TABLE IF EXISTS household_members CASCADE;
DROP TABLE IF EXISTS households CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop all functions
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS upsert_user(TEXT, TEXT, TEXT, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS generate_access_key(TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS test_schema_ready() CASCADE;

-- Drop all policies (they are dropped with tables via CASCADE)

-- Reset sequences if any exist
-- (UUID tables don't have sequences, but good to be thorough)

-- Clear any remaining schema comments
COMMENT ON SCHEMA public IS NULL;

-- Confirm cleanup
SELECT 'All tables and functions dropped successfully' AS status;
