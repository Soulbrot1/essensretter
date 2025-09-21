# Multi-User Feature Spezifikation
**EssensRetter App - Household Management**

---

## 📋 Übersicht

Diese Spezifikation beschreibt das Multi-User-Feature für die EssensRetter App, das es mehreren Personen ermöglicht, einen gemeinsamen Lebensmittel-Haushalt zu verwalten.

### Kernziele
- **Familien-freundlich**: Einfache Nutzung ohne komplexe Registrierung
- **Datenschutz-fokussiert**: Anonyme Key-basierte Authentifizierung
- **Gleichberechtigt**: Alle Haushaltsmitglieder haben gleiche Rechte bei Lebensmitteln
- **Master-kontrolliert**: Nur Master kann Mitglieder verwalten
- **Skalierbar**: Start mit 1000 Haushalten, später bis 100k Nutzer
- **Erweiterbar**: Grundsteine für zukünftiges "Verschenk-Feature"

### Feature-Evolution
```
Phase 1 (MVP):       Household-Management (Kern-Feature)
Phase 2 (Später):    Verschenk-Feature (nutzt gleiche Grundlagen)

MVP (Start):     1.000 Haushalte × 50 Foods = 50k Records
Vollversion:   100.000 Nutzer × 150 Foods = 6M Records

→ Gleiche Key-basierte Architektur für beide Features
```

---

## 🎯 Problem & Lösung

### Problem
- Familien nutzen verschiedene Geräte für Lebensmittel-Management
- Jeder hat eigene Listen → Keine gemeinsame Übersicht
- Doppelte Einkäufe, vergessene Lebensmittel
- Komplexe Multi-User-Systeme sind familienunfreundlich

### Lösung: Dual-Mode System
```
Master-Mode: Eigener Haushalt mit vollem Admin-Zugang
Sub-Mode: Beitritt zu fremdem Haushalt mit allen Rechten außer User-Management
```

---

## 👥 User Stories

### Als Master-User möchte ich...
- [x] **Automatisch einen Haushalt** beim ersten App-Start erstellen
- [x] **Sub-Keys generieren** um Familie einzuladen
- [x] **Sub-Users verwalten** (aktivieren/deaktivieren)
- [x] **Vollzugriff auf alle Features** haben

### Als Sub-User möchte ich...
- [x] **Mit einem Code beitreten** ohne E-Mail/Registrierung
- [x] **Lebensmittel gleichberechtigt verwalten** wie der Master
- [x] **Statistiken und Rezepte nutzen** können
- [x] **Jederzeit den Haushalt verlassen** können
- [x] **Zu meinem eigenen Haushalt zurückkehren** können

### Als Familie möchten wir...
- [x] **Real-time Synchronisation** zwischen allen Geräten
- [x] **Offline-Funktionalität** mit Sync bei Verbindung
- [x] **Einfache QR-Code Einladungen** verwenden
- [x] **Gleiche Berechtigungen** für alle Alltagsaufgaben

---

## 🏗️ Technische Architektur

### Authentifizierung: Anonyme Key-basierte Identifikation

#### Master-Key System
```
App-Installation → Generiere Master-Key (UUID) → Erstelle Haushalt
                 ↓
             Speichere Key lokal (SharedPreferences/Keychain)
                 ↓
        Master-Key = Identität + Admin-Berechtigung
```

#### Sub-Key System
```
Master erstellt Sub-Key → QR-Code/Text → Sub-User scannt/eingibt
                        ↓
                 Sub-Key = Beitritts-Token
                        ↓
             Sub-User wird Haushaltsmitglied (permanenter Zugang)
```

### Dual-Mode Architektur

#### Mode-Detection Logic (erweitert für zukünftige Features)
```dart
enum AppMode {
  master,        // Eigener Haushalt
  sub,           // Fremder Haushalt
  noHousehold    // Noch kein Haushalt
  // Später: donationViewer // Verschenk-Modus
}

enum ViewMode {
  household,     // Standard-Haushalt-Ansicht
  donations      // Verschenk-Ansicht (später)
}

Future<AppMode> getCurrentMode() async {
  final deviceKey = await getDeviceKey();
  final membership = await getActiveMembership(deviceKey);

  if (membership == null) return AppMode.noHousehold;
  return membership.role == 'master' ? AppMode.master : AppMode.sub;
}

// Vorbereitet für Verschenk-Feature
Future<List<AccessKey>> getAvailableAccessKeys() async {
  // Gibt alle verfügbaren Keys zurück (Sub-User + später Donation-Keys)
  return await supabase
    .from('access_keys')
    .select()
    .eq('is_active', true);
}
```

