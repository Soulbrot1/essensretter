import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/friend_service.dart';
import '../services/local_friend_messenger_service.dart';
import '../widgets/add_friend_dialog.dart';
import '../widgets/qr_code_display_dialog.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/friend_card_widget.dart';
import '../widgets/user_id_section_widget.dart';
import '../widgets/friends_empty_state_widget.dart';
import '../widgets/friends_error_widget.dart';
import '../widgets/unnamed_friends_banner_widget.dart';
import '../helpers/friends_dialog_helpers.dart';
import '../services/simple_user_identity_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<FriendConnection> _friends = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;
  int _lastFriendCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Startet automatisches Polling alle 3 Sekunden
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _checkForNewFriends();
      }
    });
  }

  /// Prüft ob neue Friends hinzugekommen sind (ohne UI zu blockieren)
  Future<void> _checkForNewFriends() async {
    try {
      final friends = await FriendService.getFriends();

      // Nur updaten wenn sich die Anzahl geändert hat
      if (friends.length != _lastFriendCount && mounted) {
        _lastFriendCount = friends.length;

        // Aktualisiere Liste
        setState(() {
          _friends = friends;
        });

        // Zeige Snackbar wenn neue Friends da sind
        final newFriendsCount = friends
            .where((f) => f.friendName == null)
            .length;
        if (newFriendsCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$newFriendsCount neue${newFriendsCount > 1 ? ' Friends haben' : 'r Friend hat'} dich hinzugefügt!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Fehler beim Polling - nicht kritisch
    }
  }

  Future<void> _loadFriends() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final friends = await FriendService.getFriends();

      setState(() {
        _friends = friends;
        _lastFriendCount = friends.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddFriendDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddFriendDialog(),
    );

    if (result == true) {
      await _loadFriends(); // Reload friends list
    }
  }

  Future<void> _removeFriend(FriendConnection friend) async {
    final confirmed = await FriendsDialogHelpers.showRemoveFriendDialog(
      context,
      friend,
    );

    if (confirmed) {
      try {
        await FriendService.removeFriend(friend.friendId);
        await _loadFriends();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${friend.friendName ?? friend.friendId} wurde entfernt',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Entfernen: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateFriendName(FriendConnection friend) async {
    final newName = await FriendsDialogHelpers.showUpdateNameDialog(
      context,
      friend,
    );

    if (newName != null) {
      try {
        await FriendService.updateFriendName(friend.friendId, newName);
        await _loadFriends();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Name zu "$newName" geändert'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Ändern: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateFriendMessenger(FriendConnection friend) async {
    final newMessenger = await FriendsDialogHelpers.showUpdateMessengerDialog(
      context,
      friend,
    );

    if (newMessenger != null) {
      try {
        await LocalFriendMessengerService.setFriendMessenger(
          friend.friendId,
          newMessenger,
        );
        await _loadFriends();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Messenger zu "${newMessenger.displayName}" geändert',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Ändern: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showQrCode(String userId) async {
    await showDialog(
      context: context,
      builder: (context) => QrCodeDisplayDialog(userId: userId),
    );
  }

  Future<void> _showQrScanner() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const QrScannerDialog(),
    );

    if (result != null && mounted) {
      try {
        await FriendService.addFriend(
          result['userId']!,
          result['name']!,
          result['messenger'],
        );
        await _loadFriends();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result['name']} wurde hinzugefügt'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _copyUserId() async {
    try {
      final userId = await SimpleUserIdentityService.getCurrentUserId();
      if (userId != null) {
        await Clipboard.setData(ClipboardData(text: userId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deine User-ID wurde kopiert!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_add),
            tooltip: 'Friend hinzufügen',
            onSelected: (value) {
              if (value == 'qr') {
                _showQrScanner();
              } else if (value == 'manual') {
                _showAddFriendDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 20),
                    SizedBox(width: 12),
                    Text('QR-Code scannen'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'manual',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('ID eingeben'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Your User-ID Section
          UserIdSectionWidget(
            onShowQrCode: _showQrCode,
            onCopyUserId: _copyUserId,
          ),

          // Friends List Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? FriendsErrorWidget(error: _error!, onRetry: _loadFriends)
                : _friends.isEmpty
                ? FriendsEmptyStateWidget(onAddFriend: _showAddFriendDialog)
                : RefreshIndicator(
                    onRefresh: _loadFriends,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount:
                          _friends.length +
                          (_friends.any((f) => f.friendName == null) ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show banner at top if there are unnamed friends
                        if (index == 0 &&
                            _friends.any((f) => f.friendName == null)) {
                          final unnamedCount = _friends
                              .where((f) => f.friendName == null)
                              .length;
                          return UnnamedFriendsBannerWidget(
                            unnamedCount: unnamedCount,
                          );
                        }

                        // Adjust index for actual friends list
                        final friendIndex =
                            _friends.any((f) => f.friendName == null) &&
                                index > 0
                            ? index - 1
                            : index;

                        if (friendIndex >= _friends.length) {
                          return const SizedBox.shrink();
                        }

                        final friend = _friends[friendIndex];
                        return FriendCardWidget(
                          friend: friend,
                          onRename: () => _updateFriendName(friend),
                          onChangeMessenger: () =>
                              _updateFriendMessenger(friend),
                          onRemove: () => _removeFriend(friend),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
