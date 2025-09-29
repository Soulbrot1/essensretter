import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SimpleUserIdentityService {
  static const String _userIdentityKey = 'user_identity_v1';

  static Future<String> ensureUserIdentity() async {
    try {
      // SharedPreferences laden
      final prefs = await SharedPreferences.getInstance();

      // Prüfen ob bereits eine User-ID existiert
      final existingUserId = prefs.getString(_userIdentityKey);

      if (existingUserId != null) {
        print('DEBUG: Existing User-ID found: $existingUserId');
        return existingUserId;
      }

      // Neue User-ID generieren
      final userId = _generateUserId();

      // Speichern
      await prefs.setString(_userIdentityKey, userId);

      print('DEBUG: New User-ID generated and saved: $userId');

      return userId;
    } catch (e) {
      print('ERROR: Failed to ensure user identity: $e');
      rethrow;
    }
  }

  static Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdentityKey);
    } catch (e) {
      print('ERROR: Failed to get current user ID: $e');
      return null;
    }
  }

  static String _generateUserId() {
    const String prefix = 'U-';
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
