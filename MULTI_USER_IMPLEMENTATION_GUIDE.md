# Multi-User Haushalt Feature - Implementierungsguide

## Übersicht

Dieses Feature ermöglicht es mehreren Personen, einen gemeinsamen Lebensmittel-Haushalt zu verwalten durch ein Master/Sub-Key System.

## Architektur-Prinzipien

### 1. Sicherheits-First Approach
- **Master-Key**: Nur beim App-Besitzer, nie teilen
- **Sub-Keys**: Temporäre Schlüssel mit begrenzten Rechten
- **Granulare Berechtigungen**: read, write, admin

### 2. Privacy by Design
- Keine E-Mail/Telefonnummer nötig
- Pseudonyme Keys (z.B. "APFEL-X7K9")
- Lokale Key-Speicherung mit iCloud Backup

## Implementierung in Phasen

### Phase 1: Backend Setup (Supabase)

#### 1.1 Datenbank-Schema
```sql
-- Haushalte
CREATE TABLE households (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  master_key TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  name TEXT DEFAULT 'Mein Haushalt'
);

-- Zugangsschlüssel
CREATE TABLE access_keys (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  key_code TEXT UNIQUE NOT NULL,
  key_type TEXT CHECK (key_type IN ('master', 'sub', 'share')) NOT NULL,
  permissions TEXT[] DEFAULT ARRAY['read', 'write'],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by TEXT,
  expires_at TIMESTAMPTZ
);

-- Food-Tabelle erweitern
ALTER TABLE foods ADD COLUMN household_id UUID REFERENCES households(id);
ALTER TABLE foods ADD COLUMN added_by TEXT; -- Key des Erstellers

-- Indexes für Performance
CREATE INDEX idx_access_keys_household ON access_keys(household_id);
CREATE INDEX idx_foods_household ON foods(household_id);
CREATE INDEX idx_foods_expiry ON foods(expiry_date);
```

#### 1.2 RLS Policies (Einfach halten!)
```sql
-- WICHTIG: Zuerst einfach, dann verfeinern!

-- Schritt 1: Alle Policies erlauben (für Development)
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE access_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "allow_all_households" ON households FOR ALL
TO authenticated, anon USING (true);

CREATE POLICY "allow_all_access_keys" ON access_keys FOR ALL
TO authenticated, anon USING (true);

-- Schritt 2: Später verfeinern (wenn alles funktioniert)
-- DROP POLICY "allow_all_households" ON households;
-- CREATE POLICY "household_access" ON households FOR ALL
-- USING (
--   master_key = current_setting('app.user_key', true) OR
--   EXISTS (
--     SELECT 1 FROM access_keys
--     WHERE household_id = households.id
--     AND key_code = current_setting('app.user_key', true)
--     AND is_active = true
--   )
-- );
```