#### Mode-Switching Behavior
```
Master-Mode: Vollzugriff + User-Management
     ↓ (Sub-Key beitreten)
Sub-Mode: Vollzugriff - User-Management + Master-Key pausiert
     ↓ (Haushalt verlassen)
Master-Mode: Zurück zum eigenen Haushalt
```

---

## 🗄️ Datenbankschema

### Core Tables

```sql
-- Geräte-Identifikation
CREATE TABLE device_keys (
  key UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Haushalte
CREATE TABLE households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT 'Mein Haushalt',
  master_device_key UUID REFERENCES device_keys(key) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Generisches Key-System (für Sub-User UND zukünftige Features)
CREATE TABLE access_keys (
  key UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  created_by UUID REFERENCES device_keys(key),

  -- Erweiterbares Key-System
  key_type TEXT CHECK (key_type IN ('sub_user', 'donation_viewer')) NOT NULL,
  label TEXT, -- "Papa", "Mama", "Kind 1" oder "Nachbarschaft", "Kita"
  permissions JSONB DEFAULT '{}', -- Flexible Berechtigungen für zukünftige Features

  -- Lifecycle Management
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  revoked_reason TEXT CHECK (revoked_reason IN (
    'revoked_by_master',
    'user_left',
    'expired'
  )),

  -- Usage Tracking
  times_used INTEGER DEFAULT 0,
  max_uses INTEGER DEFAULT 1
);

-- Haushaltsmitgliedschaften (erweitert für zukünftige Features)
CREATE TABLE household_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_key UUID REFERENCES device_keys(key) ON DELETE CASCADE,
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  access_key_used UUID REFERENCES access_keys(key), -- Generischer Verweis

  role TEXT CHECK (role IN ('master', 'sub')) NOT NULL,
  is_active BOOLEAN DEFAULT true,

  -- Ein Gerät kann nur einem Haushalt aktiv angehören
  UNIQUE(device_key, is_active) WHERE is_active = true,

  joined_at TIMESTAMPTZ DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  left_reason TEXT CHECK (left_reason IN ('voluntary', 'revoked'))
);

-- Foods-Tabelle mit Grundsteinen für Verschenk-Feature
CREATE TABLE foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  expiry_date DATE,
  added_date DATE NOT NULL DEFAULT CURRENT_DATE,
  category TEXT,
  notes TEXT,
  is_consumed BOOLEAN DEFAULT FALSE,

  -- Verschenk-Feature Grundsteine (initial nicht genutzt)
  is_for_donation BOOLEAN DEFAULT FALSE,
  donation_status TEXT DEFAULT 'available' CHECK (
    donation_status IN ('available', 'reserved', 'claimed')
  ),
  reserved_by UUID REFERENCES device_keys(key),
  reserved_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Row Level Security (RLS)

```sql
-- Nur Haushaltsmitglieder sehen ihre Lebensmittel
CREATE POLICY "household_members_foods_policy" ON foods
  FOR ALL USING (
    household_id IN (
      SELECT household_id
      FROM household_memberships
      WHERE device_key = auth.uid() AND is_active = true
    )
  );

-- Nur aktive Access-Keys verwendbar
CREATE POLICY "active_access_keys_policy" ON access_keys
  FOR SELECT USING (is_active = true);

-- Nur Master kann Access-Keys verwalten (für alle Key-Typen)
CREATE POLICY "master_manage_access_keys_policy" ON access_keys
  FOR ALL USING (
    household_id IN (
      SELECT h.id
      FROM households h
      JOIN household_memberships hm ON h.id = hm.household_id
      WHERE hm.device_key = auth.uid()
        AND hm.role = 'master'
        AND hm.is_active = true
    )
  );

-- Verschenk-Feature RLS (vorbereitet, aber initial nicht aktiv)
CREATE POLICY "donation_viewers_see_donated_foods" ON foods
  FOR SELECT USING (
    -- Regular household access OR donation access
    (household_id IN (
      SELECT household_id FROM household_memberships
      WHERE device_key = auth.uid() AND is_active = true
    ))
    OR
    -- Donation access (später aktiviert)
    (is_for_donation = true AND false) -- Initial deaktiviert
  );
```

### Database Optimierung für Skalierung

#### MVP-Version (1000 Haushalte)
```sql
-- Basis-Indizes (ausreichend für <100k Records)
CREATE INDEX idx_foods_household_id ON foods(household_id);
CREATE INDEX idx_foods_expiry ON foods(expiry_date) WHERE is_consumed = false;
CREATE INDEX idx_household_memberships_device ON household_memberships(device_key);

