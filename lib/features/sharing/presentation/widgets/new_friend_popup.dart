import 'package:flutter/material.dart';
import '../services/friend_service.dart';

class NewFriendPopup extends StatefulWidget {
  final FriendConnection connection;
  final VoidCallback? onAccepted;
  final VoidCallback? onRejected;

  const NewFriendPopup({
    super.key,
    required this.connection,
    this.onAccepted,
    this.onRejected,
  });

  @override
  State<NewFriendPopup> createState() => _NewFriendPopupState();
}

class _NewFriendPopupState extends State<NewFriendPopup> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _acceptConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();

      // Update the friend's name
      await FriendService.updateFriendName(widget.connection.friendId, name);

      if (!mounted) return;

      Navigator.of(context).pop(true);
      widget.onAccepted?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name wurde als Friend hinzugefügt'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
      );

      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectConnection() async {
    setState(() => _isLoading = true);

    try {
      // Remove the friend connection
      await FriendService.removeFriend(widget.connection.friendId);

      if (!mounted) return;

      Navigator.of(context).pop(false);
      widget.onRejected?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verbindung abgelehnt'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Ablehnen: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Neue Friend-Anfrage', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info about new connection
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Neue Verbindung!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User-ID: ${widget.connection.friendId}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'hat sich mit dir verbunden!',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Name input field
            const Text(
              'Gib diesem Friend einen Namen:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'z.B. Max, Anna, Mama...',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte Namen eingeben';
                }
                if (value.trim().length < 2) {
                  return 'Name zu kurz';
                }
                if (value.trim().length > 30) {
                  return 'Name zu lang (max. 30 Zeichen)';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Info about sharing
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.share, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ihr könnt nun gegenseitig eure geteilten Lebensmittel sehen.',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _rejectConnection,
          child: Text('Ablehnen', style: TextStyle(color: Colors.red[600])),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _acceptConnection,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check, size: 18),
          label: const Text('Annehmen'),
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }
}