#### 1.3 Helper Functions
```sql
-- Haushalt Setup (sicher, ohne RLS-Konflikte)
CREATE OR REPLACE FUNCTION setup_household(
  p_master_key TEXT,
  p_name TEXT DEFAULT 'Mein Haushalt'
) RETURNS UUID AS $$
DECLARE
  v_household_id UUID;
BEGIN
  -- Prüfe ob Haushalt bereits existiert
  SELECT id INTO v_household_id
  FROM households
  WHERE master_key = p_master_key;

  IF v_household_id IS NULL THEN
    -- Erstelle neuen Haushalt
    INSERT INTO households (master_key, name)
    VALUES (p_master_key, p_name)
    RETURNING id INTO v_household_id;

    -- Erstelle Master-Key Eintrag
    INSERT INTO access_keys (household_id, key_code, key_type, permissions)
    VALUES (v_household_id, p_master_key, 'master', ARRAY['read', 'write', 'admin']);
  END IF;

  RETURN v_household_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- User Haushalt abrufen
CREATE OR REPLACE FUNCTION get_user_household(p_user_key TEXT)
RETURNS TABLE(id UUID, name TEXT, master_key TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT h.id, h.name, h.master_key
  FROM households h
  WHERE h.master_key = p_user_key
  OR EXISTS (
    SELECT 1 FROM access_keys ak
    WHERE ak.household_id = h.id
    AND ak.key_code = p_user_key
    AND ak.is_active = true
    AND (ak.expires_at IS NULL OR ak.expires_at > now())
  )
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Phase 2: Flutter Service Layer

#### 2.1 Sauberer HouseholdService
```dart
// lib/core/services/household_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class HouseholdService {
  static const String _masterKeyPref = 'master_key';
  static const String _importedKeysPref = 'imported_keys';

  final SupabaseClient _client = Supabase.instance.client;
  String? _currentUserKey;

  String? get currentKey => _currentUserKey;

  /// Initialize und Master-Key generieren/laden
  Future<String> initializeMasterKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? masterKey = prefs.getString(_masterKeyPref);

    if (masterKey == null) {
      masterKey = _generateReadableKey();
      await prefs.setString(_masterKeyPref, masterKey);
      debugPrint('Generated new master key: $masterKey');

      // Haushalt erstellen (ohne await - im Hintergrund)
      _createHouseholdAsync(masterKey);
    } else {
      debugPrint('Using existing master key: $masterKey');
    }

    _currentUserKey = masterKey;
    return masterKey;
  }

  /// Lesbaren Key generieren
  String _generateReadableKey() {
    final words = ['APFEL', 'BIRNE', 'MANGO', 'KIWI', 'TRAUBE', 'ORANGE'];
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    final word = words[random.nextInt(words.length)];
    final code = List.generate(4, (_) =>
      chars[random.nextInt(chars.length)]
    ).join();

    return '$word-$code';
  }

  /// Haushalt im Hintergrund erstellen
  Future<void> _createHouseholdAsync(String masterKey) async {
    try {
      await _client.rpc('setup_household', params: {
        'p_master_key': masterKey,
        'p_name': 'Mein Haushalt',
      });
      debugPrint('Household created successfully');
    } catch (e) {
      debugPrint('Household creation failed: $e');
      // Nicht kritisch - wird beim nächsten Start versucht
    }
  }

  /// Sub-Key erstellen
  Future<String?> createSubKey({
    required List<String> permissions,
    String? nickname,
    DateTime? expiresAt,
  }) async {
    try {
      // Einfachen Sub-Key generieren
      final code = List.generate(8, (_) => Random.secure().nextInt(10)).join();
      final subKey = 'SUB-$code';

      // Haushalt-ID für aktuellen Master-Key
      final households = await _client
          .from('households')
          .select('id')
          .eq('master_key', _currentUserKey!)
          .limit(1);

      if (households.isEmpty) {
        debugPrint('No household found for master key');
        return null;
      }

      final householdId = households.first['id'];

      // Sub-Key in Datenbank speichern
      await _client.from('access_keys').insert({
        'household_id': householdId,
        'key_code': subKey,
        'key_type': 'sub',
        'permissions': permissions,
        'created_by': _currentUserKey,
        'expires_at': expiresAt?.toIso8601String(),
        'is_active': true,
      });

      debugPrint('Sub-key created: $subKey');
      return subKey;
    } catch (e) {
      debugPrint('Error creating sub-key: $e');
      return null;
    }
  }

  /// Aktive Sub-Keys abrufen
  Future<List<Map<String, dynamic>>> getActiveSubKeys() async {
    try {
      // Erst Haushalt finden
      final households = await _client
          .from('households')
          .select('id')
          .eq('master_key', _currentUserKey!)
          .limit(1);

      if (households.isEmpty) return [];

      final householdId = households.first['id'];

      // Dann Sub-Keys für diesen Haushalt
      final keys = await _client
          .from('access_keys')
          .select()
          .eq('household_id', householdId)
          .eq('key_type', 'sub')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(keys);
    } catch (e) {
      debugPrint('Error getting sub-keys: $e');
      return [];
    }
  }

  /// Sub-Key widerrufen
  Future<bool> revokeSubKey(String subKey) async {
    try {
      await _client
          .from('access_keys')
          .update({
            'is_active': false,
            'revoked_at': DateTime.now().toIso8601String(),
          })
          .eq('key_code', subKey);

      debugPrint('Sub-key revoked: $subKey');
      return true;
    } catch (e) {
      debugPrint('Error revoking sub-key: $e');
      return false;
    }
  }

  /// Key importieren (QR-Code gescannt)
  Future<bool> importKey(String keyCode) async {
    try {
      // Prüfe ob Key gültig ist
      final households = await _client.rpc('get_user_household',
        params: {'p_user_key': keyCode}
      );

      if (households != null && households.isNotEmpty) {
        // Speichere als importierten Key
        final prefs = await SharedPreferences.getInstance();
        final imported = prefs.getStringList(_importedKeysPref) ?? [];

        if (!imported.contains(keyCode)) {
          imported.add(keyCode);
          await prefs.setStringList(_importedKeysPref, imported);
        }

        // Wechsle zu diesem Key
        _currentUserKey = keyCode;
        debugPrint('Successfully imported key: $keyCode');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error importing key: $e');
      return false;
    }
  }

  /// Zwischen Keys wechseln
  Future<void> switchToKey(String keyCode) async {
    _currentUserKey = keyCode;
    debugPrint('Switched to key: $keyCode');
  }

  /// Verfügbare Keys (Master + Importierte)
  Future<List<String>> getAvailableKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final masterKey = prefs.getString(_masterKeyPref);
    final imported = prefs.getStringList(_importedKeysPref) ?? [];

    final keys = <String>[];
    if (masterKey != null) keys.add(masterKey);
    keys.addAll(imported);

    return keys;
  }
}
```

#### 2.2 Dependency Injection
```dart
// In injection_container.dart hinzufügen:
import 'core/services/household_service.dart';

