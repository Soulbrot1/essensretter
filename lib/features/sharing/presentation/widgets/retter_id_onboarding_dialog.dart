import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/simple_user_identity_service.dart';

/// Onboarding-Dialog für neue User zur Vorstellung der RetterId
///
/// Zeigt beim ersten App-Start die generierte RetterId und erklärt:
/// - Wofür die RetterId benötigt wird (Sharing, Restore)
/// - Dass automatisches Backup aktiv ist (iCloud/Google)
/// - Optionale externe Speicherung möglich ist
///
/// Ermöglicht:
/// - Native Share-Sheet zum Teilen der ID
/// - Kopieren der ID in Zwischenablage
class RetterIdOnboardingDialog extends StatefulWidget {
  const RetterIdOnboardingDialog({super.key});

  @override
  State<RetterIdOnboardingDialog> createState() =>
      _RetterIdOnboardingDialogState();
}

class _RetterIdOnboardingDialogState extends State<RetterIdOnboardingDialog> {
  String? _retterId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRetterId();
  }

  Future<void> _loadRetterId() async {
    try {
      final id = await SimpleUserIdentityService.ensureUserIdentity();
      setState(() {
        _retterId = id;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareRetterId() async {
    if (_retterId == null) return;

    try {
      await Share.share(
        'Meine EssensRetter-ID: $_retterId\n\n'
        'Füge mich als Friend hinzu um Lebensmittel zu teilen!',
        subject: 'Meine EssensRetter RetterId',
      );
    } catch (e) {
      // Fehler beim Teilen - ignorieren oder Snackbar zeigen
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teilen fehlgeschlagen'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    if (_retterId == null) return;

    await Clipboard.setData(ClipboardData(text: _retterId!));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('RetterId in Zwischenablage kopiert'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.celebration, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Deine RetterId wurde erstellt!',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // RetterId Display mit Copy-Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              color: Colors.green[700],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _retterId ?? 'Fehler beim Laden',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Kopieren'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            side: BorderSide(color: Colors.green[300]!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Erklärung: Wofür wird die ID gebraucht?
                  Text(
                    'Diese ID brauchst du um:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('🤝 Lebensmittel mit Freunden zu teilen'),
                  _buildBulletPoint(
                    '📱 Deine Daten auf neuen Geräten wiederherzustellen',
                  ),
                  const SizedBox(height: 16),

                  // Backup-Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.cloud_done,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Wird automatisch gesichert (iCloud/Google).',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Optionale externe Speicherung
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Du KANNST sie zusätzlich extern speichern - '
                            'z.B. wenn du kein iCloud/Google nutzt.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[900],
                            ),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Verstanden'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _shareRetterId,
          icon: const Icon(Icons.share),
          label: const Text('ID teilen'),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
