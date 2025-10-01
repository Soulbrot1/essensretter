import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/friend_service.dart';

class AddFriendDialog extends StatefulWidget {
  const AddFriendDialog({super.key});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _codeValidated = false;
  String? _validatedCode;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _validateAndAddFriend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _codeController.text.trim().toUpperCase();

      // Schritt 1: Code validieren
      if (!_codeValidated) {
        if (!FriendService.isValidUserId(code)) {
          throw Exception('Ungültiges Code-Format. Erwarte: ER-XXXXXXXX');
        }

        // Optional: Prüfe ob User existiert
        // final exists = await FriendService.userExists(code);
        // if (!exists) {
        //   throw Exception('Dieser Code existiert nicht');
        // }

        setState(() {
          _codeValidated = true;
          _validatedCode = code;
        });
        return;
      }

      // Schritt 2: Friend mit Namen hinzufügen
      final friendName = _nameController.text.trim();
      if (friendName.isEmpty) {
        throw Exception('Bitte gib einen Namen ein');
      }

      await FriendService.addFriend(_validatedCode!, friendName);

      if (!mounted) return;

      // Erfolgreich - Dialog schließen und true zurückgeben
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$friendName wurde erfolgreich hinzugefügt'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetDialog() {
    setState(() {
      _codeValidated = false;
      _validatedCode = null;
      _codeController.clear();
      _nameController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_add, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Friend hinzufügen'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_codeValidated) ...[
              const Text(
                'Gib den Zugangscode deines Friends ein:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Zugangscode',
                  hintText: 'ER-XXXXXXXX',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.05),
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
                  LengthLimitingTextInputFormatter(11), // ER-XXXXXXXX
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte Code eingeben';
                  }
                  if (!FriendService.isValidUserId(value.toUpperCase())) {
                    return 'Ungültiges Format (ER-XXXXXXXX)';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _validateAndAddFriend(),
              ),
            ] else ...[
              // Code wurde validiert, jetzt Namen eingeben
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Code validiert:',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                          Text(
                            _validatedCode!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: _resetDialog,
                      tooltip: 'Code ändern',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gib diesem Friend einen Namen:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'z.B. Anna, Max, Mama...',
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
                onFieldSubmitted: (_) => _validateAndAddFriend(),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _validateAndAddFriend,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_codeValidated ? 'Hinzufügen' : 'Weiter'),
        ),
      ],
    );
  }
}
