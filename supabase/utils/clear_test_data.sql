-- SQL Script zum Löschen von Test-Daten aus Supabase
-- Führe dieses Script in deinem Supabase SQL Editor aus

-- 1. Zeige aktuelle Friend Connections an
SELECT * FROM user_connections;

-- 2. Zeige geteilte Foods an
SELECT * FROM shared_foods;

-- 3. Zeige Reservierungen an
SELECT * FROM food_reservations;

-- VORSICHT: Die folgenden Queries löschen alle Daten!
-- Kommentiere sie aus, wenn du sie ausführen möchtest

-- 4. Lösche alle Test-Reservierungen
-- DELETE FROM food_reservations;

-- 5. Lösche alle geteilten Foods
-- DELETE FROM shared_foods;

-- 6. Lösche alle Friend Connections
-- DELETE FROM user_connections;

-- Alternative: Lösche nur Daten für einen spezifischen User
-- Ersetze 'DEINE_USER_ID' mit deiner aktuellen User ID
-- DELETE FROM food_reservations WHERE provider_id = 'DEINE_USER_ID' OR reserved_by = 'DEINE_USER_ID';
-- DELETE FROM shared_foods WHERE user_id = 'DEINE_USER_ID';
-- DELETE FROM user_connections WHERE user_id = 'DEINE_USER_ID' OR friend_id = 'DEINE_USER_ID';
