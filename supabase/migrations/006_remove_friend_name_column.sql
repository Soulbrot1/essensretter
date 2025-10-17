-- Migration: Entferne friend_name Spalte aus user_connections Tabelle
-- Grund: Datenschutz - Namen werden jetzt nur lokal gespeichert

-- Schritt 1: Entferne die friend_name Spalte
ALTER TABLE user_connections
DROP COLUMN IF EXISTS friend_name;

-- Schritt 2: Kommentar hinzufügen für Dokumentation
COMMENT ON TABLE user_connections IS 'Speichert Friend-Verbindungen zwischen Nutzern. Namen werden lokal auf den Geräten gespeichert, nicht hier.';

-- Bestätige die Änderung
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'user_connections'
  AND table_schema = 'public'
ORDER BY ordinal_position;
