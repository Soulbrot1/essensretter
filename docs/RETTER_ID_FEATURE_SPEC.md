# EssensRetter RetterId-System - Funktionale Spezifikation

> **Status**: Basiert auf bestehender Implementation in `SimpleUserIdentityService`
> **Aufwand**: 2-3 Stunden (Refactoring statt Neuimplementierung)
> **Änderung**: RetterId-Generierung bereits ✅ | Nur secure_storage Integration fehlt

## 1. Feature Overview

**Ziel**: Automatische Generierung und sichere Verwaltung einer persistenten Nutzer-Identität (RetterId), die Daten-Wiederherstellung bei Gerätewechsel ermöglicht.

**Was bereits existiert** ✅:
- RetterId-Format `ER-XXXXXXXX` (Base36, 8 Zeichen)
- Generierungs-Logik mit `Random.secure()`
- Speicherung in SharedPreferences (`user_identity_v2`)
- Service: `SimpleUserIdentityService`

**Was fehlt** ❌:
- Speicherung in `flutter_secure_storage` (für automatisches OS-Backup)
- Onboarding-Dialog beim ersten App-Start
- UI in Einstellungen zum Anzeigen/Teilen der RetterId

**Geschäftswert**:
- Verhindert Datenverlust bei App-Neuinstallation oder Gerätewechsel
- Reduziert Support-Anfragen ("Alle meine Daten sind weg!")
- Nahtlose Wiederherstellung ohne Account-Registrierung (keine Email/Passwort)
- Nutzerfreundlicher als klassische Login-Systeme

**Problem das gelöst wird**:
- Aktuell: UserID liegt nur in SharedPreferences → Bei Neuinstallation komplett weg
- Aktuell: Lebensmittel nur in lokaler SQLite → Bei Gerätewechsel nicht übertragbar
- Zukünftig: RetterId ermöglicht Zugriff auf Cloud-Backups in Supabase

## 2. Minimaler Funktionsumfang (MVP - Phase 1)

### 2.1 Core User Stories

**Als neuer Nutzer:**
- Bekomme beim ersten App-Start automatisch eine RetterId generiert
- Sehe meine RetterId in einem Dialog mit Erklärung
- Kann die RetterId über den System-Teilen-Dialog extern speichern
- Die RetterId wird automatisch sicher auf dem Gerät gespeichert

**Als bestehender Nutzer (bei Gerätewechsel):**
- Kann in den App-Einstellungen meine aktuelle RetterId einsehen
- Kann die RetterId jederzeit extern teilen/speichern
- (Phase 2: Kann mit alter RetterId Daten wiederherstellen)

### 2.2 Was in Phase 1 enthalten ist
- ✅ Automatische RetterId-Generierung beim ersten Start
- ✅ Secure Storage (iOS Keychain / Android Keystore)
- ✅ Initiales RetterId-Display mit Erklärungs-Dialog
- ✅ System-Teilen-Button für externe Speicherung
- ✅ RetterId-Anzeige in Einstellungen

### 2.3 Was NICHT in Phase 1 enthalten ist
- ❌ Daten-Restore mit alter RetterId (kommt Phase 2)
- ❌ Cloud-Backup zu Supabase (kommt Phase 2)
- ❌ "Konto besteht bereits" Workflow (kommt Phase 2)
- ❌ Mehrgeräte-Sync (außerhalb Scope)
- ❌ RetterId ändern/neu generieren

## 3. Datenkonzept

### 3.1 RetterId Format (BEREITS IMPLEMENTIERT)

**Format**: `ER-XXXXXXXX`
- Prefix: `ER-` (EssensRetter)
- Suffix: 8 Zeichen Base36 (0-9, A-Z)
- Beispiel: `ER-7K9M2P5A`

**Vorteile**:
- Leicht lesbar und merkbar (8 statt 36 Zeichen UUID)
- Eindeutig identifizierbar als EssensRetter-Code
- Base36: Alphanumerisch, gut lesbar
- Kollisionswahrscheinlichkeit: ~1 in 2.8 Billionen (36^8)
- Verwendet `Random.secure()` für kryptographische Sicherheit

**Bestehende Implementierung**:
`SimpleUserIdentityService._generateUserId()` generiert bereits dieses Format.

### 3.2 Speicherorte

**Aktuell (Status Quo): SharedPreferences**
- Key: `user_identity_v2`
- Implementation: `SimpleUserIdentityService.ensureUserIdentity()`
- Problem: Geht bei Neuinstallation verloren (nicht in OS-Backup)

**Neu (Phase 1): Dual-Storage-Strategie**

**Primär: flutter_secure_storage** (NEU)
- Speicherort iOS: iOS Keychain (automatisch in iCloud Backup)
- Speicherort Android: Android Keystore (automatisch in Google Backup)
- Key: `essensretter_user_id`
- Verschlüsselung: Automatisch durch Betriebssystem

**Sekundär: SharedPreferences** (BEHALTEN)
- Bleibt als Fallback erhalten (falls secure_storage fehlschlägt)
- Key: `user_identity_v2` (bestehend)
- Wird parallel zu secure_storage geschrieben

### 3.3 Datenmigration für Bestandsnutzer

