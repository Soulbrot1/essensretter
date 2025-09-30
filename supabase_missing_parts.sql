-- MISSING PARTS FOR SUPABASE
-- Nur die fehlenden Funktionen hinzufügen

-- 1. Upsert user function (FEHLT)
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

-- 2. Test function (FALLS FEHLT)
CREATE OR REPLACE FUNCTION test_schema_ready() RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users')
    AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'shared_foods');
END;
$$ LANGUAGE plpgsql;

-- 3. Prüfe ob shared_foods Tabelle existiert (FALLS FEHLT)
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

-- 4. Trigger für update_at (FALLS FEHLT)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_shared_foods_updated_at BEFORE UPDATE ON shared_foods
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. Indices (FALLS FEHLEN)
CREATE INDEX IF NOT EXISTS idx_shared_foods_user ON shared_foods(user_id);
CREATE INDEX IF NOT EXISTS idx_shared_foods_expiry ON shared_foods(expiry_date) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_shared_foods_status ON shared_foods(status);
