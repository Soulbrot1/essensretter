import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// Service für lokale Key-Verwaltung (ohne Backend)
///
/// Coding-Prinzip: Single Responsibility
/// Diese Klasse macht NUR Key-Verwaltung, nichts anderes
class LocalKeyService {
  static const String _masterKeyPref = 'master_key';
  static const String _createdAtPref = 'master_key_created_at';
  static const String _subKeysPref = 'sub_keys';

  final SharedPreferences _prefs;

  LocalKeyService(this._prefs);

  // Coding-Prinzip: Dependency Injection
  // Wir erstellen SharedPreferences nicht selbst, sondern bekommen es
  static Future<LocalKeyService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalKeyService(prefs);
  }

  /// Generiert einen lesbaren Master-Key
  /// Format: WORT-XXXX (z.B. APFEL-X7K9)
  ///
  /// Coding-Prinzip: Pure Function
  /// Keine Seiteneffekte, immer testbar
  String generateMasterKey() {
    final random = Random.secure(); // Secure für Krypto-Sicherheit

    // Leicht merkbare Wörter (Obst passt zur App!)
    const words = [
      'APFEL',
      'BIRNE',
      'MANGO',
      'KIWI',
      'TRAUBE',
      'ORANGE',
      'BANANE',
      'ZITRONE',
    ];

    // Wähle zufälliges Wort
    final word = words[random.nextInt(words.length)];

    // Generiere 4-stelligen Code aus Buchstaben und Zahlen
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = List.generate(
      4,
      (_) => chars[random.nextInt(chars.length)],
    ).join();

    return '$word-$code';
  }

  /// Initialisiert oder lädt den Master-Key
  ///
  /// Coding-Prinzip: Idempotenz
  /// Mehrfaches Aufrufen hat das gleiche Ergebnis
  Future<String> initializeMasterKey() async {
    // Prüfe ob bereits ein Key existiert
    final existingKey = _prefs.getString(_masterKeyPref);

    if (existingKey != null) {
      debugPrint('Existing master key found: ${_maskKey(existingKey)}');
      return existingKey;
    }

    // Generiere neuen Key
    final newKey = generateMasterKey();

    // Speichere Key und Zeitstempel
    await _prefs.setString(_masterKeyPref, newKey);
    await _prefs.setString(_createdAtPref, DateTime.now().toIso8601String());

    debugPrint('New master key generated: ${_maskKey(newKey)}');
    return newKey;
  }

  /// Holt den aktuellen Master-Key
  ///
  /// Coding-Prinzip: Null Safety
  /// Explizit mit null umgehen
  String? getMasterKey() {
    return _prefs.getString(_masterKeyPref);
  }

  /// Löscht den Master-Key (für Tests/Reset)
  ///
  /// Coding-Prinzip: Explicit Intent
  /// Gefährliche Operationen deutlich benennen
  Future<bool> deleteMasterKeyPermanently() async {
    final success = await _prefs.remove(_masterKeyPref);
    await _prefs.remove(_createdAtPref);
    await _prefs.remove(_subKeysPref);

    debugPrint('Master key deleted: $success');
    return success;
  }

  /// Generiert einen Sub-Key
  /// Format: SUB-XXXXXXXX (8 Ziffern)
  String generateSubKey() {
    final random = Random.secure();
    final code = List.generate(8, (_) => random.nextInt(10).toString()).join();

    return 'SUB-$code';
  }

  /// Speichert einen Sub-Key mit Berechtigungen
  Future<void> saveSubKey(String subKey, List<String> permissions) async {
    final subKeys = _prefs.getStringList(_subKeysPref) ?? [];

    // Format: "KEY|permission1,permission2|timestamp"
    final entry =
        '$subKey|${permissions.join(',')}|${DateTime.now().toIso8601String()}';
    subKeys.add(entry);

    await _prefs.setStringList(_subKeysPref, subKeys);
    debugPrint('Sub-key saved: ${_maskKey(subKey)}');
  }

  /// Lädt alle Sub-Keys
  List<SubKeyInfo> getSubKeys() {
    final subKeys = _prefs.getStringList(_subKeysPref) ?? [];

    return subKeys
        .map((entry) {
          final parts = entry.split('|');
          if (parts.length != 3) return null;

          return SubKeyInfo(
            key: parts[0],
            permissions: parts[1].split(','),
            createdAt: DateTime.parse(parts[2]),
          );
        })
        .whereType<SubKeyInfo>()
        .toList(); // Filtert null-Werte
  }

  /// Widerruft einen Sub-Key
  Future<bool> revokeSubKey(String subKey) async {
    final subKeys = _prefs.getStringList(_subKeysPref) ?? [];
    final sizeBefore = subKeys.length;

    // Entferne alle Einträge die mit diesem Key beginnen
    subKeys.removeWhere((entry) => entry.startsWith('$subKey|'));

    if (subKeys.length < sizeBefore) {
      await _prefs.setStringList(_subKeysPref, subKeys);
      debugPrint('Sub-key revoked: ${_maskKey(subKey)}');
      return true;
    }

    return false;
  }

  /// Maskiert einen Key für sicheres Logging
  ///
  /// Coding-Prinzip: Security by Default
  /// Niemals sensitive Daten komplett loggen
  String _maskKey(String key) {
    if (key.length <= 4) return '****';
    return '${key.substring(0, 4)}****';
  }

  /// Prüft ob dies die erste App-Nutzung ist
  bool isFirstTimeUser() {
    return _prefs.getString(_masterKeyPref) == null;
  }

  /// Gibt Statistiken zurück
  Map<String, dynamic> getStatistics() {
    final createdAt = _prefs.getString(_createdAtPref);
    final subKeys = getSubKeys();

    return {
      'hasMasterKey': getMasterKey() != null,
      'masterKeyAge': createdAt != null
          ? DateTime.now().difference(DateTime.parse(createdAt)).inDays
          : null,
      'totalSubKeys': subKeys.length,
      'activeSubKeys': subKeys.length, // Später: Nur aktive zählen
    };
  }
}

/// Datenklasse für Sub-Key Informationen
///
/// Coding-Prinzip: Data Class
/// Unveränderlich (immutable) und typsicher
class SubKeyInfo {
  final String key;
  final List<String> permissions;
  final DateTime createdAt;

  const SubKeyInfo({
    required this.key,
    required this.permissions,
    required this.createdAt,
  });

  bool get canRead => permissions.contains('read');
  bool get canWrite => permissions.contains('write');
  bool get isReadOnly => canRead && !canWrite;
}
