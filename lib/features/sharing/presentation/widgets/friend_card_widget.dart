import 'package:flutter/material.dart';
import '../services/friend_service.dart';

/// Widget für eine einzelne Friend-Card in der Friends-Liste
///
/// Zeigt:
/// - Avatar mit Initial
/// - Name (oder "Unbenannt") mit optionalem "NEU" Badge
/// - Friend-ID
/// - Menü mit Aktionen (Namen ändern, Messenger ändern, Entfernen)
class FriendCardWidget extends StatelessWidget {
  final FriendConnection friend;
  final VoidCallback onRename;
  final VoidCallback onChangeMessenger;
  final VoidCallback onRemove;

  const FriendCardWidget({
    super.key,
    required this.friend,
    required this.onRename,
    required this.onChangeMessenger,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Text(
            (friend.friendName?.isNotEmpty == true
                    ? friend.friendName!.substring(0, 1)
                    : friend.friendId.substring(3, 4))
                .toUpperCase(),
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                friend.friendName ?? 'Unbenannt',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (friend.friendName == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NEU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          friend.friendId,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'rename':
                onRename();
                break;
              case 'messenger':
                onChangeMessenger();
                break;
              case 'remove':
                onRemove();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Namen ändern'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'messenger',
              child: Row(
                children: [
                  Icon(Icons.chat, size: 20),
                  SizedBox(width: 8),
                  Text('Messenger ändern'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Entfernen', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
