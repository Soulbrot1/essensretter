import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'simple_user_identity_service.dart';
import 'local_friend_names_service.dart';

class FriendConnection {
  final String userId;
  final String friendId;
  final String? friendName; // Wird lokal geladen, nicht aus Supabase
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
      friendName: null, // Name wird separat lokal geladen
      status: data['status'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  /// Erstellt eine Kopie mit lokalem Namen
  FriendConnection copyWithLocalName(String? localName) {
    return FriendConnection(
      userId: userId,
      friendId: friendId,
      friendName: localName,
      status: status,
      createdAt: createdAt,
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

      // Erstelle bidirektionale Verbindung (ohne Namen in Supabase)
      print('DEBUG: Creating connection 1: $currentUserId -> $friendId');
      // 1. Verbindung: Current User -> Friend
      await client.from('user_connections').insert({
        'user_id': currentUserId,
        'friend_id': friendId,
        'status': 'connected',
      });

      print('DEBUG: Creating connection 2: $friendId -> $currentUserId');
      // 2. Verbindung: Friend -> Current User
      await client.from('user_connections').insert({
        'user_id': friendId,
        'friend_id': currentUserId,
        'status': 'connected',
      });

      // Speichere Namen lokal
      await LocalFriendNamesService.setFriendName(friendId, friendName);
      print('DEBUG: Local name saved: $friendId -> $friendName');

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

      print('DEBUG: Loading friends for user: $currentUserId');

      final response = await client
          .from('user_connections')
          .select()
          .eq('user_id', currentUserId)
          .eq('status', 'connected')
          .order('created_at', ascending: false);

      print('DEBUG: Raw Supabase response: $response');

      // Lade lokale Namen für alle Friends
      final friendConnections = <FriendConnection>[];
      for (final data in (response as List)) {
        final connection = FriendConnection.fromSupabase(data);
        final localName = await LocalFriendNamesService.getFriendName(
          connection.friendId,
        );
        print(
          'DEBUG: Friend ${connection.friendId} has local name: $localName',
        );
        friendConnections.add(connection.copyWithLocalName(localName));
      }

      print('DEBUG: Loaded ${friendConnections.length} friends');
      return friendConnections;
    } catch (e) {
      print('ERROR: Failed to get friends: $e');
      return [];
    }
  }

  /// Aktualisiert den Namen eines Friends (nur lokal)
  static Future<bool> updateFriendName(String friendId, String newName) async {
    try {
      // Speichere Namen nur lokal
      await LocalFriendNamesService.setFriendName(friendId, newName);

      print('DEBUG: Friend name updated locally: $friendId -> $newName');
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

      // Entferne lokalen Namen
      await LocalFriendNamesService.removeFriendName(friendId);

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
