# Supabase Database Schema

Dieses Verzeichnis enthält alle Supabase-Datenbankmigrationen und Utility-Scripts für das EssensRetter Sharing-Feature und Backup-System.

## 📁 Struktur

```
/supabase/
├── migrations/           # Datenbankmigrationen (in chronologischer Reihenfolge)
│   ├── 001_initial_schema.sql
│   ├── 002_user_connections_table.sql
│   ├── 003_food_reservations_table.sql
│   ├── 004_fix_food_reservations_rls.sql
│   ├── 005_enforce_single_reservation_per_food.sql
│   ├── 006_remove_friend_name_column.sql
│   └── 007_backup_system.sql
│
├── utils/                # Utility-Scripts für Wartung
│   ├── reset_database.sql
│   └── clear_test_data.sql
│
└── README.md             # Diese Datei
```

## 🗂️ Migrations-Übersicht

### 001_initial_schema.sql (v2.0.0)
**Erstellt:** 2024-10-09
**Beschreibung:** Basis-Schema für Supabase

**Tabellen:**
- `users` - Nutzer-Registrierung (RetterId-basiert)
- `shared_foods` - Geteilte Lebensmittel
- `access_keys` - QR-Code-basierte Zugriffsschlüssel
- `shared_sessions` - Aktive Sharing-Sessions

**Funktionen:**
- `update_updated_at_column()` - Auto-Update Trigger
- `upsert_user()` - User-Registrierung/Update
- `generate_access_key()` - QR-Code Generierung
- `test_schema_ready()` - Schema-Validierung

---

### 002_user_connections_table.sql
**Erstellt:** 2024-10-09
**Beschreibung:** Friends-Feature (bidirektionale Verbindungen)

**Tabellen:**
- `user_connections` - Freundschaftsverbindungen zwischen Nutzern

**Features:**
- Bidirektionale Friend-Connections
- Status-Verwaltung (connected, blocked, pending)
- RLS Policies für Datenschutz
- Helper-Funktion für bidirektionale Verbindungen

---

### 003_food_reservations_table.sql
**Erstellt:** 2024-10-09
**Beschreibung:** Reservierungs-System für geteilte Lebensmittel

**Tabellen:**
- `food_reservations` - Reservierungen von geteilten Foods

**Features:**
- User können Foods ihrer Friends reservieren
- Provider-Tracking (wer hat das Food geteilt)
- Reserved-by Tracking (wer hat reserviert)
- Zeitstempel für Reservierungen

---

### 004_fix_food_reservations_rls.sql
**Erstellt:** 2024-10-09
**Beschreibung:** Korrektur der RLS Policies für food_reservations

**Änderungen:**
- Verbesserte Row Level Security
- Erlaubt Providern Zugriff auf ihre Reservierungen
- Erlaubt Nutzern Zugriff auf eigene Reservierungen

---

### 005_enforce_single_reservation_per_food.sql
**Erstellt:** 2024-10-09
**Beschreibung:** Constraint für Single-Reservation pro Food

**Änderungen:**
- UNIQUE Constraint: Nur eine Reservierung pro `shared_food_id`
- Verhindert Doppel-Reservierungen
- Sichert Datenintegrität

---

### 006_remove_friend_name_column.sql
**Erstellt:** 2024-10-09
**Beschreibung:** Entfernt deprecated `friend_name` Spalte

**Änderungen:**
- Migration zu lokalem `friend_name` Storage (via LocalFriendNamesService)
- Entfernt Spalte aus `user_connections`
- Cleanup obsoleter Code

---

### 007_backup_system.sql
**Erstellt:** 2025-01-16
**Beschreibung:** Snapshot-Backup-System für RetterId-basierte Datenwiederherstellung

**Tabellen:**
- `backups` - JSONB-basierte Snapshot-Backups

**Features:**
- Automatisches Backup bei App-Schließen
- Hash-Check zur Traffic-Optimierung (-70%)
- RLS Policies (User können nur eigene Backups lesen/schreiben)
- Cleanup-Funktion für alte Backups
- Monitoring-Views (`backup_stats`)

**Architektur:**
- SQLite = Source of Truth (primäre Datenquelle)
- Supabase = Snapshot-Backup-Storage (nicht Live-Sync)
- Nur neuestes Backup pro RetterId (UNIQUE constraint)

## 🚀 Migrations ausführen

### Option 1: Supabase Dashboard (Empfohlen)

1. Öffne [Supabase Dashboard](https://app.supabase.com)
2. Gehe zu deinem Projekt
3. Navigiere zu **SQL Editor**
4. Kopiere den Inhalt der Migration-Datei
5. Führe das Script aus

### Option 2: Supabase CLI

```bash
# Alle Migrations in Reihenfolge ausführen
supabase db push

# Einzelne Migration ausführen
supabase db execute --file supabase/migrations/001_initial_schema.sql
```

## 🛠️ Utility Scripts

### reset_database.sql
Löscht **alle** Tabellen und Daten.

⚠️ **VORSICHT:** Nur in Development verwenden!

```sql
-- Führe in Supabase SQL Editor aus
\i supabase/utils/reset_database.sql
```

### clear_test_data.sql
Löscht nur Test-Daten (behält Schema bei).

```sql
-- Führe in Supabase SQL Editor aus
\i supabase/utils/clear_test_data.sql
```

## 📋 Neue Migration hinzufügen

1. Erstelle neue Datei: `supabase/migrations/00X_beschreibung.sql`
2. Nummeriere chronologisch (nächste freie Nummer)
3. Dokumentiere in diesem README
4. Führe Migration in Supabase aus
5. Committe Änderungen

**Template:**
```sql
-- ============================================================================
-- MIGRATION NAME
-- ============================================================================
-- Version: X.X.X
-- Date: YYYY-MM-DD
-- Description: Was macht diese Migration?
-- ============================================================================

-- Deine SQL-Statements hier

COMMENT ON TABLE tabelle_name IS 'Beschreibung';
```

## 🔍 Schema-Validierung

Nach Ausführung aller Migrations kannst du testen:

```sql
-- Prüfe ob alle Basis-Tabellen existieren
SELECT test_schema_ready();

-- Zeige alle Tabellen
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Zeige Backup-Statistiken
SELECT * FROM backup_stats;
```

## 📚 Weiterführende Dokumentation

- [Supabase Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Migrations Best Practices](https://www.postgresql.org/docs/current/ddl-alter.html)
- [EssensRetter Feature Spec](../docs/RETTER_ID_FEATURE_SPEC.md)

## ⚠️ Wichtige Hinweise

- **Migrations sind immutable**: Ändere niemals eine bereits ausgeführte Migration
- **Backup vor Änderungen**: Immer Supabase-Backup erstellen vor größeren Änderungen
- **Teste lokal**: Nutze Supabase Local Development für Tests
- **RLS beachten**: Alle Tabellen sollten Row Level Security haben