-- Indizes für spätere Verschenk-Feature (vorbereitet)
CREATE INDEX idx_foods_donation ON foods(is_for_donation, donation_status)
  WHERE is_for_donation = true;
CREATE INDEX idx_access_keys_type ON access_keys(key_type, is_active);

-- Supabase Free Tier: Perfekt für MVP
-- 500MB Datenbank (reicht für 1000 Haushalte)
-- 50MB Bandbreite/Monat
```

#### Skalierungs-Version (100k Nutzer) - **SPÄTER**
```sql
-- Erweiterte Indizes für große Datenmengen
CREATE INDEX CONCURRENTLY idx_foods_household_expiry
  ON foods(household_id, expiry_date) WHERE is_consumed = false;

CREATE INDEX CONCURRENTLY idx_foods_household_created
  ON foods(household_id, created_at DESC);

-- Partitionierung erst bei >10M records nötig
CREATE TABLE foods_partitioned (LIKE foods INCLUDING ALL)
PARTITION BY HASH (household_id);

-- Pro Plan dann nötig
-- 8GB Datenbank + Connection Pooling
```

---

## 🔐 Sicherheitskonzept

### Anonymität & Datenschutz
- **Keine personenbezogenen Daten** in der Datenbank
- **UUID-basierte Identifikation** statt E-Mail/Name
- **Lokale Schlüssel-Speicherung** mit Keychain/Keystore
- **DSGVO-konform** durch Design

### Zugriffskontrolle
- **Row Level Security** isoliert Haushalte voneinander
- **Ein-Key-pro-Gerät** Prinzip
- **Master-kontrollierte** Sub-Key-Erstellung
- **Permanente Deaktivierung** beim Verlassen

### Missbrauchsschutz
- **Sub-Keys sind Einmal-nutzbar** (times_used/max_uses)
- **Automatische Expiration** möglich
- **Audit-Trail** für alle Aktionen
- **Master kann jederzeit Sub-Keys widerrufen**

### Skalierungs-Sicherheit

#### MVP-Version (ausreichend für Start)
- **Supabase Rate Limiting**: Standard (reicht für 1000 Haushalte)
- **Query Limits**: Standard Supabase Limits
- **Memory**: Normale Flutter App Limits

#### Später bei Skalierung
- **Rate Limiting**: Max 1000 API calls/min pro Household
- **Query Timeouts**: Max 5s für komplexe Abfragen
- **Memory Limits**: Max 1000 Foods pro Request
- **Connection Limits**: Supabase Connection Pooling

---

## 🔄 User Flows

### 1. Erste App-Installation (Master-Mode)
```
App-Start → Keine lokalen Keys gefunden
         → Generiere Master-Key
         → Erstelle Haushalt in Supabase
         → Speichere Key lokal
         → App zeigt Master-Interface
```

### 2. Sub-User Einladung
```
Master: Settings → "Neuen Nutzer einladen"
                → Eingabe: Label ("Mama")
                → Generiere Sub-Key
                → Zeige QR-Code + Text-Code

Sub-User: App-Start → "Haushalt beitreten"
                   → Scanne QR oder eingabe Code
                   → Validierung in Supabase
                   → Master-Key pausiert
                   → Wechsel zu Sub-Mode
```

### 3. Haushalt verlassen (Permanent)
```
Sub-User: Settings → "Haushalt verlassen"
                  → Warnung: "Permanent + neuer Code nötig"
                  → Bestätigung
                  → Sub-Key wird permanent deaktiviert
                  → Mitgliedschaft beendet
                  → Zurück zu Master-Mode
```

### 4. Sub-User Rauswurf
```
Master: Settings → "Benutzer verwalten"
                → Liste aktiver Sub-Users
                → "Zugang entziehen"
                → Sub-Key permanent deaktiviert
                → Betroffenes Gerät automatisch ausgeloggt
```

---

## 🎨 UI/UX Design

### Mode-abhängige Navigation

#### Master-Mode Interface
```
Bottom Navigation:
├── Lebensmittel (Vollzugriff)
├── Statistiken (Vollzugriff)
├── Rezepte (Vollzugriff)
└── Einstellungen
    ├── Haushalt verwalten ✅
    ├── Benutzer verwalten ✅
    ├── Sub-Keys erstellen ✅
    └── Standard-Einstellungen
