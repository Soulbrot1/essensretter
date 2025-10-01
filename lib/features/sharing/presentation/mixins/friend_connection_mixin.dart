import 'dart:async';
import 'package:flutter/material.dart';
import '../services/friend_connection_listener.dart';
import '../services/friend_service.dart';
import '../widgets/new_friend_popup.dart';

/// Mixin für Seiten, die auf neue Friend-Verbindungen reagieren sollen
mixin FriendConnectionMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<FriendConnection>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _startListeningForConnections();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _startListeningForConnections() {
    // Starte den globalen Listener (falls noch nicht gestartet)
    FriendConnectionListener.startListening();

    // Abonniere neue Verbindungen
    _connectionSubscription = FriendConnectionListener.onNewConnection.listen((
      connection,
    ) {
      if (mounted) {
        _showNewConnectionPopup(connection);
      }
    });
  }

  void _showNewConnectionPopup(FriendConnection connection) {
    showDialog(
      context: context,
      barrierDismissible: false, // User muss entscheiden
      builder: (context) => NewFriendPopup(
        connection: connection,
        onAccepted: () {
          // Optional: Refresh der aktuellen Seite
          onConnectionAccepted();
        },
        onRejected: () {
          // Optional: Refresh der aktuellen Seite
          onConnectionRejected();
        },
      ),
    );
  }

  /// Override diese Methode, um auf akzeptierte Verbindungen zu reagieren
  void onConnectionAccepted() {
    // Standard: Nichts tun
    // Kann in der implementierenden Klasse überschrieben werden
  }

  /// Override diese Methode, um auf abgelehnte Verbindungen zu reagieren
  void onConnectionRejected() {
    // Standard: Nichts tun
    // Kann in der implementierenden Klasse überschrieben werden
  }
}
