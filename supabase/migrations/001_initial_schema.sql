-- ============================================================================
-- ESSENSRETTER INITIAL SCHEMA
-- ============================================================================
-- Version: 2.0.0 - Simplified for single-user sharing
-- Date: 2024-10-09
-- Description: Base tables for users, shared foods, access keys, and sessions
-- ============================================================================

-- ============================================================================
-- 1. USERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  user_id TEXT PRIMARY KEY,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  app_version TEXT,
  platform TEXT,
  device_info JSONB DEFAULT '{}',
  CONSTRAINT user_id_format CHECK (user_id ~ '^ER-[A-Z0-9]{8}$')
);

CREATE INDEX idx_users_last_active ON users(last_active_at);

COMMENT ON TABLE users IS 'Base user table for app installations, identified by RetterId';

-- ============================================================================
-- 2. SHARED_FOODS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS shared_foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  expiry_date DATE,
  added_date TIMESTAMPTZ DEFAULT NOW(),
  category TEXT,
  notes TEXT,
  quantity TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'active',
  status_changed_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_shared_foods_user ON shared_foods(user_id);
CREATE INDEX idx_shared_foods_expiry ON shared_foods(expiry_date) WHERE status = 'active';
CREATE INDEX idx_shared_foods_status ON shared_foods(status);

COMMENT ON TABLE shared_foods IS 'Foods shared by users with friends';

-- ============================================================================
-- 3. ACCESS_KEYS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS access_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  access_key TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  last_used_at TIMESTAMPTZ,
  use_count INTEGER DEFAULT 0,
  permissions TEXT DEFAULT 'read'
);

CREATE INDEX idx_access_keys_key ON access_keys(access_key) WHERE is_active = true;
CREATE INDEX idx_access_keys_user ON access_keys(user_id);

COMMENT ON TABLE access_keys IS 'QR-Code based sharing access keys';

-- ============================================================================
-- 4. SHARED_SESSIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS shared_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  viewer_user_id TEXT REFERENCES users(user_id) ON DELETE CASCADE,
  access_key TEXT NOT NULL REFERENCES access_keys(access_key),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_sessions_owner ON shared_sessions(owner_user_id);
CREATE INDEX idx_sessions_viewer ON shared_sessions(viewer_user_id);
CREATE INDEX idx_sessions_active ON shared_sessions(is_active);

COMMENT ON TABLE shared_sessions IS 'Active sharing sessions between users';

-- ============================================================================
-- 5. FUNCTIONS
-- ============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for shared_foods
CREATE TRIGGER update_shared_foods_updated_at BEFORE UPDATE ON shared_foods
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Upsert user function
CREATE OR REPLACE FUNCTION upsert_user(
  p_user_id TEXT,
  p_display_name TEXT DEFAULT NULL,
  p_app_version TEXT DEFAULT NULL,
  p_platform TEXT DEFAULT NULL,
  p_device_info JSONB DEFAULT '{}'
) RETURNS users AS $$
DECLARE
  v_user users;
BEGIN
  INSERT INTO users (user_id, display_name, app_version, platform, device_info, last_active_at)
  VALUES (p_user_id, p_display_name, p_app_version, p_platform, p_device_info, NOW())
  ON CONFLICT (user_id) DO UPDATE SET
    last_active_at = NOW(),
    app_version = COALESCE(EXCLUDED.app_version, users.app_version),
    platform = COALESCE(EXCLUDED.platform, users.platform),
    device_info = users.device_info || EXCLUDED.device_info
  RETURNING * INTO v_user;

  RETURN v_user;
END;
$$ LANGUAGE plpgsql;

-- Generate access key function
CREATE OR REPLACE FUNCTION generate_access_key(
  p_user_id TEXT,
  p_expires_hours INTEGER DEFAULT 24
) RETURNS TEXT AS $$
DECLARE
  v_access_key TEXT;
BEGIN
  -- Generate random 8-character key
  v_access_key := 'AK-' || substr(md5(random()::text), 1, 8);

  -- Insert access key
  INSERT INTO access_keys (user_id, access_key, expires_at)
  VALUES (p_user_id, v_access_key, NOW() + (p_expires_hours || ' hours')::INTERVAL);

  RETURN v_access_key;
END;
$$ LANGUAGE plpgsql;

-- Test function to verify schema readiness
CREATE OR REPLACE FUNCTION test_schema_ready() RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users')
    AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'shared_foods')
    AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'access_keys')
    AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'shared_sessions');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 6. ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE access_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_sessions ENABLE ROW LEVEL SECURITY;

-- Users policies (permissive for now)
CREATE POLICY "Anyone can register/update user" ON users
  FOR ALL USING (true) WITH CHECK (true);

-- Shared foods policies
CREATE POLICY "Users can manage their foods" ON shared_foods
  FOR ALL USING (true) WITH CHECK (true);

-- Access keys policies
CREATE POLICY "Access keys are public readable when active" ON access_keys
  FOR SELECT USING (is_active = true);

-- Sessions policies
CREATE POLICY "Sessions are readable" ON shared_sessions
  FOR SELECT USING (true);

-- ============================================================================
-- SCHEMA VERSION
-- ============================================================================

COMMENT ON SCHEMA public IS 'EssensRetter Simple Schema v2.0.0';
