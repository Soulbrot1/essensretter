import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Benachrichtigungen',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
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
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Hilfe & Demo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
