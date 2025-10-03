import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../../../sharing/presentation/services/simple_user_identity_service.dart';
import '../../../sharing/presentation/mixins/friend_connection_mixin.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with FriendConnectionMixin {
  bool _notificationsExpanded = false;
  bool _userIdExpanded = false;

  @override
  void onConnectionAccepted() {
    // No specific action needed in settings page
    // The popup will show and handle the friend connection
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
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