**Szenario 1: Bestehender User (hat `user_identity_v2` in SharedPreferences)**
1. App-Start: `SimpleUserIdentityService.ensureUserIdentity()` wird aufgerufen
2. Prüfe secure_storage → leer
3. Prüfe SharedPreferences (`user_identity_v2`) → RetterId gefunden (z.B. `ER-ABC12345`)
4. **Migration**: Kopiere RetterId zu secure_storage
5. Zeige KEINEN Onboarding-Dialog (silent migration)
6. SharedPreferences bleibt als Fallback erhalten (nicht löschen)
7. Ab jetzt: Dual-Storage (beide Speicher parallel)

**Szenario 2: Komplett neuer User**
1. App-Start: Prüfe secure_storage → leer
2. Prüfe SharedPreferences → leer
3. `SimpleUserIdentityService._generateUserId()` generiert neue RetterId
4. Speichere in **beide**: secure_storage + SharedPreferences
5. **Zeige Onboarding-Dialog** mit RetterId

**Szenario 3: Nach OS-Backup-Wiederherstellung (iOS/Android)**
1. App-Start: Prüfe secure_storage → RetterId gefunden! (aus Keychain/Keystore)
2. SharedPreferences leer (nicht in OS-Backup enthalten)
3. Schreibe RetterId auch in SharedPreferences (Konsistenz)
4. KEIN Onboarding-Dialog (User hat ja bereits gesehen)
5. → **Erfolgreiche automatische Wiederherstellung!**

## 4. Funktionale Anforderungen

### 4.1 RetterId-Generierung (BEREITS IMPLEMENTIERT ✅)
- Automatisch beim ersten App-Start (wenn keine vorhanden)
- Format: `ER-{8 Zeichen Base36}`
- Kollisionsprüfung nicht nötig (2.8 Billionen mögliche IDs)
- Verwendet `Random.secure()` für kryptographische Zufallszahlen
- **Bestehende Methode**: `SimpleUserIdentityService._generateUserId()`
- **Keine Änderungen nötig** an der Generierungs-Logik

### 4.2 Secure Storage
- Verwendung: `flutter_secure_storage` Package
- Automatische Keychain/Keystore Integration
- Kein manuelles Encryption-Handling nötig
- Fallback bei Storage-Fehler: SharedPreferences (mit Warning-Log)

### 4.3 Onboarding-Dialog (nur für neue Nutzer)
- Trigger: Erster App-Start ohne bestehende UserID
- Timing: Nach RetterId-Generierung, vor Main-UI
- Inhalt:
  - Titel: "Deine RetterId"
  - RetterId: Groß, zentriert, copyable
  - Erklärung: "Diese ID ermöglicht Datenwiederherstellung bei Gerätewechsel"
  - Hinweis: "Sie wird automatisch gespeichert"
  - Empfehlung: "Zusätzlich extern sichern (Screenshot, Passwort-Manager)"
- Buttons:
  - "Teilen" → System Share Sheet
  - "Weiter" → App starten

### 4.4 Einstellungs-Seite
- Neuer Abschnitt: "RetterId & Backup"
- Anzeige: Aktuelle RetterId (read-only)
- Button: "RetterId teilen" → System Share Sheet
- Info-Text: "Diese ID wird für Daten-Backups benötigt"

## 5. UI/UX Flows

### 5.1 Neuer Nutzer Flow
```
App-Start → RetterId generieren → In secure_storage speichern → Dialog anzeigen
   ↓
[Dialog: Deine RetterId]
   ├─ "ER-A7K9M2P5"
   ├─ Erklärungs-Text
   ├─ [Teilen-Button] → System Share Sheet → Extern speichern
   └─ [Weiter-Button] → Main-App
```

### 5.2 Bestandsnutzer Flow (Migration)
```
App-Start → secure_storage leer → Prüfe SharedPreferences → UserID gefunden
   ↓
Migriere zu secure_storage → KEIN Dialog → Main-App normal
```

### 5.3 RetterId in Einstellungen ansehen
```
Einstellungen → Scrollen zu "RetterId & Backup"
   ↓
[Card]
   ├─ "Deine RetterId: ER-A7K9M2P5"
   ├─ [Kopieren-Button] → Clipboard
   └─ [Teilen-Button] → System Share Sheet
```

## 6. Technische Überlegungen

### 6.1 Architektur

**Package-Integration:**
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0  # NEU
  shared_preferences: ^2.2.2       # BEREITS VORHANDEN
```

**Bestehende Struktur:**
```
/lib/features/sharing/presentation/services/
  └─ simple_user_identity_service.dart (VORHANDEN)
     - ensureUserIdentity()
     - getCurrentUserId()
     - _generateUserId()
```

**Änderungen:**
1. **SimpleUserIdentityService erweitern** (refactoring, nicht neu schreiben)
   - Dependency auf `FlutterSecureStorage` hinzufügen
   - Dual-Storage-Logik implementieren
   - Migration von SharedPreferences zu secure_storage

2. **Keine neuen Services nötig** (alles in SimpleUserIdentityService)

3. **Service bleibt statisch** (aktuelles Design beibehalten für Kompatibilität)

### 6.2 SimpleUserIdentityService Refactoring

**Aktuell (Status Quo):**
```dart
class SimpleUserIdentityService {
  static const String _userIdentityKey = 'user_identity_v2';