// In init() Funktion:
sl.registerLazySingleton(() => HouseholdService());
```

### Phase 3: UI Implementation

#### 3.1 Haushalt-Management Screen
```dart
// lib/features/household/presentation/pages/household_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/household_service.dart';

class HouseholdManagementPage extends StatefulWidget {
  const HouseholdManagementPage({super.key});

  @override
  State<HouseholdManagementPage> createState() => _HouseholdManagementPageState();
}

class _HouseholdManagementPageState extends State<HouseholdManagementPage> {
  final _householdService = GetIt.instance<HouseholdService>();
  List<Map<String, dynamic>> _activeSubKeys = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubKeys();
  }

  Future<void> _loadSubKeys() async {
    setState(() => _isLoading = true);
    final keys = await _householdService.getActiveSubKeys();
    setState(() {
      _activeSubKeys = keys;
      _isLoading = false;
    });
  }

  Future<void> _createSubKey(BuildContext context) async {
    // Dialog für Berechtigungen
    final permissions = await showDialog<List<String>>(
      context: context,
      builder: (context) => _PermissionDialog(),
    );

    if (permissions != null && permissions.isNotEmpty) {
      final subKey = await _householdService.createSubKey(
        permissions: permissions,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      if (subKey != null && mounted) {
        await _showQRCode(context, subKey, permissions);
        await _loadSubKeys();
      }
    }
  }

  Future<void> _showQRCode(BuildContext context, String subKey, List<String> permissions) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neuer Zugangsschlüssel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR Code
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: subKey,
                version: QrVersions.auto,
                size: 180,
              ),
            ),
            const SizedBox(height: 16),
            // Key als Text
            SelectableText(
              subKey,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Berechtigung: ${permissions.join(', ')}'),
            const SizedBox(height: 16),
            // Copy Button
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: subKey));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code kopiert!')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Kopieren'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haushalt verwalten'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                             color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sie sind Administrator',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Erstellen Sie Zugänge für Haushaltsmitglieder',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sub-Keys Liste
                Expanded(
                  child: _activeSubKeys.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                   size: 64, color: Theme.of(context).disabledColor),
                              const SizedBox(height: 16),
                              const Text('Noch keine Zugänge erstellt'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activeSubKeys.length,
                          itemBuilder: (context, index) {
                            final key = _activeSubKeys[index];
                            final permissions = List<String>.from(key['permissions'] ?? []);

                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(key['key_code'] ?? 'Unbekannt',
                                    style: const TextStyle(fontFamily: 'monospace')),
                                subtitle: Text('Berechtigung: ${permissions.join(', ')}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _revokeKey(key['key_code']),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createSubKey(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Zugang erstellen'),
      ),
    );
  }

  Future<void> _revokeKey(String keyCode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zugang widerrufen?'),
        content: Text('Möchten Sie den Zugang "$keyCode" wirklich widerrufen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Widerrufen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _householdService.revokeSubKey(keyCode);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zugang wurde widerrufen')),
        );
        await _loadSubKeys();
      }
    }
  }
}

