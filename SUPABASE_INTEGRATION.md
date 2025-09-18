# Supabase Integration Guide

## Häufige Fehler und Lösungen

### SQL Schema Fehler

#### 1. Syntax Error bei deutschen Kommentaren
**Fehler:** `ERROR: 42601: syntax error at or near "aktivieren"`

**Problem:** Deutsche Kommentare ohne `--` Prefix werden als SQL Code interpretiert

**Lösung:** Alle Kommentare müssen mit `--` beginnen oder in `/* */` stehen
```sql
-- Korrekt
-- Row Level Security aktivieren
ALTER TABLE households ENABLE ROW LEVEL SECURITY;

-- Falsch
Row Level Security aktivieren
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
```

#### 2. Umlaute in Kommentaren vermeiden
**Problem:** Umlaute können in SQL Kommentaren Probleme verursachen

**Lösung:** Verwende ASCII-Zeichen in Kommentaren
```sql
-- Korrekt
-- Indizes fuer Performance

-- Problematisch
-- Indizes für Performance
```

## Implementierungs-Checkliste

### 1. Dependencies
- [x] `supabase_flutter: ^2.5.6` in pubspec.yaml
- [x] Supabase Client in main.dart initialisiert

### 2. Umgebungsvariablen
- [x] SUPABASE_URL in .env
- [x] SUPABASE_ANON_KEY in .env
- [x] .env in .gitignore

### 3. Datenbank Schema
- [x] households Tabelle
- [x] sub_keys Tabelle
- [x] foods Tabelle
- [x] Row Level Security Policies
- [x] Performance Indizes

### 4. Flutter Code
- [x] SupabaseDataSource implementiert
- [x] Repository Pattern erweitert
- [x] LocalKeyService Integration
- [x] Dependency Injection konfiguriert

### 5. Sicherheit
- [x] RLS Policies für Haushalts-Isolation
- [x] Master-Key und Sub-Key Authentifizierung
- [x] Keine Secrets im Code

## Architektur

### Datenfluss
1. **App Start:** Master-Key wird geladen/generiert
2. **Supabase:** Haushalt wird erstellt (falls neu)
3. **RLS Context:** Keys werden für Row Level Security gesetzt
4. **Data Operations:** Alle Operationen respektieren Haushalts-Grenzen

### Fallback-Strategie
- **Primary:** Supabase für Cloud-Sync
- **Fallback:** Lokale SQLite für Offline-Funktionalität
- **Hybrid:** Beide Systeme parallel für Robustheit

## Debugging Tipps

### 1. RLS Context prüfen
```sql
SELECT current_setting('app.current_master_key', true);
SELECT current_setting('app.current_sub_key', true);
```

### 2. Haushalts-Zugehörigkeit testen
```sql
-- Als Master-Key User
SELECT * FROM households WHERE master_key = 'DEIN_MASTER_KEY';

-- Als Sub-Key User
SELECT h.* FROM households h
JOIN sub_keys sk ON h.id = sk.household_id
WHERE sk.sub_key = 'DEIN_SUB_KEY';
```

### 3. Flutter Debug Logs
```dart
debugPrint('Current household: ${keyService.getCurrentHousehold()}');
debugPrint('Master key: ${keyService.getMasterKey()}');
```

## Bekannte Limitationen

1. **Offline-First:** Derzeit Supabase-first mit lokaler Fallback
2. **Konflikt-Resolution:** Noch nicht implementiert für parallele Edits
3. **Real-time Updates:** Noch nicht implementiert

## Nächste Schritte

1. Real-time Subscriptions für Live-Updates
2. Conflict Resolution für Offline-Online Sync
3. Bulk-Import für Migration existierender Daten
4. Performance Monitoring und Optimierung