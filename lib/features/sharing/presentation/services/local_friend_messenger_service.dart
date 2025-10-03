import 'package:shared_preferences/shared_preferences.dart';
import 'messenger_type.dart';

/// Service zum lokalen Speichern der Messenger-Präferenzen für Friends
class LocalFriendMessengerService {
  static const String _prefix = 'friend_messenger_';

  /// Speichert den bevorzugten Messenger für einen Friend
  static Future<void> setFriendMessenger(
    String friendId,
    MessengerType messenger,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$friendId', messenger.name);
  }

  /// Lädt den bevorzugten Messenger für einen Friend
  static Future<MessengerType?> getFriendMessenger(String friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final messengerName = prefs.getString('$_prefix$friendId');
    return MessengerType.fromString(messengerName);
  }

  /// Entfernt den Messenger für einen Friend
  static Future<void> removeFriendMessenger(String friendId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$friendId');
  }
}
