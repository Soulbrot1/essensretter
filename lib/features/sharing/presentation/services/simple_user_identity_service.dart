import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import '../../../../core/utils/app_logger.dart';

/// Service für sichere Verwaltung der RetterId mit Dual-Storage-Strategie
///
/// Speichert die RetterId parallel in:
/// - FlutterSecureStorage (primär): iOS Keychain / Android Keystore
///   → Wird automatisch von iCloud/Google Backup mitgesichert
/// - SharedPreferences (sekundär): Fallback bei Secure Storage Fehlern
///
/// Migriert automatisch bestehende UserIDs von SharedPreferences zu Secure Storage.
class SimpleUserIdentityService {
  static const String _userIdentityKey = 'user_identity_v2';
  static const String _secureStorageKey = 'essensretter_user_id';

  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Hauptmethode: Holt RetterId mit automatischer Migration und Dual-Storage
  ///
  /// Implementiert 3 Szenarien:
  /// 1. Bestehender User: Migration von SharedPreferences → Secure Storage
  /// 2. Neuer User: Generierung + Speicherung in beide Speicher
  /// 3. Nach OS-Backup-Wiederherstellung: Sync zurück zu SharedPreferences
  static Future<String> ensureUserIdentity() async {
    try {
      // Szenario 1 & 3: Prüfe Secure Storage (primär)
      String? userId = await _secureStorage.read(key: _secureStorageKey);

      if (userId != null) {
        // Szenario 3: Nach OS-Backup-Wiederherstellung
        // Sync zurück zu SharedPreferences für Konsistenz
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString(_userIdentityKey) == null) {
          await prefs.setString(_userIdentityKey, userId);
        }
        return userId;
      }

      // Szenario 1: Migration - Prüfe SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString(_userIdentityKey);

      if (userId != null) {
        // Bestehender User → Migration zu Secure Storage
        try {
          await _secureStorage.write(key: _secureStorageKey, value: userId);
        } catch (e) {
          // Fallback: Wenn Secure Storage fehlschlägt, funktioniert SharedPreferences weiter
          AppLogger.warning(
            'Secure Storage Migration fehlgeschlagen',
            error: e,
          );
        }
        return userId;
      }

      // Szenario 2: Neuer User → Generiere neue RetterId
      userId = _generateUserId();

      // Dual-Storage: Schreibe in beide parallel
      await Future.wait([
        _secureStorage.write(key: _secureStorageKey, value: userId).catchError((
          e,
        ) {
          AppLogger.warning(
            'Secure Storage Schreiben fehlgeschlagen',
            error: e,
          );
          return null;
        }),
        prefs.setString(_userIdentityKey, userId).then((_) => null),
      ]);

      return userId;
    } catch (e) {
      rethrow;
    }
  }

  /// Gibt die aktuelle RetterId zurück (nur lesen, keine Generierung)
  ///
  /// Gibt null zurück wenn keine RetterId vorhanden ist
  static Future<String?> getCurrentUserId() async {
    try {
      // 1. Check secure_storage (primary)
      String? userId = await _secureStorage.read(key: _secureStorageKey);
      if (userId != null) return userId;

      // 2. Check SharedPreferences (fallback)
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdentityKey);
    } catch (e) {
      return null;
    }
  }

  /// Setzt eine neue RetterId (z.B. nach Restore)
  ///
  /// Überschreibt RetterId in beiden Speichern
  static Future<void> setRetterId(String retterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        _secureStorage
            .write(key: _secureStorageKey, value: retterId)
            .catchError((e) {
              AppLogger.warning(
                'Secure Storage Schreiben fehlgeschlagen',
                error: e,
              );
              return null;
            }),
        prefs.setString(_userIdentityKey, retterId).then((_) => null),
      ]);
    } catch (e) {
      AppLogger.error('Fehler beim Setzen der RetterId', error: e);
      rethrow;
    }
  }

  /// Prüft ob User neu ist (keine RetterId vorhanden)
  ///
  /// Verwendet für Onboarding-Dialog Entscheidung
  static Future<bool> isNewUser() async {
    try {
      final secureId = await _secureStorage.read(key: _secureStorageKey);
      if (secureId != null) return false;

      final prefs = await SharedPreferences.getInstance();
      final prefsId = prefs.getString(_userIdentityKey);
      return prefsId == null;
    } catch (e) {
      return true; // Bei Fehler als neuer User behandeln
    }
  }

  /// Generiert eine neue RetterId im Format ER-XXXXXXXX
  ///
  /// Production-ready User-ID Format:
  /// - Format: ER-XXXXXXXX (11 Zeichen total)
  /// - ER = EssensRetter Präfix
  /// - 8 Base36 Zeichen (0-9, A-Z)
  /// - Kapazität: 36^8 = 2.8 Billionen User-IDs
  /// - Collision-resistent und human-readable
  /// - Verwendet Random.secure() für kryptographische Sicherheit
  static String _generateUserId() {
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
}
