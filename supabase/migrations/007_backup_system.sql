-- ============================================================================
-- ESSENSRETTER BACKUP SYSTEM
-- ============================================================================
-- Version: 1.0
-- Date: 2025-01-16
-- Description: Snapshot-based backup system for RetterId-based data recovery
--
-- Architecture Principles:
-- - SQLite = Source of Truth (primary data source)
-- - Supabase = Snapshot Backup Storage (not live-sync)
-- - No multi-device sync (device migration only)
-- - Only latest backup per RetterId (upsert)
-- ============================================================================

-- ============================================================================
-- 1. EXTENSIONS
-- ============================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 2. MAIN BACKUP TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS backups (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- User Identification (RetterId Format: ER-XXXXXXXX)
  user_id TEXT NOT NULL,

  -- Backup Data (JSONB for better query capabilities)
  data JSONB NOT NULL,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  device_info TEXT,  -- Optional: e.g. "iPhone 14", "Samsung Galaxy S21"
  app_version TEXT,  -- Optional: e.g. "1.0.0"
  data_hash TEXT,    -- SHA-256 hash for integrity check

  -- Constraint: Only one backup per RetterId (latest overwrites old)
  UNIQUE(user_id)
);

-- ============================================================================
-- 3. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Main index for user lookups (during restore)
CREATE INDEX IF NOT EXISTS idx_backups_user_id
  ON backups(user_id);

-- Index for time-based queries (e.g. "Show recent backups")
CREATE INDEX IF NOT EXISTS idx_backups_created_at
  ON backups(created_at DESC);

-- GIN index for JSONB queries (in case we want to filter later)
CREATE INDEX IF NOT EXISTS idx_backups_data_gin
  ON backups USING GIN(data);

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS
ALTER TABLE backups ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can only read their own backups
CREATE POLICY "Users can read own backups"
  ON backups
  FOR SELECT
  USING (user_id = current_setting('app.user_id', true));

-- Policy 2: Users can only create/update their own backups
CREATE POLICY "Users can insert/update own backups"
  ON backups
  FOR INSERT
  WITH CHECK (user_id = current_setting('app.user_id', true));

CREATE POLICY "Users can update own backups"
  ON backups
  FOR UPDATE
  USING (user_id = current_setting('app.user_id', true))
  WITH CHECK (user_id = current_setting('app.user_id', true));

-- Policy 3: Users can only delete their own backups
CREATE POLICY "Users can delete own backups"
  ON backups
  FOR DELETE
  USING (user_id = current_setting('app.user_id', true));

-- ============================================================================
-- 5. TRIGGER FOR AUTOMATIC updated_at
-- ============================================================================

-- Function that automatically updates updated_at
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for backups table
CREATE TRIGGER update_backups_updated_at
  BEFORE UPDATE ON backups
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_column();

-- ============================================================================
-- 6. CLEANUP FUNCTION (Optional)
-- ============================================================================

-- Function to delete old backups (if we introduce history later)
CREATE OR REPLACE FUNCTION cleanup_old_backups(retention_days INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  WITH deleted AS (
    DELETE FROM backups
    WHERE created_at < NOW() - (retention_days || ' days')::INTERVAL
    RETURNING *
  )
  SELECT COUNT(*) INTO deleted_count FROM deleted;

  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 7. HELPER VIEWS (Optional, for monitoring)
-- ============================================================================

-- View: Backup statistics
CREATE OR REPLACE VIEW backup_stats AS
SELECT
  COUNT(*) as total_backups,
  COUNT(DISTINCT user_id) as unique_users,
  AVG(pg_column_size(data)) as avg_backup_size_bytes,
  MAX(created_at) as latest_backup,
  MIN(created_at) as oldest_backup
FROM backups;

-- ============================================================================
-- 8. GRANT PERMISSIONS
-- ============================================================================

-- Service Role has full access (for backend operations)
GRANT ALL ON backups TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_old_backups TO service_role;

-- Anon/Authenticated Role has access only via RLS policies
GRANT SELECT, INSERT, UPDATE, DELETE ON backups TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON backups TO authenticated;

-- ============================================================================
-- 9. COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE backups IS 'Snapshot backups of food and friends data per RetterId. Only latest backup per user_id is stored (UNIQUE constraint).';
COMMENT ON COLUMN backups.user_id IS 'RetterId in format ER-XXXXXXXX (Base36, 8 characters)';
COMMENT ON COLUMN backups.data IS 'JSONB with complete snapshot: {foods: [...], friends: [...], version: "1.0"}';
COMMENT ON COLUMN backups.data_hash IS 'SHA-256 hash of data field for integrity check';
COMMENT ON COLUMN backups.device_info IS 'Optional: Device name for debugging (e.g. "iPhone 14")';
COMMENT ON COLUMN backups.app_version IS 'Optional: App version at time of backup (e.g. "1.0.0")';

-- ============================================================================
-- 10. EXAMPLE QUERIES FOR TESTING
-- ============================================================================

-- Create/update backup (upsert)
/*
INSERT INTO backups (user_id, data, device_info, app_version, data_hash)
VALUES (
  'ER-ABC12345',
  '{
    "version": "1.0",
    "timestamp": "2025-01-16T10:00:00Z",
    "foods": [
      {"id": "1", "name": "Bell Pepper", "expiryDate": "2025-01-20"}
    ],
    "friends": [
      {"userId": "ER-XYZ78910", "displayName": "Anna"}
    ]
  }'::JSONB,
  'iPhone 14',
  '1.0.0',
  'abc123hash456'
)
ON CONFLICT (user_id)
DO UPDATE SET
  data = EXCLUDED.data,
  device_info = EXCLUDED.device_info,
  app_version = EXCLUDED.app_version,
  data_hash = EXCLUDED.data_hash;
*/

-- Retrieve backup (restore)
/*
SELECT data, created_at, device_info
FROM backups
WHERE user_id = 'ER-ABC12345';
*/

-- Delete backup (cleanup during restore)
/*
DELETE FROM backups
WHERE user_id = 'ER-OLD67890';
*/

-- Check backup size
/*
SELECT
  user_id,
  pg_size_pretty(pg_column_size(data)) as backup_size,
  created_at
FROM backups
ORDER BY created_at DESC
LIMIT 10;
*/

-- ============================================================================
-- END OF SCHEMA DEFINITION
-- ============================================================================
