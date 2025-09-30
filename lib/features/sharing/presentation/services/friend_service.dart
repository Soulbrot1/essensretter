import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'simple_user_identity_service.dart';

class FriendConnection {
  final String userId;
  final String friendId;
  final String? friendName;
  final String status;
  final DateTime createdAt;

  FriendConnection({
    required this.userId,
    required this.friendId,
    this.friendName,
    required this.status,
    required this.createdAt,
  });

  factory FriendConnection.fromSupabase(Map<String, dynamic> data) {
    return FriendConnection(
      userId: data['user_id'],
      friendId: data['friend_id'],
      friendName: data['friend_name'],
      status: data['status'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }
}

class FriendService {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    _client ??= SupabaseClient(
      dotenv.env['SUPABASE_URL'] ?? '',
      dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    return _client!;
  }

  /// Validiert eine User-ID
  static bool isValidUserId(String userId) {
    // User-ID Format: ER-XXXXXXXX (ER- plus 8 alphanumerische Zeichen)
    final regex = RegExp(r'^ER-[A-Z0-9]{8}$');
    return regex.hasMatch(userId);
  }

  /// Fügt einen Friend hinzu (bidirektionale Verbindung)
  static Future<bool> addFriend(String friendId, String friendName) async {
    try {
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Current user ID not found');
      }

      // Validiere Friend-ID
      if (!isValidUserId(friendId)) {
        throw Exception('Invalid friend ID format');
      }

      // Verhindere Selbst-Hinzufügen
      if (currentUserId == friendId) {
        throw Exception('Cannot add yourself as friend');
      }

      // Prüfe ob bereits verbunden
      final existingConnection = await client
          .from('user_connections')
          .select()
          .eq('user_id', currentUserId)
          .eq('friend_id', friendId)
          .maybeSingle();

      if (existingConnection != null) {
        if (existingConnection['status'] == 'blocked') {
          throw Exception('This user is blocked');
        }
        throw Exception('Already connected with this user');
      }

      // Erstelle bidirektionale Verbindung
      // 1. Verbindung: Current User -> Friend
      await client.from('user_connections').insert({
        'user_id': currentUserId,
        'friend_id': friendId,
        'friend_name': friendName,
        'status': 'connected',
      });

      // 2. Verbindung: Friend -> Current User (ohne Namen, wird später hinzugefügt)
      await client.from('user_connections').insert({
        'user_id': friendId,
        'friend_id': currentUserId,
        'friend_name': null, // Friend muss später einen Namen vergeben
        'status': 'connected',
      });

      print('DEBUG: Friend added successfully: $friendId');
      return true;
    } catch (e) {
      print('ERROR: Failed to add friend: $e');
      rethrow;
    }
  }

  /// Lädt alle Friends des aktuellen Users
  static Future<List<FriendConnection>> getFriends() async {
    try {
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Current user ID not found');
      }

      final response = await client
          .from('user_connections')
          .select()
          .eq('user_id', currentUserId)
          .eq('status', 'connected')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => FriendConnection.fromSupabase(data))
          .toList();
    } catch (e) {
      print('ERROR: Failed to get friends: $e');
      return [];
    }
  }

  /// Aktualisiert den Namen eines Friends
  static Future<bool> updateFriendName(String friendId, String newName) async {
    try {
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Current user ID not found');
      }

      await client
          .from('user_connections')
          .update({'friend_name': newName})
          .eq('user_id', currentUserId)
          .eq('friend_id', friendId);

      print('DEBUG: Friend name updated: $friendId -> $newName');
      return true;
    } catch (e) {
      print('ERROR: Failed to update friend name: $e');
      return false;
    }
  }

  /// Entfernt einen Friend (bidirektional)
  static Future<bool> removeFriend(String friendId) async {
    try {
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Current user ID not found');
      }

      // Lösche beide Richtungen der Verbindung
      await client
          .from('user_connections')
          .delete()
          .eq('user_id', currentUserId)
          .eq('friend_id', friendId);

      await client
          .from('user_connections')
          .delete()
          .eq('user_id', friendId)
          .eq('friend_id', currentUserId);

      print('DEBUG: Friend removed: $friendId');
      return true;
    } catch (e) {
      print('ERROR: Failed to remove friend: $e');
      return false;
    }
  }

  /// Blockiert einen Friend
  static Future<bool> blockFriend(String friendId) async {
    try {
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Current user ID not found');
      }

      // Update status zu "blocked" für diese Richtung
      await client.from('user_connections').upsert({
        'user_id': currentUserId,
        'friend_id': friendId,
        'status': 'blocked',
      });

      // Lösche die andere Richtung
      await client
          .from('user_connections')
          .delete()
          .eq('user_id', friendId)
          .eq('friend_id', currentUserId);

      print('DEBUG: Friend blocked: $friendId');
      return true;
    } catch (e) {
      print('ERROR: Failed to block friend: $e');
      return false;
    }
  }

  /// Prüft ob eine User-ID existiert (für Validierung vor dem Hinzufügen)
  static Future<bool> userExists(String userId) async {
    try {
      // Prüfe ob User schon mal etwas geteilt hat
      final response = await client
          .from('shared_foods')
          .select('user_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('ERROR: Failed to check user existence: $e');
      return false;
    }
  }

  /// Testet die Verbindung zu Supabase
  static Future<bool> testConnection() async {
    try {
      await client.from('user_connections').select('count').limit(1);
      return true;
    } catch (e) {
      print('ERROR: Friend service connection test failed: $e');
      return false;
    }
  }
}
