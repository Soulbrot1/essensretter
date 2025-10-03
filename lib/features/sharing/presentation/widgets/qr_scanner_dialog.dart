import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/friend_service.dart';

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

    // Zeige Name-Eingabe Dialog
    if (mounted) {
      final friendName = await _showNameInputDialog(code);
      if (friendName != null && mounted) {
        Navigator.of(context).pop({'userId': code, 'name': friendName});
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<String?> _showNameInputDialog(String userId) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Wie soll dieser Friend heißen?',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            child: const Text('Hinzufügen'),
          ),
        ],
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
