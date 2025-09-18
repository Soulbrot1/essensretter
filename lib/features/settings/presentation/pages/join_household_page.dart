import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/local_key_service.dart';

/// Seite zum Beitreten zu einem Haushalt via QR-Code
///
/// Coding-Prinzip: Single Responsibility
/// Diese Seite kümmert sich NUR um das Scannen und Beitreten
class JoinHouseholdPage extends StatefulWidget {
  const JoinHouseholdPage({super.key});

  @override
  State<JoinHouseholdPage> createState() => _JoinHouseholdPageState();
}

class _JoinHouseholdPageState extends State<JoinHouseholdPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final _keyService = GetIt.instance<LocalKeyService>();

  QRViewController? controller;
  bool _isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid && controller != null) {
      controller!.pauseCamera();
    } else if (Platform.isIOS && controller != null) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haushalt beitreten'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Anweisungen
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                const Text(
                  'QR-Code scannen',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scannen Sie den QR-Code, den Ihnen der Haushalt-Administrator gezeigt hat.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // QR Scanner
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.green,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            ),
          ),

          // Status und Aktionen
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_isProcessing)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 8),
                      Text('QR-Code wird verarbeitet...'),
                    ],
                  )
                else
                  const Text(
                    'Richten Sie die Kamera auf den QR-Code',
                    style: TextStyle(fontSize: 16),
                  ),

                const SizedBox(height: 16),

                // Manueller Eingabe Button
                OutlinedButton.icon(
                  onPressed: _showManualInput,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Code manuell eingeben'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        _processQRCode(scanData.code!);
      }
    });
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Pausiere die Kamera während der Verarbeitung
    await controller?.pauseCamera();

    try {
      // QR-Code Format: HOUSEHOLD_INVITE:MASTER_KEY:SUB_KEY
      if (qrData.startsWith('HOUSEHOLD_INVITE:')) {
        final parts = qrData.split(':');
        if (parts.length == 3) {
          final masterKey = parts[1];
          final subKey = parts[2];

          await _joinHousehold(masterKey, subKey);
        } else {
          _showError('Ungültiger QR-Code Format');
          // Resume camera on error
          await controller?.resumeCamera();
        }
      } else {
        _showError('Dies ist kein gültiger Haushalt-QR-Code');
        // Resume camera on error
        await controller?.resumeCamera();
      }
    } catch (e) {
      _showError('Fehler beim Verarbeiten: $e');
      // Resume camera on error
      await controller?.resumeCamera();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _joinHousehold(String masterKey, String subKey) async {
    try {
      // Prüfe ob bereits einem Haushalt beigetreten
      final currentMasterKey = _keyService.getMasterKey();
      if (currentMasterKey != null) {
        await _showAlreadyMemberDialog();
        return;
      }

      // Speichere Sub-Key Informationen lokal
      await _keyService.saveSubKey(subKey, ['read', 'write']);

      // Zeige Erfolg Dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Erfolgreich beigetreten!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sie sind dem Haushalt erfolgreich beigetreten.'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ihre Details:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Sub-Key: $subKey'),
                      Text('Haushalt: $masterKey'),
                      const Text('Berechtigung: Lesen & Schreiben'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dialog schließen
                  Navigator.of(context).pop(); // Zur Einstellungen zurück
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Fertig'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Fehler beim Beitreten: $e');
    }
  }

  Future<void> _showAlreadyMemberDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Bereits Mitglied'),
          ],
        ),
        content: const Text(
          'Sie sind bereits Mitglied in einem Haushalt. '
          'Sie können nur einem Haushalt gleichzeitig angehören.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _showManualInput() async {
    final TextEditingController codeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code manuell eingeben'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Geben Sie den kompletten Einladungscode ein:'),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                hintText: 'HOUSEHOLD_INVITE:APFEL-X7K9:SUB-12345678',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (codeController.text.isNotEmpty) {
                _processQRCode(codeController.text);
              }
            },
            child: const Text('Beitreten'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
