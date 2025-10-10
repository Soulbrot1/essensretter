import 'package:flutter/material.dart';
import '../pages/friends_page.dart';
import '../widgets/qr_code_display_dialog.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/add_friend_dialog.dart';
import '../services/simple_user_identity_service.dart';
import '../services/friend_service.dart';

/// User Management Bar für OfferedFoodsBottomSheet
///
/// Enthält:
/// - Button für eigene ID/QR-Code anzeigen
/// - Button zum Nutzer hinzufügen (QR-Scanner)
/// - Button zum Nutzer verwalten
class UserManagementBar extends StatelessWidget {
  final VoidCallback? onFriendsChanged;

  const UserManagementBar({super.key, this.onFriendsChanged});

  Future<void> _showOwnQrCode(BuildContext context) async {
    final userId = await SimpleUserIdentityService.getCurrentUserId();
    if (userId != null && context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => QrCodeDisplayDialog(userId: userId),
      );
    }
  }

  Future<void> _showAddFriendOptions(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Friend hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('QR-Code scannen'),
              onTap: () => Navigator.pop(context, 'qr'),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('ID manuell eingeben'),
              onTap: () => Navigator.pop(context, 'manual'),
            ),
          ],
        ),
      ),
    );

    if (result == 'qr' && context.mounted) {
      await _scanQrCode(context);
    } else if (result == 'manual' && context.mounted) {
      await _showManualAddDialog(context);
    }
  }

  Future<void> _scanQrCode(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const QrScannerDialog(),
    );

    if (result != null && context.mounted) {
      try {
        await FriendService.addFriend(
          result['userId']!,
          result['name']!,
          result['messenger'],
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result['name']} wurde hinzugefügt'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showManualAddDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddFriendDialog(),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend hinzugefügt'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openFriendsManagement(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FriendsPage()),
    );

    // Trigger reload after returning from Friends page
    onFriendsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Eigene ID/QR-Code anzeigen
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showOwnQrCode(context),
              icon: const Icon(Icons.qr_code, size: 18),
              label: const Text('Meine ID', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Nutzer hinzufügen
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showAddFriendOptions(context),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Hinzufügen', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Nutzer verwalten
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openFriendsManagement(context),
              icon: const Icon(Icons.people, size: 18),
              label: const Text('Verwalten', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
