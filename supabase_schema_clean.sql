-- ESSENSRETTER SHARING FEATURE SCHEMA
-- Version 1.0.0

-- 1. USERS TABLE
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

-- 2. HOUSEHOLDS TABLE
CREATE TABLE IF NOT EXISTS households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  household_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  settings JSONB DEFAULT '{
    "allow_member_invites": false,
    "auto_delete_expired": false,
    "notification_settings": {}
  }',
  stats JSONB DEFAULT '{
    "total_items_saved": 0,
    "total_items_wasted": 0
  }'
);

CREATE INDEX idx_households_owner ON households(owner_user_id);

-- 3. HOUSEHOLD_MEMBERS TABLE
CREATE TABLE IF NOT EXISTS household_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  invited_by TEXT REFERENCES users(user_id),
  permissions JSONB DEFAULT '{
    "can_add": true,
    "can_edit": true,
    "can_delete": false,
    "can_invite": false
  }',
  UNIQUE(household_id, user_id)
);

CREATE INDEX idx_members_household ON household_members(household_id);
CREATE INDEX idx_members_user ON household_members(user_id);

-- 4. ACCESS_KEYS TABLE
CREATE TABLE IF NOT EXISTS access_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  access_key TEXT UNIQUE NOT NULL,
  created_by TEXT NOT NULL REFERENCES users(user_id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  max_uses INTEGER DEFAULT NULL,
  current_uses INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  deactivated_at TIMESTAMPTZ,
  deactivated_by TEXT REFERENCES users(user_id),
  grant_role TEXT DEFAULT 'member',
  grant_permissions JSONB DEFAULT '{
    "can_add": true,
    "can_edit": true,
    "can_delete": false,
    "can_invite": false
  }'
);

CREATE INDEX idx_access_keys_key ON access_keys(access_key) WHERE is_active = true;
CREATE INDEX idx_access_keys_household ON access_keys(household_id);

-- 5. SHARED_FOODS TABLE
CREATE TABLE IF NOT EXISTS shared_foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  expiry_date DATE,
  added_date TIMESTAMPTZ DEFAULT NOW(),
  category TEXT,
  notes TEXT,
  quantity TEXT,
  added_by TEXT NOT NULL REFERENCES users(user_id),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by TEXT REFERENCES users(user_id),
  status TEXT DEFAULT 'active',
  status_changed_at TIMESTAMPTZ,
  status_changed_by TEXT REFERENCES users(user_id),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_shared_foods_household ON shared_foods(household_id);
CREATE INDEX idx_shared_foods_expiry ON shared_foods(expiry_date) WHERE status = 'active';
CREATE INDEX idx_shared_foods_status ON shared_foods(status);

-- 6. ACTIVITY_LOG TABLE
CREATE TABLE IF NOT EXISTS activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(user_id),
  action_type TEXT NOT NULL,
  action_details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_date DATE GENERATED ALWAYS AS (DATE(created_at)) STORED
);

CREATE INDEX idx_activity_household ON activity_log(household_id);
CREATE INDEX idx_activity_user ON activity_log(user_id);
CREATE INDEX idx_activity_date ON activity_log(created_date);

-- 7. FUNCTIONS & TRIGGERS

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_households_updated_at BEFORE UPDATE ON households
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shared_foods_updated_at BEFORE UPDATE ON shared_foods
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- UPSERT USER FUNCTION
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

-- 8. ROW LEVEL SECURITY

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE access_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- Basic policies for anon access
CREATE POLICY "Anyone can register/update user" ON users
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Users can view their households" ON households
  FOR SELECT USING (true);

CREATE POLICY "Members can view their household members" ON household_members
  FOR SELECT USING (true);

CREATE POLICY "Members can view household foods" ON shared_foods
  FOR SELECT USING (true);

CREATE POLICY "Anyone can use valid access keys" ON access_keys
  FOR SELECT USING (is_active = true);

-- 9. TEST FUNCTION
CREATE OR REPLACE FUNCTION test_schema_ready() RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users')
    AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'households')
    AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'household_members')
    AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'shared_foods');
END;
$$ LANGUAGE plpgsql;

COMMENT ON SCHEMA public IS 'EssensRetter Sharing Schema v1.0.0';
