import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/local_key_service.dart';

/// Seite zur Verwaltung des aktuellen Haushalts
class HouseholdManagementPage extends StatefulWidget {
  const HouseholdManagementPage({super.key});

  @override
  State<HouseholdManagementPage> createState() =>
      _HouseholdManagementPageState();
}

class _HouseholdManagementPageState extends State<HouseholdManagementPage> {
  final _keyService = GetIt.instance<LocalKeyService>();
  HouseholdInfo? _currentHousehold;
  bool _isInForeignHousehold = false;

  @override
  void initState() {
    super.initState();
    _loadHouseholdInfo();
  }

  void _loadHouseholdInfo() {
    setState(() {
      _currentHousehold = _keyService.getCurrentHousehold();
      _isInForeignHousehold = _keyService.isInForeignHousehold();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haushalt-Status'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _currentHousehold == null
          ? const Center(child: Text('Kein Haushalt vorhanden'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCurrentHouseholdCard(),
                const SizedBox(height: 20),
                if (_isInForeignHousehold) _buildLeaveButton(),
                const SizedBox(height: 20),
                _buildInfoCard(),
              ],
            ),
    );
  }

  Widget _buildCurrentHouseholdCard() {
    if (_currentHousehold == null) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _currentHousehold!.isOwn ? Colors.green : Colors.blue,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _currentHousehold!.isOwn ? Icons.home : Icons.group,
                  color: _currentHousehold!.isOwn ? Colors.green : Colors.blue,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentHousehold!.isOwn
                            ? 'Mein Haushalt'
                            : 'Fremder Haushalt',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentHousehold!.isOwn
                            ? 'Sie sind der Besitzer dieses Haushalts'
                            : 'Sie sind Mitglied in diesem Haushalt',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.key,
              _currentHousehold!.isOwn ? 'Master Key' : 'Sub-Key',
              _currentHousehold!.isOwn
                  ? _currentHousehold!.masterKey
                  : _currentHousehold!.subKey ?? 'N/A',
            ),
            const SizedBox(height: 8),
            if (!_currentHousehold!.isOwn)
              _buildDetailRow(
                Icons.vpn_key,
                'Haushalt-ID',
                '****-****', // Verstecke Master Key des fremden Haushalts
              ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.calendar_today,
              _currentHousehold!.isOwn ? 'Erstellt am' : 'Beigetreten am',
              _formatDate(_currentHousehold!.joinedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveButton() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Fremder Haushalt',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Sie sind momentan in einem fremden Haushalt. '
              'Um zu Ihrem eigenen Haushalt zurückzukehren, müssen Sie diesen verlassen.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _leaveForeignHousehold();
                },
                icon: const Icon(Icons.exit_to_app),
                label: const Text(
                  'Haushalt verlassen & zu eigenem zurückkehren',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Wie funktioniert das?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isInForeignHousehold
                  ? '• Sie sind momentan in einem fremden Haushalt\n'
                        '• Ihre eigenen Daten sind pausiert\n'
                        '• Wenn Sie diesen Haushalt verlassen, kehren Sie zu Ihrem eigenen zurück\n'
                        '• Alle Ihre eigenen Lebensmittel-Daten bleiben erhalten'
                  : '• Dies ist Ihr eigener Haushalt\n'
                        '• Sie können anderen erlauben, beizutreten\n'
                        '• Wenn Sie einem fremden Haushalt beitreten, wird dieser pausiert\n'
                        '• Sie können jederzeit zurückkehren',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _leaveForeignHousehold() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Haushalt verlassen'),
        content: const Text(
          'Möchten Sie diesen fremden Haushalt wirklich verlassen?\n\n'
          'Sie kehren zu Ihrem eigenen Haushalt zurück und verlieren den Zugriff auf die Daten des fremden Haushalts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verlassen & zurückkehren'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _keyService.leaveForeignHousehold();
        _loadHouseholdInfo();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zu eigenem Haushalt zurückgekehrt'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Verlassen: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