  static Future<String> ensureUserIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final existingUserId = prefs.getString(_userIdentityKey);

    if (existingUserId != null) {
      return existingUserId;
    }

    final userId = _generateUserId();
    await prefs.setString(_userIdentityKey, userId);
    return userId;
  }

  static String _generateUserId() {
    // ER-XXXXXXXX mit Base36
    // ... (bereits implementiert)
  }
}
```

**Nach Refactoring (Phase 1):**
```dart
class SimpleUserIdentityService {
  static const String _userIdentityKey = 'user_identity_v2';
  static const String _secureStorageKey = 'essensretter_user_id';

  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Hauptmethode: Holt RetterId mit Auto-Migration + Dual-Storage
  static Future<String> ensureUserIdentity() async {
    // 1. Prüfe secure_storage (primär)
    String? userId = await _secureStorage.read(key: _secureStorageKey);

    if (userId != null) {
      // Szenario 3: Nach OS-Backup-Wiederherstellung
      // Sync zurück zu SharedPreferences (Konsistenz)
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_userIdentityKey) == null) {
        await prefs.setString(_userIdentityKey, userId);
      }
      return userId;
    }

    // 2. Migration: Prüfe SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString(_userIdentityKey);

    if (userId != null) {
      // Szenario 1: Bestehender User → Migration
      await _secureStorage.write(key: _secureStorageKey, value: userId);
      return userId;
    }

    // 3. Szenario 2: Neuer User → Generiere neue RetterId
    userId = _generateUserId();

    // Dual-Storage: Schreibe in beide
    await _secureStorage.write(key: _secureStorageKey, value: userId);
    await prefs.setString(_userIdentityKey, userId);

    return userId;
  }

  static String _generateUserId() {
    // KEINE ÄNDERUNG - bestehende Implementation bleibt
    const String prefix = 'ER-';
    const String charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const int idLength = 8;

    final random = Random.secure();
    final buffer = StringBuffer(prefix);

    for (int i = 0; i < idLength; i++) {
      buffer.write(charset[random.nextInt(charset.length)]);
    }

    return buffer.toString();
  }

  // Bestehende Methode bleibt kompatibel
  static Future<String?> getCurrentUserId() async {
    return await ensureUserIdentity();
  }
}
```

**Änderungen zusammengefasst:**
- ✅ Bestehende `_generateUserId()` bleibt unverändert
- ✅ `ensureUserIdentity()` erweitert um secure_storage Logik
- ✅ Dual-Storage: Beide Speicher werden parallel geschrieben
- ✅ Automatische Migration von SharedPreferences → secure_storage
- ✅ Backward-Compatible: Bestehende Caller funktionieren weiter

### 6.3 Onboarding-Dialog Implementierung

**Neues Widget:**
```
/lib/core/presentation/widgets/
  └─ retter_id_onboarding_dialog.dart
