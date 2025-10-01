import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/friend_service.dart';
import '../widgets/add_friend_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final friends = await FriendService.getFriends();

      // Check for new friends without names
      final newFriendsCount = friends.where((f) => f.friendName == null).length;
      if (newFriendsCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$newFriendsCount neue${newFriendsCount > 1 ? ' Friends haben' : 'r Friend hat'} dich hinzugefügt! Bitte Namen vergeben.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }

      setState(() {
        _friends = friends;
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
      _loadFriends(); // Reload friends list
    }
  }

  Future<void> _removeFriend(FriendConnection friend) async {
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

    if (confirmed == true) {
      try {
        await FriendService.removeFriend(friend.friendId);
        _loadFriends();
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

    if (newName != null && newName.isNotEmpty && newName != friend.friendName) {
      try {
        await FriendService.updateFriendName(friend.friendId, newName);
        _loadFriends();
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
          IconButton(
            onPressed: _showAddFriendDialog,
            icon: const Icon(Icons.person_add),
            tooltip: 'Friend hinzufügen',
          ),
        ],
      ),
      body: Column(
        children: [
          // Your User-ID Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Deine User-ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<String?>(
                  future: SimpleUserIdentityService.getCurrentUserId(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Lade User-ID...'),
                        ],
                      );
                    }

                    final userId = snapshot.data ?? 'Nicht verfügbar';
                    return Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            userId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: userId != 'Nicht verfügbar'
                              ? _copyUserId
                              : null,
                          icon: const Icon(Icons.copy),
                          tooltip: 'Kopieren',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Teile diese ID mit anderen, damit sie dich als Friend hinzufügen können.',
                  style: TextStyle(fontSize: 12, color: Colors.green[600]),
                ),
              ],
            ),
          ),

          // Friends List Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text('Fehler: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFriends,
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  )
                : _friends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Noch keine Friends',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Füge Friends hinzu, um ihre Lebensmittel zu sehen',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddFriendDialog,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Ersten Friend hinzufügen'),
                        ),
                      ],
                    ),
                  )
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
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$unnamedCount neue${unnamedCount > 1 ? ' Friends' : 'r Friend'} ohne Namen! Tippe auf "Namen ändern" im Menü.',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Adjust index for actual friends list
                        final friendIndex =
                            _friends.any((f) => f.friendName == null) &&
                                index > 0
                            ? index - 1
                            : index;

                        if (friendIndex >= _friends.length)
                          return const SizedBox.shrink();

                        final friend = _friends[friendIndex];
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (friend.friendName == null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
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
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'rename':
                                    _updateFriendName(friend);
                                    break;
                                  case 'remove':
                                    _removeFriend(friend);
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
                                  value: 'remove',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_remove,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Entfernen',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