```

#### Sub-Mode Interface
```
Bottom Navigation:
├── Lebensmittel (Vollzugriff)
├── Statistiken (Vollzugriff)
├── Rezepte (Vollzugriff)
└── Einstellungen
    ├── Haushalt verlassen ✅
    ├── Standard-Einstellungen
    └── [User-Management versteckt] ❌
```

### Visual Indicators
- **Mode-Badge** in der App-Bar: "Master" / "Gast bei: Familie Schmidt"
- **Access-Key Status** in Master-Settings: Aktiv/Inaktiv/Expired
- **View-Mode Toggle** (vorbereitet): "Meine Foods" / "Verschenken" (später)

---

## 📊 Berechtigungsmatrix

| Feature | Master | Sub-User |
|---------|---------|----------|
| Lebensmittel hinzufügen | ✅ | ✅ |
| Lebensmittel bearbeiten | ✅ | ✅ |
| Lebensmittel löschen | ✅ | ✅ |
| Statistiken anzeigen | ✅ | ✅ |
| Rezepte verwalten | ✅ | ✅ |
| Access-Keys erstellen | ✅ | ❌ |
| Access-Keys widerrufen | ✅ | ❌ |
| Benutzer verwalten | ✅ | ❌ |
| Haushalt umbenennen | ✅ | ❌ |
| Haushalt verlassen | N/A | ✅ |

---

## 🚀 Implementierungsroadmap

### MVP-Phase (Wochen 1-6): **Sofort startbereit für 1000 Haushalte**

#### Phase 1: Foundation (Woche 1-2)
**Ziel: Basis-Infrastruktur (MVP-ready)**
- [x] Supabase Projekt Setup (Free Tier)
- [x] Datenbankschema implementieren
- [x] RLS Policies konfigurieren
- [x] Anonymous Auth aktivieren
- [ ] Key-Generation Service
- [ ] Secure Key Storage

#### Phase 2: Master-Mode (Woche 3-4)
**Ziel: Einzeluser-Funktionalität**
- [ ] Master-Key Auto-Generation
- [ ] Haushalt-Erstellung
- [ ] Access-Key Management UI (generisch für beide Features)
- [ ] QR-Code Generation
- [ ] Mode-Detection Logic

#### Phase 3: Sub-Mode & Launch (Woche 5-6)
**Ziel: Multi-User MVP**
- [ ] Access-Key Validation (Sub-User Keys)
- [ ] Mode-Switching Logic
- [ ] Beitritts-UI (QR-Scanner)
- [ ] Verlassen-Funktionalität
- [ ] Permission-basierte UI
- [ ] Food-UI mit Grundsteinen für View-Modi
- [ ] **MVP LAUNCH** 🚀

### Skalierungs-Phase (Wochen 7-10): **Wenn >500 Haushalte erreicht**

#### Phase 4: Data Migration (Woche 7-8)
**Ziel: Bestehende Daten migrieren**
- [ ] SQLite → Supabase Migration
- [ ] Food-Sync Implementierung
- [ ] Offline-First Architecture
- [ ] Conflict Resolution

#### Phase 5: Performance-Optimierung (Woche 9-10)
**Ziel: Bereit für 100k Nutzer**
- [ ] Erweiterte Database Indizes
- [ ] Pagination für Food-Listen
- [ ] Memory Management (max 1k Foods in-app)
- [ ] Query Performance Monitoring
- [ ] Load Testing
- [ ] Supabase Pro Plan Migration

---

## 🧪 Test-Szenarien

### Happy Path Tests
1. **Master-Onboarding**: App-Installation → Automatischer Haushalt
2. **Sub-User Einladung**: QR-Code → Successful Join → Mode-Switch
3. **Lebensmittel-Sync**: Master adds food → Sub sees immediately
4. **Freiwilliges Verlassen**: Sub leaves → Returns to Master-Mode

### Edge Cases
1. **Doppelter Sub-Key**: Gleicher Code auf zwei Geräten
2. **Offline-Join**: Beitritt ohne Internet → Sync when online
3. **Master-Gerät verloren**: Recovery-Mechanismus
4. **Sub-Key Expiration**: Automatische Deaktivierung

### Security Tests
1. **SQL Injection**: Malicious Sub-Key inputs
2. **Unauthorized Access**: RLS Policy validation
3. **Key Bruteforce**: Rate limiting on Sub-Key attempts
4. **Data Isolation**: Cross-household data leakage

### Performance & Load Tests
1. **Database Load**: 6M Foods, 40k Haushalte simultaner Zugriff
2. **Query Performance**: <500ms für Food-Listen mit 150 Items
3. **Memory Usage**: <100MB RAM bei 1000 Foods
4. **Connection Limits**: 100 concurrent Users pro Household
5. **Real-time Sync**: <2s Latenz zwischen Geräten
6. **Pagination**: Smooth scrolling bei 10k+ Foods

---

## ✅ Finale Entscheidungen (erste Sektion)

### Access-Key Format
- **Option A**: UUID (`550e8400-e29b-41d4-a716-446655440000`)
- **Option B**: Kurz-Code (`ABCD-1234`)
- **✅ Entscheidung**: **Kurz-Code** (ABCD-1234) für bessere UX

### Statistiken & Rezepte
- **Option A**: Pro-Gerät gespeichert (individuell)
- **Option B**: Pro-Haushalt geteilt (gemeinsam)
- **✅ Entscheidung**: **Pro-Haushalt geteilt** für Familientransparenz

### Master-Key Recovery
- **Option A**: Kein Recovery (bei Verlust = neuer Haushalt)
- **Option B**: QR-Code Backup Export
- **Option C**: Seed-Phrase Backup
- **Option D**: iCloud/Android Keychain Backup
- **✅ Entscheidung**: **iCloud/Android Keychain Backup** für automatische Wiederherstellung

### Access-Key Limits
- **Option A**: Unlimited Access-Keys
- **Option B**: Maximum (z.B. 10 aktive Keys)
- **✅ Entscheidung**: **Maximum 5 Sub-User pro Haushalt**


---

## 📚 Technische Referenzen

### Dependencies
```yaml
# Neue Dependencies für Multi-User
supabase_flutter: ^2.5.6    # Backend & Real-time
qr_flutter: ^4.1.0          # QR-Code Generation
mobile_scanner: ^5.0.0      # QR-Code Scanning
uuid: ^4.5.0                # Key Generation
```

### Skalierungs-Architektur

#### Repository Pattern (MVP → Skalierung)

**MVP-Version (erweitert für zukünftige Features):**
```dart
abstract class FoodRepository {
  // Standard Household Foods
  Future<Either<Failure, List<Food>>> getFoodsForHousehold(String householdId);