```

**Integration in main.dart:**
```dart
Future<void> main() async {
  // Dependency Injection Setup
  await setupServiceLocator();

  // Prüfe ob Onboarding nötig
  final needsOnboarding = await _checkIfFirstLaunch();

  runApp(MyApp(showOnboarding: needsOnboarding));
}
```

### 6.4 Dependencies

**Neu benötigt:**
```yaml
flutter_secure_storage: ^9.0.0  # iOS Keychain / Android Keystore
share_plus: ^7.2.1              # System Share Sheet (falls nicht vorhanden)
```

**Bereits vorhanden:**
```yaml
shared_preferences: ^2.2.2      # Bestehende UserID-Speicherung
```

**NICHT benötigt:**
- `uuid` Package → RetterId-Generierung nutzt `Random.secure()` (Dart stdlib)

## 7. Kritische Risiken & Mitigation

### 7.1 Technische Risiken

**Secure Storage Zugriffsfehler**
- Risiko: Keychain/Keystore nicht verfügbar (Jailbreak, sehr alte Android-Versionen)
- Wahrscheinlichkeit: <1% der Nutzer
- Lösung: Fallback zu SharedPreferences mit Warning-Log
- Impact: Medium (Daten gehen bei Neuinstallation verloren)

**Migration schlägt fehl**
- Risiko: SharedPreferences → secure_storage Migration scheitert
- Wahrscheinlichkeit: <0.1%
- Lösung: Alte UserID bleibt in SharedPreferences, Retry bei nächstem Start
- Impact: Low (funktioniert weiter wie bisher)

**UUID-Kollision**
- Risiko: Zwei Nutzer bekommen identische RetterId
- Wahrscheinlichkeit: ~1 in 1 Billion
- Lösung: Vernachlässigbar, keine Maßnahme nötig
- Impact: Theoretisch High, praktisch irrelevant

**Keychain-Backup wird nicht wiederhergestellt**
- Risiko: User wechselt Gerät, iCloud/Google-Backup funktioniert nicht
- Wahrscheinlichkeit: 10-20% (User deaktivieren Backups)
- Lösung: Daher der Onboarding-Dialog mit "extern speichern"
- Impact: Medium (User muss RetterId manuell eingeben in Phase 2)

### 7.2 UX Risiken

**Nutzer speichert RetterId nicht extern**
- Risiko: Bei Gerätewechsel ohne OS-Backup ist RetterId weg
- Wahrscheinlichkeit: 50-70% ignorieren den Dialog
- Lösung: In Phase 2 mehrfach erinnern (Einstellungen, App-Start)
- Impact: Medium (Datenverlust, aber nur wenn OS-Backup auch fehlt)

**Nutzer verwechselt RetterId mit Freundschafts-Code**
- Risiko: Verwirrung durch ähnliche Formate
- Wahrscheinlichkeit: Low (unterschiedliches Prefix/UI)
- Lösung: Klare Benennung, unterschiedliche Farben/Icons
- Impact: Low (nur Verwirrung, keine Datenverlust)

**Dialog nervt bei Testinstallationen**
- Risiko: Entwickler/Tester müssen Dialog jedes Mal wegklicken
- Wahrscheinlichkeit: 100% in Development
- Lösung: Environment-Flag zum Deaktivieren in Debug-Builds
- Impact: Low (nur Developer Experience)

### 7.3 Sicherheitsrisiken

**RetterId wird öffentlich geteilt**
- Risiko: User postet RetterId in Social Media
- Wahrscheinlichkeit: Very Low
- Impact: Medium (andere könnten theoretisch auf Backups zugreifen)
- Lösung Phase 2: Zusätzliche Authentifizierung beim Restore

**Screenshot landet in Cloud-Backup**
- Risiko: Screenshot mit RetterId wird automatisch gebackupt
- Wahrscheinlichkeit: High
- Impact: Low (eigentlich gewollt - ist ja Backup-Zweck)
- Lösung: Kein Handlungsbedarf

## 8. Akzeptanzkriterien

### 8.1 Funktionale Kriterien

**Phase 1 - RetterId-Generierung:**
- ✅ Beim ersten App-Start wird automatisch RetterId generiert
- ✅ RetterId hat Format `ER-XXXXXXXX`
- ✅ RetterId wird in secure_storage gespeichert
- ✅ Bei Neustart wird dieselbe RetterId wiederverwendet

**Phase 1 - Onboarding:**
- ✅ Nur neue Nutzer sehen Onboarding-Dialog
- ✅ Bestandsnutzer werden silent migriert
- ✅ Dialog zeigt RetterId klar und copyable
- ✅ System-Teilen-Funktionalität funktioniert

**Phase 1 - Einstellungen:**
- ✅ Aktuelle RetterId ist in Einstellungen sichtbar
- ✅ "Kopieren" und "Teilen" Buttons funktionieren
- ✅ RetterId ist nicht editierbar (read-only)

### 8.2 Performance-Kriterien
- RetterId-Generierung: <100ms
- Secure Storage Read: <50ms
- Onboarding-Dialog Anzeige: <200ms nach App-Start
- Keine merkliche Verzögerung beim App-Start durch Migration

### 8.3 Kompatibilitäts-Kriterien
- iOS 12.0+ (flutter_secure_storage Mindestanforderung)
- Android 4.1+ (API Level 16+)
- Funktioniert auf Simulatoren/Emulatoren
- Funktioniert auf Geräten mit/ohne Biometrie

### 8.4 Datenschutz-Kriterien
- RetterId enthält keine personenbezogenen Daten
- RetterId kann nicht auf Person zurückgeführt werden
- Keychain/Keystore-Zugriff nur durch EssensRetter-App
- Keine Übertragung der RetterId an Server (in Phase 1)

## 9. Testing-Strategie

### 9.1 Unit Tests

**UserIdentityService Tests:**
- ✅ Neue RetterId generieren wenn keine vorhanden
- ✅ Bestehende RetterId aus secure_storage laden
- ✅ Migration von SharedPreferences zu secure_storage
- ✅ RetterId-Format validieren (ER-[A-Z0-9]{8})
- ✅ Fallback zu SharedPreferences bei secure_storage Fehler

**RetterId Generator Tests:**
- ✅ Format-Validierung (Regex-Match)
- ✅ Eindeutigkeit (100 IDs generieren, keine Duplikate)
- ✅ Length-Check (immer 11 Zeichen: ER- + 8)

### 9.2 Widget Tests

**RetterIdOnboardingDialog Tests:**
- ✅ RetterId wird korrekt angezeigt
- ✅ "Teilen"-Button triggert Share-Action
- ✅ "Weiter"-Button schließt Dialog
- ✅ Text-Inhalte korrekt (Accessibility)

**Settings RetterId Section Tests:**
- ✅ RetterId wird aus Service geladen und angezeigt
- ✅ "Kopieren"-Button setzt Clipboard
- ✅ "Teilen"-Button triggert Share-Action

### 9.3 Integration Tests

**Erster App-Start Scenario:**
1. Frische Installation (keine Daten)
2. App startet
3. RetterId wird generiert
4. Onboarding-Dialog erscheint
5. User klickt "Weiter"
6. Main-App wird geladen
7. RetterId ist in Einstellungen sichtbar

**Migration Scenario:**
1. App mit alter UserID in SharedPreferences
2. App startet
3. UserID wird zu secure_storage migriert
4. KEIN Onboarding-Dialog
5. Main-App wird direkt geladen
6. RetterId (= alte UserID) ist in Einstellungen sichtbar

**Persistenz Scenario:**
1. App startet, RetterId wird generiert
2. App schließen
3. App neu starten
4. Dieselbe RetterId wird geladen (keine Neugeneration)

### 9.4 Manuelle Test-Checklist

**iOS:**
- [ ] Keychain-Zugriff funktioniert auf echtem Device
- [ ] iCloud Keychain Backup (optional, schwer zu testen)
- [ ] App-Neuinstallation ohne Backup löscht RetterId
- [ ] Share Sheet zeigt iOS-native UI

**Android:**
- [ ] Keystore-Zugriff funktioniert
- [ ] Google Backup (optional, schwer zu testen)
- [ ] App-Neuinstallation ohne Backup löscht RetterId
- [ ] Share Sheet zeigt Android-native UI

**Edge Cases:**
- [ ] Sehr langsame Geräte (keine UI-Blockade)
- [ ] Flugmodus / Offline (sollte trotzdem funktionieren)
- [ ] Nach Force-Quit (Daten bleiben erhalten)

## 10. Implementierungs-Roadmap

### Phase 1: Basis-Implementation (2-3 Stunden)
**Aufgaben:**
- [ ] `flutter_secure_storage` Dependency hinzufügen (5 Min)
- [ ] `SimpleUserIdentityService` refactoring (1h)
  - secure_storage Integration
  - Dual-Storage-Logik
  - Migration von SharedPreferences → secure_storage
  - **KEINE Änderung** an `_generateUserId()` (bereits perfekt!)
- [ ] Tests für Migration-Szenarien schreiben (30 Min)
- [ ] `RetterIdOnboardingDialog` Widget erstellen (45 Min)
- [ ] Einstellungs-Sektion für RetterId erweitern (30 Min)
- [ ] Integration in `main.dart` (15 Min)
- [ ] Manuelle Tests auf iOS/Android (30 Min)

**Deliverables:**
- ✅ RetterId wird in secure_storage gespeichert (automatisches OS-Backup)
- ✅ Dual-Storage: secure_storage + SharedPreferences parallel
- ✅ Silent Migration für Bestandsnutzer
- ✅ Onboarding-Dialog nur für neue Nutzer
- ✅ RetterId-Anzeige/Teilen in Einstellungen
- ✅ Tests für alle 3 Migrationsszenarien
- ✅ Backward-Compatible mit bestehendem Code

**Zeitersparnis gegenüber Neuimplementierung:**
- RetterId-Generierung: -30 Min (bereits implementiert ✅)
- Service-Struktur: -30 Min (erweitern statt neu schreiben ✅)
- Gesamt: 2-3h statt 3-4h

### Phase 2: Cloud-Backup Integration (4-6 Stunden)

**Architektur-Prinzip:**
- **SQLite bleibt Source of Truth** (primäre Datenquelle)
- **Supabase = Snapshot-Backup-Storage** (nicht für Live-Sync)
- Kein Multi-Device-Sync, nur Gerätewechsel-Wiederherstellung

#### 2.1 Snapshot-Backup-Konzept

**Was ist ein Snapshot?**
Ein Snapshot ist eine **komplette Momentaufnahme aller Daten** zu einem bestimmten Zeitpunkt. Wie ein Foto der gesamten Datenbank.

**Im Gegensatz zu Live-Sync:**
- NICHT: Jede Änderung sofort synchronisieren
- SONDERN: Periodisch kompletten Datenstand hochladen
- Vorteil: Einfach, keine Konflikt-Resolution nötig

**Backup-Struktur:**
```json
{
  "userId": "ER-ABC12345",
  "timestamp": "2025-10-13T14:30:00Z",
  "version": "1.0",
  "device": "iPhone 14",
  "foods": [
    {"id": "1", "name": "Paprika", "expiryDate": "2025-10-20", ...},
    {"id": "2", "name": "Milch", "expiryDate": "2025-10-15", ...}
    // ... alle Lebensmittel
  ],
  "friends": [
    {"userId": "ER-XYZ78910", "displayName": "Anna", ...}
    // ... alle Freunde
  ]
}
```

#### 2.2 Hash-Check-Methode (Traffic-Optimierung)

**Problem ohne Hash-Check:**
User öffnet App, schaut nur rein, schließt → Backup hochgeladen (verschwendet Traffic)

**Lösung: Hash als digitaler Fingerabdruck**
```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SnapshotBackupService {
  String? _lastBackupHash;

  /// Berechnet SHA-256 Hash des Snapshots
  String _calculateHash(Map<String, dynamic> snapshot) {
    final jsonString = jsonEncode(snapshot);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Erstellt Backup nur wenn Daten sich geändert haben
  Future<void> createBackupIfNeeded() async {
    // 1. Hole aktuelle Daten aus SQLite
    final foods = await foodRepository.getAllFoods();
    final friends = await friendRepository.getAllFriends();

    final snapshot = {
      'userId': await userService.getRetterId(),
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'foods': foods.map((f) => f.toJson()).toList(),
      'friends': friends.map((f) => f.toJson()).toList(),
    };

    // 2. Berechne Hash (1-2ms, sehr schnell)
    final currentHash = _calculateHash(snapshot);

    // 3. Vergleiche mit letztem Backup
    if (currentHash == _lastBackupHash) {
      print("✅ Keine Änderungen seit letztem Backup, skip");
      return; // Kein Upload nötig!
    }

    // 4. Daten haben sich geändert → Upload zu Supabase
    print("📤 Änderungen erkannt, lade Backup hoch");

    // Optional: gzip Compression (-60% Traffic)
    final compressed = gzip.encode(utf8.encode(jsonEncode(snapshot)));

    await supabase.from('backups').upsert({
      'user_id': snapshot['userId'],
      'data': compressed,
      'created_at': snapshot['timestamp'],
    });

    // 5. Merke dir Hash für nächstes Mal
    _lastBackupHash = currentHash;
    await _storage.write('last_backup_hash', currentHash);
  }
}
```

**Vorteile Hash-Check:**
- **-70% Traffic**: Nur bei echten Änderungen Backup
- **Schnell**: Hash berechnen dauert 1-2ms
- **Einfach**: ~15 Zeilen Code
- **Batterie-schonend**: Weniger Netzwerk-Aktivität

#### 2.3 Backup-Trigger-Strategie

**Methode: AppLifecycleState.paused + Throttling**

```dart
class AppLifecycleObserver extends WidgetsBindingObserver {
  DateTime? _lastBackup;
  static const Duration _throttleDuration = Duration(minutes: 5);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      final now = DateTime.now();

      // Throttling: nur alle 5 Min
      if (_lastBackup == null ||
          now.difference(_lastBackup!) > _throttleDuration) {

        await backupService.createBackupIfNeeded();
        _lastBackup = now;
      }
    }
  }
}
```

**Trigger-Zeitpunkte:**
1. **App in Hintergrund** (paused): User drückt Home-Button
2. **Throttling**: Maximal alle 5 Minuten
3. **Hash-Check**: Nur bei Änderungen

**Warum NICHT "beim Schließen"?**
- iOS/Android killen Apps oft hart (kein sauberes Schließen)
- `paused` ist zuverlässiger (wird immer getriggert)

**Beispiel-Szenario:**
```
10:00 → App öffnen
10:05 → Paprika hinzufügen
10:10 → App in Hintergrund (Home drücken)
        → Trigger: paused
        → Hash-Check: Unterschiedlich
        → ✅ Backup hochladen

