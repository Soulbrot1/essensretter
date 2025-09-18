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

  void _loadMasterKey() async {
    // Prüfe ob Service bereits registriert ist
    if (!GetIt.instance.isRegistered<LocalKeyService>()) {
      // Falls nicht, erstelle einen neuen Service
      final service = await LocalKeyService.create();
      GetIt.instance.registerSingleton<LocalKeyService>(service);
      _masterKey = service.getMasterKey();

      // Falls kein Key existiert, initialisiere einen
      if (_masterKey == null) {
        _masterKey = await service.initializeMasterKey();
      }
    } else {
      // Nur anzeigen wenn man im eigenen Haushalt ist
      if (_keyService.isOwnHouseholdActive()) {
        _masterKey = _keyService.getMasterKey();
      } else {
        _masterKey = null; // Verstecke Master Key wenn in fremdem Haushalt
      }
    }

    if (mounted) {
      setState(() {});
    }
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

    // Generiere neuen Sub-Key für den Einzuladenden
    final newSubKey = _keyService.generateSubKey();
    final inviteCode = 'HOUSEHOLD_INVITE:$_masterKey:$newSubKey';

    // Speichere den Sub-Key bereits für die Einladung
    await _keyService.saveSubKey(newSubKey, ['read', 'write']);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Haushalt-Einladung QR-Code'),
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
                    data: inviteCode,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '👥 Haushalt-Einladung',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dieser QR-Code lädt eine Person zu Ihrem Haushalt ein.\n\nSub-Key: $newSubKey',
                style: const TextStyle(fontSize: 12),
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

  Future<void> _showSubKeyManagement() async {
    final subKeys = _keyService.getSubKeys();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Haushalt verwalten'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sub-Key erstellen Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createSubKey,
                  icon: const Icon(Icons.add),
                  label: const Text('Familienmitglied einladen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sub-Keys Liste
              if (subKeys.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Aktive Familienmitglieder:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...subKeys.map(
                  (subKey) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.green),
                      title: Text(subKey.key),
                      subtitle: Text(
                        'Erstellt: ${subKey.createdAt.day}.${subKey.createdAt.month}.${subKey.createdAt.year}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _revokeSubKey(subKey.key),
                      ),
                    ),
                  ),
                ),
              ] else
                const Text(
                  'Noch keine Familienmitglieder eingeladen.',
                  style: TextStyle(color: Colors.grey),
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

  Future<void> _createSubKey() async {
    try {
      final subKey = _keyService.generateSubKey();
      await _keyService.saveSubKey(subKey, ['read', 'write']);

      if (!mounted) return;

      // QR-Code für Sub-Key generieren
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Familienmitglied einladen'),
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
                      data: 'HOUSEHOLD_INVITE:$_masterKey:$subKey',
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sub-Key: $subKey',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Familienmitglied kann diesen QR-Code scannen',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: subKey));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sub-Key kopiert')),
                );
              },
              child: const Text('Kopieren'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Schließen'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  Future<void> _revokeSubKey(String subKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zugang entziehen'),
        content: Text('Möchten Sie den Zugang für $subKey wirklich entziehen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Entziehen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _keyService.revokeSubKey(subKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Zugang entzogen' : 'Fehler beim Entziehen',
            ),
          ),
        );
        // Dialog neu öffnen um aktualisierte Liste zu zeigen
        Navigator.of(context).pop();
        _showSubKeyManagement();
      }
    }
  }

  Widget _buildSubKeyCard(String subKey) {
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
                Icon(Icons.group, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Haushaltsmitglied',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sub-Key Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ihr Sub-Key:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subKey,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
                      'Sie sind Mitglied in einem Haushalt. Der Haushalt-Administrator '
                      'kann Ihren Zugang verwalten.',
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

  @override
  Widget build(BuildContext context) {
    // Wenn in fremdem Haushalt, zeige Sub-Key Info
    if (_keyService.isInForeignHousehold()) {
      final subKey = _keyService.getOwnSubKey();
      if (subKey != null) {
        return _buildSubKeyCard(subKey);
      }
    }

    // Wenn im eigenen Haushalt und Sub-Key User
    if (_keyService.isSubKeyUser()) {
      final subKey = _keyService.getOwnSubKey();
      return _buildSubKeyCard(subKey!);
    }

    // Nur Master Key anzeigen wenn im eigenen Haushalt
    if (_masterKey == null || !_keyService.isOwnHouseholdActive()) {
      return const SizedBox.shrink(); // Verstecke komplett wenn in fremdem Haushalt
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
            const SizedBox(height: 8),

            // Sub-Key Management Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showSubKeyManagement,
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text('Haushalt verwalten'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: BorderSide(color: Colors.green.shade300),
                ),
              ),
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
