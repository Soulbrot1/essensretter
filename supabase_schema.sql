-- ====================================================================
-- SUPABASE SCHEMA FÜR ESSENSRETTER SHARING-FEATURE
-- ====================================================================
-- Dieses Schema unterstützt alle geplanten Features:
-- 1. User-Registrierung und -Verwaltung
-- 2. Haushalte mit mehreren Teilnehmern
-- 3. QR-Code basiertes Teilen
-- 4. Geteilte Lebensmittel-Listen
-- 5. Zugriffskontrolle und Berechtigungen
-- ====================================================================

-- ====================================================================
-- 1. USERS TABLE - Basis-User-Verwaltung
-- ====================================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT UNIQUE NOT NULL, -- ER-XXXXXXXX Format
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  app_version TEXT,
  platform TEXT, -- 'ios', 'android', 'web'

  -- Metadaten für Analytics/Support
  device_info JSONB DEFAULT '{}',

  -- Index für schnelle Lookups
  CONSTRAINT user_id_format CHECK (user_id ~ '^ER-[A-Z0-9]{8}$')
);

CREATE INDEX idx_users_user_id ON users(user_id);
CREATE INDEX idx_users_last_active ON users(last_active_at);

-- ====================================================================
-- 2. HOUSEHOLDS TABLE - Haushalts-Verwaltung
-- ====================================================================
CREATE TABLE IF NOT EXISTS households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  household_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Einstellungen
  settings JSONB DEFAULT '{
    "allow_member_invites": false,
    "auto_delete_expired": false,
    "notification_settings": {}
  }',

  -- Statistiken (für spätere Features)
  stats JSONB DEFAULT '{
    "total_items_saved": 0,
    "total_items_wasted": 0
  }'
);

CREATE INDEX idx_households_owner ON households(owner_user_id);

-- ====================================================================
-- 3. HOUSEHOLD_MEMBERS TABLE - Haushaltsmitglieder
-- ====================================================================
CREATE TABLE IF NOT EXISTS household_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member', -- 'owner', 'admin', 'member', 'viewer'
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  invited_by TEXT REFERENCES users(user_id),

  -- Berechtigungen
  permissions JSONB DEFAULT '{
    "can_add": true,
    "can_edit": true,
    "can_delete": false,
    "can_invite": false
  }',

  -- Sicherstellen dass ein User nur einmal pro Haushalt existiert
  UNIQUE(household_id, user_id)
);

CREATE INDEX idx_members_household ON household_members(household_id);
CREATE INDEX idx_members_user ON household_members(user_id);

-- ====================================================================
-- 4. ACCESS_KEYS TABLE - QR-Code/Einladungslinks
-- ====================================================================
CREATE TABLE IF NOT EXISTS access_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  access_key TEXT UNIQUE NOT NULL, -- Generierter Schlüssel für QR-Code
  created_by TEXT NOT NULL REFERENCES users(user_id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ, -- Optional: Ablaufdatum

  -- Nutzungsbeschränkungen
  max_uses INTEGER DEFAULT NULL, -- NULL = unbegrenzt
  current_uses INTEGER DEFAULT 0,

  -- Status
  is_active BOOLEAN DEFAULT true,
  deactivated_at TIMESTAMPTZ,
  deactivated_by TEXT REFERENCES users(user_id),

  -- Berechtigungen für neue Mitglieder
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

-- ====================================================================
-- 5. SHARED_FOODS TABLE - Geteilte Lebensmittel
-- ====================================================================
CREATE TABLE IF NOT EXISTS shared_foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,

  -- Lebensmittel-Daten
  name TEXT NOT NULL,
  expiry_date DATE,
  added_date TIMESTAMPTZ DEFAULT NOW(),
  category TEXT,
  notes TEXT,
  quantity TEXT,

  -- Tracking
  added_by TEXT NOT NULL REFERENCES users(user_id),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by TEXT REFERENCES users(user_id),

  -- Status
  status TEXT DEFAULT 'active', -- 'active', 'consumed', 'wasted', 'deleted'
  status_changed_at TIMESTAMPTZ,
  status_changed_by TEXT REFERENCES users(user_id),

  -- Metadaten
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_shared_foods_household ON shared_foods(household_id);
CREATE INDEX idx_shared_foods_expiry ON shared_foods(expiry_date) WHERE status = 'active';
CREATE INDEX idx_shared_foods_status ON shared_foods(status);

-- ====================================================================
-- 6. ACTIVITY_LOG TABLE - Audit-Trail für alle Aktionen
-- ====================================================================
CREATE TABLE IF NOT EXISTS activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(user_id),
  action_type TEXT NOT NULL, -- 'food_added', 'food_consumed', 'member_joined', etc.
  action_details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Für Performance bei großen Datenmengen
  created_date DATE GENERATED ALWAYS AS (DATE(created_at)) STORED
);

CREATE INDEX idx_activity_household ON activity_log(household_id);
CREATE INDEX idx_activity_user ON activity_log(user_id);
CREATE INDEX idx_activity_date ON activity_log(created_date);

-- ====================================================================
-- 7. FUNCTIONS & TRIGGERS
-- ====================================================================

-- Auto-Update updated_at Timestamp
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

-- Funktion zum Registrieren/Aktualisieren eines Users
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

-- ====================================================================
-- 8. ROW LEVEL SECURITY (RLS)
-- ====================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE access_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- Policies für Anon-Zugriff (für unsere App ohne Auth)
-- WICHTIG: In Production sollte man authenticated users verwenden!

-- Users können sich selbst registrieren/updaten
CREATE POLICY "Anyone can register/update user" ON users
  FOR ALL USING (true) WITH CHECK (true);

-- Jeder kann Haushalte seiner User-ID sehen
CREATE POLICY "Users can view their households" ON households
  FOR SELECT USING (true);

-- Mitglieder können ihre Haushalte sehen
CREATE POLICY "Members can view their household members" ON household_members
  FOR SELECT USING (true);

-- Geteilte Lebensmittel sind für Haushaltsmitglieder sichtbar
CREATE POLICY "Members can view household foods" ON shared_foods
  FOR SELECT USING (true);

-- Access Keys können von jedem mit dem Key eingelöst werden
CREATE POLICY "Anyone can use valid access keys" ON access_keys
  FOR SELECT USING (is_active = true);

-- ====================================================================
-- 9. INITIAL DATA & TESTS
-- ====================================================================

-- Test-Funktion zum Prüfen ob Schema korrekt ist
CREATE OR REPLACE FUNCTION test_schema_ready() RETURNS BOOLEAN AS $$
BEGIN
  -- Prüfe ob alle wichtigen Tabellen existieren
  RETURN EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users')
    AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'households')
    AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'household_members')
    AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'shared_foods');
END;
$$ LANGUAGE plpgsql;

-- Kommentar mit Schema-Version für Migrationen
COMMENT ON SCHEMA public IS 'EssensRetter Sharing Schema v1.0.0';