12:00 → App öffnen, nur schauen
12:05 → App in Hintergrund
        → Trigger: paused (aber < 5 Min seit letztem)
        → ❌ Throttled, kein Check

14:00 → App öffnen, nur schauen
14:10 → App in Hintergrund
        → Trigger: paused (> 5 Min seit letztem)
        → Hash-Check: Gleich
        → ❌ Kein Backup nötig

16:00 → App öffnen, Milch hinzufügen
16:05 → App in Hintergrund
        → Trigger: paused (> 5 Min)
        → Hash-Check: Unterschiedlich
        → ✅ Backup hochladen
```

#### 2.4 Supabase-Schema

**Tabelle: backups**
```sql
CREATE TABLE backups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,
  data JSONB NOT NULL,  -- oder BYTEA für compressed
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  device_info TEXT,
  UNIQUE(user_id)  -- Nur ein Backup pro User (überschreiben)
);

CREATE INDEX idx_backups_user_id ON backups(user_id);
CREATE INDEX idx_backups_created_at ON backups(created_at);
```

**Strategie: Nur neuestes Backup behalten**
- `UNIQUE(user_id)` → `upsert` überschreibt altes Backup
- Spart Speicher (kein historischer Verlauf)
- Für History: `UNIQUE(user_id, created_at)` + `LIMIT 5` bei Query

#### 2.5 Restore-Workflow

**UI-Flow:**
```
Neues Gerät / Neuinstallation
  ↓