// Permission Dialog
class _PermissionDialog extends StatefulWidget {
  @override
  State<_PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<_PermissionDialog> {
  bool _canRead = true;
  bool _canWrite = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Berechtigungen wählen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text('Lesen'),
            subtitle: const Text('Kann Lebensmittel sehen'),
            value: _canRead,
            onChanged: (value) => setState(() => _canRead = value ?? true),
          ),
          CheckboxListTile(
            title: const Text('Bearbeiten'),
            subtitle: const Text('Kann Lebensmittel hinzufügen/ändern'),
            value: _canWrite,
            onChanged: (value) => setState(() => _canWrite = value ?? false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            final permissions = <String>[];
            if (_canRead) permissions.add('read');
            if (_canWrite) permissions.add('write');
            Navigator.of(context).pop(permissions);
          },
          child: const Text('Erstellen'),
        ),
      ],
    );
  }
}
```

#### 3.2 QR-Code Scanner
```dart
// lib/features/household/presentation/pages/qr_scanner_page.dart
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/household_service.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final _householdService = GetIt.instance<HouseholdService>();
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-Code scannen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Richten Sie die Kamera auf den QR-Code'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showManualInput(context),
                    child: const Text('Code manuell eingeben'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        _processScannedCode(scanData.code!);
      }
    });
  }

  Future<void> _processScannedCode(String code) async {
    controller?.pauseCamera();

    final success = await _householdService.importKey(code);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zugang erfolgreich importiert!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ungültiger oder abgelaufener Code')),
        );
        controller?.resumeCamera();
      }
    }
  }

  Future<void> _showManualInput(BuildContext context) async {
    final controller = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code eingeben'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'z.B. SUB-12345678',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Importieren'),
          ),
        ],
      ),
    );

    if (code != null && code.isNotEmpty) {
      await _processScannedCode(code);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
```

#### 3.3 Navigation einbinden
```dart
// In settings_page.dart hinzufügen:
import '../../../household/presentation/pages/household_management_page.dart';

// In der ListView nach den Benachrichtigungen:
const Divider(height: 32),
const Padding(
  padding: EdgeInsets.all(16.0),
  child: Text(
    'Haushalt',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),
),
ListTile(
  leading: const Icon(Icons.group, color: Colors.blue),
  title: const Text('Haushalt verwalten'),
  subtitle: const Text('Zugänge für Mitbewohner erstellen'),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HouseholdManagementPage(),
      ),
    );
  },
),
ListTile(
  leading: const Icon(Icons.qr_code_scanner, color: Colors.green),
  title: const Text('QR-Code scannen'),
  subtitle: const Text('Zugang zu anderem Haushalt'),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRScannerPage(),
      ),
    );
  },
),
```

### Phase 4: Abhängigkeiten hinzufügen

#### 4.1 pubspec.yaml erweitern
```yaml
dependencies:
  # Bestehende Dependencies...

  # Backend & Sync
  supabase_flutter: ^2.3.2

  # QR Code
  qr_flutter: ^4.1.0
  qr_code_scanner: ^1.0.1
```

#### 4.2 Permissions (iOS)
```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>QR-Codes für Haushalts-Zugänge scannen</string>
```

#### 4.3 Permissions (Android)
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
```

## Entwicklungsreihenfolge (Empfohlen)

### Woche 1: Foundation
1. ✅ Supabase-Tabellen erstellen
2. ✅ Helper Functions einrichten
3. ✅ HouseholdService implementieren
4. ✅ Basic UI für Management

### Woche 2: Core Features
5. Sub-Key CRUD Operations testen
6. QR-Code Generation/Scanning
7. Error Handling verfeinern

### Woche 3: Data Layer
8. Food-Sync mit Households
9. Conflict Resolution
10. Offline-Mode

### Woche 4: Polish & Security
11. RLS Policies verfeinern
12. Performance-Optimierung
13. Ausführliches Testing

## Häufige Fallstricke (Vermeiden!)

