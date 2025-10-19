-- Migration: Erstelle Share-Codes für alle existierenden User
-- Datum: 2025-10-18
-- Beschreibung: Fügt Share-Codes für User hinzu, die vor der share_codes Tabelle existierten

-- Erstelle Share-Codes für alle User die noch keinen haben
-- Nutzt die ensure_unique_share_code() Funktion aus Migration 008
INSERT INTO share_codes (user_id, share_code)
SELECT
    ud.user_id,
    ensure_unique_share_code()
FROM
    user_data ud
WHERE
    NOT EXISTS (
        SELECT 1
        FROM share_codes sc
        WHERE sc.user_id = ud.user_id
    )
ON CONFLICT (user_id) DO NOTHING;

-- Logging: Wie viele Share-Codes wurden erstellt?
DO $$
DECLARE
    created_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO created_count FROM share_codes;
    RAISE NOTICE 'Share-Codes erstellt: % insgesamt', created_count;
END $$;