[Onboarding-Dialog]
  ├─ "Neu starten" → Generiere neue RetterId
  └─ "Daten wiederherstellen" → Zeige Eingabefeld
      ↓
User gibt RetterId ein: "ER-OLD67890"
  ↓
Supabase Query: SELECT data FROM backups WHERE user_id = 'ER-OLD67890'
  ↓
Backup gefunden?
  ├─ Ja → Download JSON → Schreibe in SQLite → Cleanup alte ID → Fertig
  └─ Nein → Fehlermeldung: "Kein Backup gefunden für diese RetterId"
```

**Code mit automatischem Cleanup:**
```dart
Future<void> restoreFromBackup(String oldRetterId) async {
  // 1. Hole AKTUELLE RetterId (wurde bei App-Start neu generiert)
  final currentRetterId = await userService.getRetterId();

  // 2. Hole Backup von Supabase mit alter RetterId
  final response = await supabase
    .from('backups')
    .select('data, created_at')
    .eq('user_id', oldRetterId)
    .maybeSingle();

  if (response == null) {
    throw BackupNotFoundException('Kein Backup gefunden für $oldRetterId');
  }

  // 3. Dekomprimiere falls nötig
  final data = response['data'];
  final snapshot = data is String
    ? jsonDecode(gzip.decode(base64Decode(data)))  // Falls compressed
    : data;  // JSONB ist schon geparst

  // 4. Lokale DB komplett löschen
  await foodRepository.deleteAll();
  await friendRepository.deleteAll();

  // 5. Backup-Daten in SQLite schreiben
  for (var foodJson in snapshot['foods']) {
    await foodRepository.insert(Food.fromJson(foodJson));
  }

  for (var friendJson in snapshot['friends']) {
    await friendRepository.insert(Friend.fromJson(friendJson));
  }

  // 6. CLEANUP: Lösche Backup der neuen (ungenutzten) RetterId
  if (currentRetterId != oldRetterId) {
    try {
      await supabase
        .from('backups')
        .delete()
        .eq('user_id', currentRetterId);

      print("🧹 Cleanup: Gelöschtes Backup für ungenutzte ID $currentRetterId");
    } catch (e) {
      // Ignoriere Fehler (Backup existierte vielleicht noch gar nicht)
      print("ℹ️ Kein Backup für $currentRetterId gefunden (ok)");
    }
  }

  // 7. RetterId lokal überschreiben mit alter ID
  await userService.setRetterId(oldRetterId);

  print("✅ Backup wiederhergestellt (${snapshot['foods'].length} Lebensmittel)");
  print("✅ RetterId gewechselt: $currentRetterId → $oldRetterId");
}
```

**Cleanup-Logik erklärt:**

**Problem ohne Cleanup:**
```
Neues Gerät:
1. App generiert ER-NEW12345
2. User fügt 2 Test-Lebensmittel hinzu
3. App in Hintergrund → Backup hochgeladen
   Supabase: ER-NEW12345 → {2 Lebensmittel}

