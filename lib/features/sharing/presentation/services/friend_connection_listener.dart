import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'simple_user_identity_service.dart';
import 'friend_service.dart';

class FriendConnectionListener {
  static RealtimeChannel? _channel;
  static StreamController<FriendConnection>? _newConnectionController;
  static String? _currentUserId;

  /// Startet den Realtime-Listener für neue Friend-Verbindungen
  static Future<void> startListening() async {
    try {
      _currentUserId = await SimpleUserIdentityService.getCurrentUserId();
      if (_currentUserId == null) {
        print('ERROR: Cannot start friend listener - no user ID');
        return;
      }

      // Wenn bereits ein Listener läuft, stoppe ihn nicht neu
      if (_channel != null) {
        print(
          'DEBUG: Friend listener already running for user $_currentUserId',
        );
        return;
      }

      // Stream Controller für neue Verbindungen
      _newConnectionController ??=
          StreamController<FriendConnection>.broadcast();

      // Supabase Realtime Channel für user_connections Tabelle
      _channel = FriendService.client
          .channel('friend_connections_$_currentUserId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'user_connections',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: _currentUserId,
            ),
            callback: (payload) {
              print('DEBUG: Realtime event received for user $_currentUserId');
              print('DEBUG: Payload: ${payload.newRecord}');
              _handleNewConnection(payload.newRecord);
            },
          )
          .subscribe();

      print(
        'DEBUG: Friend connection listener started for user $_currentUserId',
      );
    } catch (e) {
      print('ERROR: Failed to start friend connection listener: $e');
    }
  }

  /// Verarbeitet neue Verbindungen
  static void _handleNewConnection(Map<String, dynamic> record) {
    try {
      // Jede neue Verbindung benötigt einen lokalen Namen
      final connection = FriendConnection.fromSupabase(record);

      print('DEBUG: New friend connection detected: ${connection.friendId}');

      // Benachrichtige alle Listener
      _newConnectionController?.add(connection);
    } catch (e) {
      print('ERROR: Failed to handle new connection: $e');
    }
  }

  /// Stream für neue Verbindungen
  static Stream<FriendConnection> get onNewConnection {
    _newConnectionController ??= StreamController<FriendConnection>.broadcast();
    return _newConnectionController!.stream;
  }

  /// Stoppt den Listener
  static Future<void> stopListening() async {
    await _channel?.unsubscribe();
    _channel = null;
    print('DEBUG: Friend connection listener stopped');
  }

  /// Dispose resources
  static void dispose() {
    stopListening();
    _newConnectionController?.close();
    _newConnectionController = null;
  }
}
