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
        return;
      }

      // Wenn bereits ein Listener läuft, stoppe ihn nicht neu
      if (_channel != null) {
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
              _handleNewConnection(payload.newRecord);
            },
          )
          .subscribe();
    } catch (e) {
      // Subscription failed - non-critical
    }
  }

  /// Verarbeitet neue Verbindungen
  static void _handleNewConnection(Map<String, dynamic> record) {
    try {
      // Jede neue Verbindung benötigt einen lokalen Namen
      final connection = FriendConnection.fromSupabase(record);

      // Benachrichtige alle Listener
      _newConnectionController?.add(connection);
    } catch (e) {
      // Failed to parse connection - skip
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
  }

  /// Dispose resources
  static void dispose() {
    stopListening();
    _newConnectionController?.close();
    _newConnectionController = null;
  }
}