4. User restored mit ER-OLD67890
5. Restore erfolgreich, 50 Lebensmittel geladen

Problem: ER-NEW12345 liegt als Datenbankleiche in Supabase!
```

**Lösung mit Cleanup:**
```
6. Cleanup erkennt: currentRetterId (ER-NEW12345) != oldRetterId (ER-OLD67890)
7. Lösche Backup für ER-NEW12345 von Supabase
8. Setze lokale RetterId auf ER-OLD67890

Ergebnis: Nur noch ER-OLD67890 in Supabase ✅
```

**Vorteile:**
- ✅ Keine Datenbankleichen in Supabase
- ✅ Spart Speicher
- ✅ Klare Datenhaltung (nur eine aktive RetterId pro User)
- ✅ Sicher: Cleanup erst NACH erfolgreichem Restore

**Edge Cases:**
- **Sofortiger Restore**: Neue ID hatte noch kein Backup → Cleanup-Delete schlägt fehl → wird ignoriert ✅
- **Restore schlägt fehl**: Cleanup wird nicht ausgeführt → alte ID bleibt erhalten ✅
- **Mehrfacher Restore**: Jedes Mal wird vorherige ID aufgeräumt ✅

#### 2.6 Traffic-Berechnung

**Annahmen bei 100.000 Usern:**
- 15% Daily Active Users = 15.000 User/Tag
- Durchschnittlich 2-3 App-Sessions/Tag
- 50 Lebensmittel × 250 Bytes = 12.5 KB
- 5 Freunde × 150 Bytes = 0.75 KB
- **Total: ~14 KB pro Snapshot**

**Ohne Optimierungen:**
```
15.000 User × 2.5 Sessions/Tag = 37.500 Backups/Tag
37.500 × 14 KB = 525 MB/Tag
525 MB × 30 Tage = 15.8 GB/Monat
```

**Mit Hash-Check (-70%):**
```
37.500 × 0.3 = 11.250 Backups/Tag (nur bei Änderungen)
11.250 × 14 KB = 157 MB/Tag
157 MB × 30 = 4.7 GB/Monat
```

**Mit Hash-Check + gzip (-60% zusätzlich):**
```
11.250 × 5.6 KB (14 KB × 0.4) = 63 MB/Tag
63 MB × 30 = 1.9 GB/Monat
```

**Supabase Kosten:**
- Free Tier: 2 GB/Monat → Reicht bis ~100k User
- Pro Plan: $25/Monat → 50 GB (weit mehr als nötig)

#### 2.7 Was gebackupt wird

**Enthalten:**
- ✅ Alle Lebensmittel (id, name, expiryDate, category, notes, addedDate)
- ✅ Alle Freunde (userId, displayName)
- ✅ `isConsumed` Flag
- ✅ `isShared` Flag (wenn einfach implementierbar)

**NICHT enthalten (vorerst):**
- ❌ App-Einstellungen (Benachrichtigungen, Theme)
- ❌ Statistiken/Analysen
- ❌ Geteilte-Lebensmittel-Historie (nur eigene)

**Rationale für isShared:**
- Wichtig: Nach Restore muss App wissen welche Lebensmittel geteilt waren
- Sonst: Freunde-Feature inkonsistent
- Aufwand: Minimal (einfach im JSON mit übertragen)

#### 2.8 Aufgaben-Breakdown

**Phase 2 Implementierung (4-6h):**
- [ ] `SnapshotBackupService` erstellen (1.5h)
  - Hash-Berechnung
  - Backup-Upload mit gzip
  - Hash-Persistierung in Storage
- [ ] `AppLifecycleObserver` implementieren (30 Min)
  - paused-Trigger
  - Throttling-Logik
- [ ] Supabase-Tabelle `backups` anlegen (15 Min)
- [ ] Restore-UI in Onboarding-Dialog (1h)
  - "Daten wiederherstellen" Button
  - RetterId-Eingabefeld
  - Loading-State während Restore
  - Error-Handling
- [ ] Restore-Logic implementieren (1.5h)
  - Supabase Query
  - Dekompression
  - SQLite-Schreiboperationen
  - **Cleanup-Logik** (Lösche ungenutzte RetterId-Backups)
  - Error-Handling
- [ ] Tests schreiben (1h)
  - Hash-Berechnung Tests
  - Backup-Trigger Tests
  - Restore-Logic Tests
  - Cleanup-Logic Tests (ungenutzte RetterId wird gelöscht)
- [ ] Manuelle Tests (30 Min)
  - iOS/Android Backup-Upload
  - Restore auf neuem Gerät
  - Offline-Verhalten

**Deliverables:**
- ✅ Automatisches Backup bei App-Schließen (mit Hash-Check)
- ✅ Traffic-optimiert: -70% durch Hash-Check + gzip
- ✅ Restore-Workflow mit RetterId-Eingabe
- ✅ Automatisches Cleanup: Ungenutzte RetterId-Backups werden gelöscht
- ✅ Kosteneffizient: ~2 GB/Monat bei 100k Usern
- ✅ Zuverlässig: Backup bei jedem App-Schließen (Throttled)

### Phase 3: Optimierungen (optional)
- Push-Reminder zum Sichern der RetterId
- QR-Code-Export der RetterId (analog zu Freundschafts-Codes)
- "RetterId ändern" Funktion (falls gewünscht)

## 11. Dokumentations-Anforderungen

### 11.1 Code-Dokumentation
- Alle neuen Services mit DartDoc-Kommentaren
- Komplexe Logik (z.B. Migration) mit Inline-Kommentaren
- README-Update mit RetterId-Konzept

### 11.2 User-Facing Dokumentation
- App-Store Beschreibung: "Daten-Backup mit RetterId"
- In-App Hilfe-Text in Einstellungen
- Datenschutzerklärung-Update (RetterId erwähnen)

### 11.3 Developer Dokumentation
- CLAUDE.md Update mit RetterId-System
- Architecture Decision Record (ADR) für secure_storage Wahl
- Migration-Guide für Bestandsnutzer

## 12. Design-Entscheidungen für Phase 2 ✅

**Entscheidungen getroffen:**

1. **Restore automatisch bei App-Start prüfen?**
   - ❌ NEIN: Manuell über Onboarding-Dialog
   - Rationale: Kein Performance-Impact, User hat Kontrolle

2. **Wie oft soll Backup-Sync ausgeführt werden?**
   - ✅ Bei App in Hintergrund (paused) + Throttling 5 Min
   - Rationale: Zuverlässig, gute Aktualität, kosteneffizient

3. **Hash-Check für Traffic-Optimierung?**
   - ✅ JA: -70% Traffic durch Smart-Backup
   - Rationale: Einfach, schnell, spart Kosten

4. **gzip Compression?**
   - ✅ JA: -60% zusätzliche Traffic-Reduktion
   - Rationale: Standardmäßig verfügbar, minimal Overhead

5. **Multi-Device-Sync?**
   - ❌ NEIN: Nur Snapshot-Backup für Gerätewechsel
   - Rationale: Deutlich einfacher, keine Konflikt-Resolution nötig

6. **Backup-Historie behalten?**
   - ❌ NEIN: Nur neuestes Backup (upsert)
   - Rationale: Spart Speicher, für Use Case ausreichend
   - Optional: Kann später auf 5 History-Snapshots erweitert werden

6b. **Cleanup beim Restore?**
   - ✅ JA: Ungenutzte RetterId-Backups automatisch löschen
   - Rationale: Verhindert Datenbankleichen, spart Speicher
   - Sicher: Cleanup erst NACH erfolgreichem Restore

7. **Zusätzliche Auth beim Restore?**
   - ❌ NEIN (Phase 2): RetterId alleine reicht
   - Rationale: Balance UX vs. Sicherheit
   - Optional: Kann in Phase 3 mit PIN/Biometrie erweitert werden

8. **Was wird gebackupt?**
   - ✅ Alle Lebensmittel + Freunde + isConsumed + isShared
   - ❌ NICHT: Einstellungen, Statistiken
   - Rationale: Fokus auf kritische Daten

**Architektur-Prinzipien:**
- SQLite = Source of Truth (primäre Datenquelle)
- Supabase = Snapshot-Backup-Storage (nicht Live-Sync)
- Kein Multi-Device-Sync (außerhalb Scope)
- Snapshot überschreibt bei Restore komplett lokale Daten

**Traffic-Ziel erreicht:**
- ~2 GB/Monat bei 100k Usern (mit Hash-Check + gzip)
- Free Tier ausreichend bis ~100k User
- Danach $25/Monat (Pro Plan)

**Nicht in diesem Feature enthalten:**
- Multi-Device Live-Sync (außerhalb Scope - zu komplex)
- RetterId teilen mit Freunden (verwechselbar mit Freundschafts-Codes)
- RetterId als Login-Ersatz für andere Services
- Inkrementelle Backups (nur komplette Snapshots)
