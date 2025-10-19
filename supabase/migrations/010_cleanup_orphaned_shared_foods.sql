-- Migration: Bereinige verwaiste Lebensmittel-Angebote
-- Datum: 2025-10-18
-- Problem: Nach App-Neuinstallation existieren shared_foods ohne lokale Referenz

-- Lösche alle shared_foods Einträge
-- ACHTUNG: Dies löscht ALLE aktuell geteilten Lebensmittel!
-- User müssen ihre Lebensmittel neu teilen
DELETE FROM shared_foods;

-- Alternative: Nur Einträge löschen die älter als X Tage sind
-- DELETE FROM shared_foods WHERE created_at < NOW() - INTERVAL '7 days';

-- Logging
DO $$
BEGIN
    RAISE NOTICE 'Alle shared_foods wurden gelöscht. User müssen Lebensmittel neu teilen.';
END $$;
