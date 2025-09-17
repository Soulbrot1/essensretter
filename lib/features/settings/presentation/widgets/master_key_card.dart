import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/local_key_service.dart';

/// Widget zur Anzeige des Master-Keys mit QR-Code
///
/// Coding-Prinzip: Separation of Concerns
/// Dieses Widget kümmert sich NUR um die Darstellung
class MasterKeyCard extends StatefulWidget {
  const MasterKeyCard({super.key});

  @override
  State<MasterKeyCard> createState() => _MasterKeyCardState();
}

class _MasterKeyCardState extends State<MasterKeyCard> {
  final _keyService = GetIt.instance<LocalKeyService>();
  bool _isKeyVisible = false;
  String? _masterKey;

  @override
  void initState() {
    super.initState();
    _loadMasterKey();
  }

  void _loadMasterKey() {
    _masterKey = _keyService.getMasterKey();
  }

  void _toggleKeyVisibility() {
    if (!_isKeyVisible) {
      // Zeige Warnung vor dem Anzeigen
      _showSecurityWarning();
    } else {
      setState(() {
        _isKeyVisible = false;
      });
    }
  }

  Future<void> _showSecurityWarning() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Sicherheitshinweis'),
          ],
        ),
        content: const Text(
          'Dieser Schlüssel ist wie ein Passwort für Ihre Lebensmitteldaten.\n\n'
          '• Teilen Sie ihn NICHT mit anderen Personen\n'
          '• Nutzen Sie für Haushaltsmitglieder die "Zugang erstellen" Funktion\n'
          '• Der QR-Code ist nur für Backup/Gerätewechsel gedacht\n\n'
          'Möchten Sie den Schlüssel wirklich anzeigen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Verstanden, anzeigen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isKeyVisible = true;
      });
    }
  }

  void _copyToClipboard() {
    if (_masterKey != null) {
      Clipboard.setData(ClipboardData(text: _masterKey!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schlüssel in Zwischenablage kopiert'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showQRCode() async {
    if (_masterKey == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Master-Key QR-Code'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: _masterKey!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ Nur für Backup/Gerätewechsel',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nicht zum Teilen mit anderen Personen!',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_masterKey == null) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Kein Master-Key gefunden')),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.key, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Ihr persönlicher Schlüssel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Key Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isKeyVisible ? _masterKey! : '••••-••••',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isKeyVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: _toggleKeyVisibility,
                    tooltip: _isKeyVisible ? 'Verbergen' : 'Anzeigen',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isKeyVisible ? _copyToClipboard : null,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Kopieren'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isKeyVisible ? _showQRCode : null,
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('QR-Code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info Text
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dieser Schlüssel wurde bei der ersten App-Nutzung '
                      'automatisch generiert und identifiziert Ihren Haushalt.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