  Future<Either<Failure, List<Food>>> getExpiringFoods(
    String householdId,
    int daysAhead,
  );

  // Grundsteine für Verschenk-Feature (initial leer)
  Future<Either<Failure, List<Food>>> getDonationFoods(String accessKey);
  Future<Either<Failure, void>> reserveFood(String foodId, String deviceKey);
}
```

**Skalierungs-Version (pagination):**
```dart
abstract class FoodRepository {
  // Paginierte Abfragen für große Datenmengen
  Future<Either<Failure, PaginatedFoods>> getFoodsForHousehold(
    String householdId, {
    int limit = 50,
    String? cursor,
  });
}

class PaginatedFoods {
  final List<Food> foods;
  final String? nextCursor;
  final bool hasMore;
}
```

#### BLoC State Management (erweitert für View-Modi)
```dart
class FoodLoaded extends FoodState {
  final List<Food> foods;
  final AppMode currentMode;
  final ViewMode currentViewMode;  // household oder donations
  final String? householdName;
  final bool hasMore;          // Pagination
  final String? nextCursor;    // Pagination
  final DateTime lastSync;     // Cache invalidation

  // Grundsteine für Verschenk-Feature
  final List<Food> donationFoods;  // Separate Liste für Verschenk-Foods
  final List<AccessKey> availableAccessKeys; // Verfügbare Donation-Keys
}

// Memory-efficient BLoC mit View-Modi
class FoodBloc extends Bloc<FoodEvent, FoodState> {
  static const int _maxFoodsInMemory = 1000;

  void _limitMemoryUsage(List<Food> foods) {
    if (foods.length > _maxFoodsInMemory) {
      foods.removeRange(0, foods.length - _maxFoodsInMemory);
    }
  }

  // Events für zukünftige Verschenk-Features
  void switchViewMode(ViewMode mode) {
    add(SwitchViewModeEvent(mode));
  }

  void loadDonationFoods(String accessKey) {
    add(LoadDonationFoodsEvent(accessKey));
  }
}
```

#### Database Query Optimierung (erweitert)
```dart
class SupabaseFoodDataSource {
  // Standard Household Foods
  Future<List<Food>> getFoodsForHousehold(String householdId) async {
    return await supabase
      .from('foods')
      .select()
      .eq('household_id', householdId)
      .eq('is_consumed', false)
      .eq('is_for_donation', false)  // Nur normale Foods
      .order('expiry_date', ascending: true)
      .limit(50);
  }