### ❌ Was NICHT tun:
1. **Master-Key als QR teilen** → Sicherheitsrisiko
2. **Komplexe RLS von Anfang an** → Endlose Debugging-Schleifen
3. **Sync ohne Offline-First** → Datenverlust
4. **Direkte UI-DB Calls** → Tight Coupling

### ✅ Best Practices:
1. **Service Layer verwenden** → Saubere Abstraktion
2. **Schrittweise RLS einführen** → Erst funktional, dann sicher
3. **Umfangreiches Logging** → Einfaches Debugging
4. **Feature Flags** → Rollback-fähig entwickeln

## Testing-Strategie

### Unit Tests
```dart
// test/services/household_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('HouseholdService', () {
    test('should generate readable master key', () {
      final service = HouseholdService();
      final key = service._generateReadableKey();

      expect(key, matches(r'^[A-Z]+-[A-Z0-9]{4}$'));
    });

    test('should create sub-key with correct permissions', () async {
      // Mock Supabase calls
      final subKey = await householdService.createSubKey(
        permissions: ['read', 'write']
      );

      expect(subKey, startsWith('SUB-'));
      expect(subKey?.length, equals(12)); // SUB- + 8 digits
    });
  });
}
```

### Integration Tests
```dart
// integration_test/household_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Household Multi-User Flow', () {
    testWidgets('should share household via QR code', (tester) async {
      // 1. Master-User erstellt Sub-Key
      await tester.pumpWidget(MyApp());

      // Gehe zu Einstellungen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Gehe zu Haushalt verwalten
      await tester.tap(find.text('Haushalt verwalten'));
      await tester.pumpAndSettle();

      // Erstelle Sub-Key
      await tester.tap(find.text('Zugang erstellen'));
      await tester.pumpAndSettle();

      // Wähle Berechtigungen
      await tester.tap(find.text('Erstellen'));
      await tester.pumpAndSettle();

      // QR-Code sollte angezeigt werden
      expect(find.byType(QrImageView), findsOneWidget);
    });
  });
}
```

## Rollback-Plan

Falls das Feature Probleme macht:
1. **Feature Flag ausschalten** → Zurück zu lokalem Modus
2. **Daten bleiben lokal** → Kein Datenverlust
3. **Migration ist optional** → User entscheidet
4. **Schrittweise Einführung** → Erst Beta-User

## Performance-Überlegungen

### Datenbank-Optimierung
- Indexes auf `household_id`, `key_code`, `is_active`
- Connection Pooling für Supabase
- Query-Optimierung mit EXPLAIN ANALYZE

### App-Performance
- Lazy Loading für große Haushaltslisten
- Caching für häufige Queries
- Background Sync ohne UI-Blocking

## Sicherheits-Checkliste

- [ ] Master-Keys niemals in Logs ausgeben
- [ ] Sub-Key Expiration implementiert
- [ ] Rate Limiting für Key-Erstellung
- [ ] Input Validation für alle APIs
- [ ] HTTPS-Only für alle Verbindungen
- [ ] SQL Injection Protection (durch Supabase)

## Nächste Schritte

1. **Reset auf sauberen Branch**
   ```bash
   git checkout main
   git stash  # Falls ungespeicherte Änderungen
   ```

2. **Feature Branch erstellen**
   ```bash
   git checkout -b feature/multi-user-household
   ```

3. **Schritt-für-Schritt implementieren**
   - Phase 1: Backend Setup
   - Phase 2: Service Layer
   - Phase 3: UI Implementation
   - Phase 4: Testing & Polish

4. **Nach jedem Schritt**
   - Funktionalität testen
   - Commit mit aussagekräftiger Message
   - Bei Problemen: Einzelne Commits rückgängig machen

5. **Deployment**
   - Ausführliche Tests auf verschiedenen Geräten
   - Beta-Release für kleine Nutzergruppe
   - Monitoring für Performance & Errors

Das ist ein langfristiges Feature - lieber langsam und sauber als schnell und chaotisch! 🎯

## Hilfreiche Ressourcen

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [Flutter QR Code Packages](https://pub.dev/packages/qr_flutter)
- [Clean Architecture in Flutter](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [BLoC Pattern Guide](https://bloclibrary.dev/)

Viel Erfolg bei der Implementierung! 🚀