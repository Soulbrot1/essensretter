import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/friend_service.dart';
import '../services/messenger_type.dart';

class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({super.key});

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScannedCode(String? code) async {
    if (code == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Validiere User-ID Format
    if (!FriendService.isValidUserId(code)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ungültiger QR-Code'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    // Prüfe ob Verbindung bereits besteht
    try {
      final friends = await FriendService.getFriends();
      final alreadyConnected = friends.any((f) => f.friendId == code);

      if (alreadyConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dieser Friend ist bereits hinzugefügt'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler bei der Überprüfung: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    // Zeige Name-Eingabe und Messenger-Auswahl Dialog
    if (mounted) {
      final result = await _showNameInputDialog(code);
      if (result != null && mounted) {
        Navigator.of(context).pop({
          'userId': code,
          'name': result['name'],
          'messenger': result['messenger'],
        });
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _showNameInputDialog(String userId) async {
    final controller = TextEditingController();
    MessengerType selectedMessenger = MessengerType.whatsapp;
    bool nameEntered = false;
    String? enteredName;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Friend benennen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User-ID: $userId',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              if (!nameEntered) ...[
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Wie soll dieser Friend heißen?',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() {
                        nameEntered = true;
                        enteredName = value.trim();
                      });
                    }
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          enteredName!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          setState(() {
                            nameEntered = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bevorzugter Messenger:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
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
                            Icon(messenger.icon, size: 18),
                            const SizedBox(width: 8),
                            Text(messenger.displayName),
                          ],
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (!nameEntered) {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    setState(() {
                      nameEntered = true;
                      enteredName = name;
                    });
                  }
                } else {
                  Navigator.of(
                    context,
                  ).pop({'name': enteredName, 'messenger': selectedMessenger});
                }
              },
              child: Text(nameEntered ? 'Hinzufügen' : 'Weiter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('QR-Code scannen'),
            actions: [
              IconButton(
                icon: const Icon(Icons.flash_on),
                onPressed: () => _controller.toggleTorch(),
              ),
              IconButton(
                icon: const Icon(Icons.flip_camera_ios),
                onPressed: () => _controller.switchCamera(),
              ),
            ],
          ),
          SizedBox(
            height: 400,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      _handleScannedCode(barcode.rawValue);
                    }
                  },
                ),
                if (_isProcessing)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                // Scan-Rahmen
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: const Text(
              'Richte die Kamera auf einen QR-Code',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