  // Verschenk-Foods (vorbereitet, initial leer)
  Future<List<Food>> getDonationFoods(String accessKey) async {
    // Initial disabled - später aktiviert
    return [];

    // Später:
    // return await supabase
    //   .from('foods')
    //   .select('*, households!household_id(name)')
    //   .eq('is_for_donation', true)
    //   .eq('donation_status', 'available')
    //   .order('expiry_date', ascending: true);
  }

  // Batch-Operations für bessere Performance
  Future<void> bulkUpdateFoods(List<Food> foods) async {
    final updates = foods.map((f) => f.toJson()).toList();
    await supabase.from('foods').upsert(updates);
  }
}
```

---

## 🎯 Erfolgs-Kriterien

### Funktionale Kriterien
- [x] Master kann Access-Keys erstellen/widerrufen (erweiterbar)
- [x] Sub-User kann mit Code beitreten
- [x] Lebensmittel-Sync funktioniert real-time
- [x] Mode-Switching funktioniert nahtlos
- [x] Permanentes Verlassen funktioniert
- [x] Grundsteine für Verschenk-Feature gelegt

### Non-funktionale Kriterien

#### MVP-Version (1000 Haushalte)
- [x] **Performance**: <2s für Mode-Switch, <2s für Food-Listen
- [x] **Offline**: Basis-Funktionalität ohne Internet
- [x] **Sicherheit**: RLS verhindert Cross-Household-Access
- [x] **Usability**: QR-Code-Join in <30s

#### Skalierungs-Version (100k Nutzer)
- [x] **Performance**: <500ms für Food-Queries
- [x] **Offline**: Vollständige Offline-First Architecture
- [x] **Memory**: <100MB bei 1000+ Foods
- [x] **Skalierung**: 100k Nutzer / 40k Haushalte / 6M Foods

### Business Kriterien
- [x] **Datenschutz**: Keine personenbezogenen Daten
- [x] **Familientauglich**: Kinder brauchen keine E-Mail
- [x] **Einfachheit**: Onboarding in <2 Min
- [x] **Zuverlässigkeit**: 99.9% Uptime

## ✅ Finale Entscheidungen

### Access-Key Format (für beide Features)
- **Option A**: UUID (`550e8400-e29b-41d4-a716-446655440000`)
- **Option B**: Kurz-Code (`ABCD-1234`)
- **✅ Entscheidung**: **Kurz-Code** (ABCD-1234) für bessere UX
- **Begründung**: Einfacher zu teilen, QR-Codes kleiner, tippen möglich

### Statistiken & Rezepte
- **Option A**: Pro-Gerät gespeichert (individuell)
- **Option B**: Pro-Haushalt geteilt (gemeinsam)
- **✅ Entscheidung**: **Pro-Haushalt geteilt** für Familientransparenz
- **Begründung**: Familie soll gemeinsame Übersicht haben

### Master-Key Recovery
- **Option A**: Kein Recovery (bei Verlust = neuer Haushalt)
- **Option B**: QR-Code Backup Export
- **Option C**: Seed-Phrase Backup
- **Option D**: iCloud/Android Keychain Backup
- **✅ Entscheidung**: **iCloud/Android Keychain Backup** für automatische Wiederherstellung
- **Begründung**: Automatisch, sicher, plattform-nativ, überdauert App-Neuinstallation

### Access-Key Limits (erweiterbar)
- **Option A**: Unlimited Keys (Sub-User + Donation)
- **Option B**: Maximum pro Typ (z.B. 10 Sub-User + 5 Donation-Keys)
- **✅ Entscheidung**: **Maximum 5 Sub-User pro Haushalt**
- **Begründung**: Ausreichend für große Familien, verhindert Missbrauch

### Verschenk-Feature Grundsteine (MVP-Phase)
- **Datenbank-Felder**: ✅ Sofort anlegen (is_for_donation, donation_status)
- **UI-Grundsteine**: ✅ View-Mode-Toggle vorbereiten
- **Key-Management**: ✅ Generic Service für beide Features
- **Entscheidung**: Grundsteine in MVP legen für einfachere Erweiterung

---

**Status**: 🚧 In Entwicklung (erweitert für Verschenk-Feature Grundsteine)
**Letzte Aktualisierung**: 2025-01-21
**Nächster Review**: Bei Phase-Abschluss