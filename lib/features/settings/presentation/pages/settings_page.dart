import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../../../sharing/presentation/services/simple_user_identity_service.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../backup/presentation/services/snapshot_backup_service.dart';
import '../../../../injection_container.dart' as di;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsExpanded = false;
  bool _userIdExpanded = false;
  bool _backupExpanded = false;
  bool _isBackupInProgress = false;
  String? _lastBackupResult;

  Future<void> _triggerManualBackup() async {
    setState(() {
      _isBackupInProgress = true;
      _lastBackupResult = null;
    });

    try {
      final backupService = di.sl<SnapshotBackupService>();
      final success = await backupService.createBackup();

      if (!mounted) return;

      setState(() {
        _isBackupInProgress = false;
        _lastBackupResult = success
            ? 'Backup erfolgreich erstellt!'
            : 'Backup übersprungen (keine Änderungen)';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lastBackupResult!),
          backgroundColor: success ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isBackupInProgress = false;
        _lastBackupResult = 'Fehler: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup fehlgeschlagen: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading || state is SettingsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Fehler: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SettingsBloc>().add(
                        LoadNotificationSettings(),
                      );
                    },
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            );
          }

          if (state is SettingsLoaded) {
            return ListView(
              children: [
                // Benachrichtigungen - Collapsible
                ListTile(
                  title: const Text(
                    'Benachrichtigungen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      _notificationsExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() {
                        _notificationsExpanded = !_notificationsExpanded;
                      });
                    },
                  ),
                ),
                if (_notificationsExpanded) ...[
                  SwitchListTile(
                    title: const Text('Tägliche Erinnerungen'),
                    subtitle: const Text(
                      'Erhalte täglich eine Benachrichtigung über ablaufende Lebensmittel',
                    ),
                    value: state.notificationSettings.isEnabled,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(
                        UpdateNotificationEnabled(value),
                      );
                    },
                  ),
                  if (state.notificationSettings.isEnabled) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('Benachrichtigungszeit'),
                      subtitle: Text(
                        state.notificationSettings.notificationTime.format(
                          context,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime:
                              state.notificationSettings.notificationTime,
                        );

                        if (selectedTime != null && context.mounted) {
                          context.read<SettingsBloc>().add(
                            UpdateNotificationTime(selectedTime),
                          );
                        }
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Was wird benachrichtigt?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• Bereits abgelaufene Lebensmittel\n'
                                '• Lebensmittel die heute ablaufen\n'
                                '• Lebensmittel die in den nächsten 2 Tagen ablaufen',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                const Divider(height: 32),

                // Benutzer-Identifikation - Collapsible
                ListTile(
                  title: const Text(
                    'Benutzer-Identifikation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      _userIdExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() {
                        _userIdExpanded = !_userIdExpanded;
                      });
                    },
                  ),
                ),
                if (_userIdExpanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ihre Benutzer-ID',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<String?>(
                              future:
                                  SimpleUserIdentityService.getCurrentUserId(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Lade User-ID...'),
                                    ],
                                  );
                                }

                                final userId =
                                    snapshot.data ?? 'Nicht verfügbar';

                                return Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        userId,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      onPressed: userId != 'Nicht verfügbar'
                                          ? () {
                                              Clipboard.setData(
                                                ClipboardData(text: userId),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'User-ID kopiert!',
                                                  ),
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                      tooltip: 'Kopieren',
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Diese ID wird für das Teilen von Lebensmitteln verwendet.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 32),

                // Statistiken - Öffnet als Modal Bottom Sheet
                ListTile(
                  title: const Text(
                    'Lebensmittel-Statistiken',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Verschwendungsstatistiken und Trends anzeigen',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.9,
                        minChildSize: 0.5,
                        maxChildSize: 0.95,
                        builder: (context, scrollController) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: const StatisticsPage(),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 32),

                // Backup & Wiederherstellung - Collapsible
                ListTile(
                  title: const Text(
                    'Backup & Wiederherstellung',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      _backupExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() {
                        _backupExpanded = !_backupExpanded;
                      });
                    },
                  ),
                ),
                if (_backupExpanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Info über automatisches Backup
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
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Automatisches Backup ist aktiv. Deine Daten werden gesichert, wenn die App in den Hintergrund geht.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Manueller Backup-Button
                            ElevatedButton.icon(
                              onPressed: _isBackupInProgress
                                  ? null
                                  : _triggerManualBackup,
                              icon: _isBackupInProgress
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload),
                              label: Text(
                                _isBackupInProgress
                                    ? 'Backup läuft...'
                                    : 'Manuelles Backup erstellen',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),

                            // Letztes Backup-Ergebnis
                            if (_lastBackupResult != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _lastBackupResult!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      _lastBackupResult!.contains('erfolgreich')
                                      ? Colors.green[700]
                                      : _lastBackupResult!.contains(
                                          'übersprungen',
                                        )
                                      ? Colors.orange[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Backup-Status-Info
                            FutureBuilder<bool>(
                              future: di
                                  .sl<SnapshotBackupService>()
                                  .hasBackup(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Prüfe Backup-Status...',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  );
                                }

                                final hasBackup = snapshot.data ?? false;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      hasBackup
                                          ? Icons.check_circle
                                          : Icons.cloud_off,
                                      size: 16,
                                      color: hasBackup
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      hasBackup
                                          ? 'Cloud-Backup vorhanden'
                                          : 'Noch kein Cloud-Backup',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            // Erklärung
                            Text(
                              'Was wird gesichert?\n'
                              '• Alle Lebensmittel\n'
                              '• Freunde und Verbindungen\n'
                              '• Lokale Einstellungen',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
