import 'package:shared_preferences/shared_preferences.dart';

/// Service für lokale Speicherung von Friend-Namen auf dem Gerät
class LocalFriendNamesService {
  static const String _keyPrefix = 'friend_name_';

  /// Speichert den Namen für einen Friend lokal
  static Future<void> setFriendName(String friendId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$friendId', name);
  }

  /// Lädt den Namen für einen Friend lokal
  static Future<String?> getFriendName(String friendId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix$friendId');
  }

  /// Entfernt den Namen für einen Friend lokal
  static Future<void> removeFriendName(String friendId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$friendId');
  }

  /// Lädt alle lokal gespeicherten Friend-Namen
  static Future<Map<String, String>> getAllFriendNames() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

    final friendNames = <String, String>{};
    for (final key in keys) {
      final friendId = key.substring(_keyPrefix.length);
      final name = prefs.getString(key);
      if (name != null) {
        friendNames[friendId] = name;
      }
    }

    return friendNames;
  }

  /// Prüft ob ein Friend einen lokalen Namen hat
  static Future<bool> hasFriendName(String friendId) async {
    final name = await getFriendName(friendId);
    return name != null && name.isNotEmpty;
  }
}
