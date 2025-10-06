import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../services/messenger_type.dart';

/// Helper-Klasse für alle Dialoge in der Friends-Page
class FriendsDialogHelpers {
  /// Zeigt Dialog zum Entfernen eines Friends
  static Future<bool> showRemoveFriendDialog(
    BuildContext context,
    FriendConnection friend,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Friend entfernen'),
        content: Text(
          'Möchtest du ${friend.friendName ?? friend.friendId} wirklich als Friend entfernen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  /// Zeigt Dialog zum Ändern des Friend-Namens
  static Future<String?> showUpdateNameDialog(
    BuildContext context,
    FriendConnection friend,
  ) async {
    final controller = TextEditingController(text: friend.friendName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Namen ändern'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Neuer Name für diesen Friend',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    // Only return if valid and different
    if (newName != null && newName.isNotEmpty && newName != friend.friendName) {
      return newName;
    }
    return null;
  }

  /// Zeigt Dialog zum Ändern des bevorzugten Messengers
  static Future<MessengerType?> showUpdateMessengerDialog(
    BuildContext context,
    FriendConnection friend,
  ) async {
    MessengerType selectedMessenger =
        friend.preferredMessenger ?? MessengerType.whatsapp;

    final newMessenger = await showDialog<MessengerType>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Messenger ändern'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bevorzugter Messenger für ${friend.friendName ?? friend.friendId}:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...MessengerType.values
                  .where((m) => m != MessengerType.none)
                  .map(
                    (messenger) => RadioListTile<MessengerType>(
                      value: messenger,
                      groupValue: selectedMessenger,
                      onChanged: (value) {
                        setState(() {
                          selectedMessenger = value!;
                        });
                      },
                      title: Row(
                        children: [
                          Icon(messenger.icon, size: 20),
                          const SizedBox(width: 12),
                          Text(messenger.displayName),
                        ],
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selectedMessenger),
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    // Only return if different
    if (newMessenger != null && newMessenger != friend.preferredMessenger) {
      return newMessenger;
    }
    return null;
  }
}
