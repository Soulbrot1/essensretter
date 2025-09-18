import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../bloc/settings_bloc.dart';
import '../../../food_tracking/presentation/bloc/food_bloc.dart';
import '../../../food_tracking/presentation/bloc/food_event.dart';
import '../widgets/master_key_card.dart';
import 'join_household_page.dart';
import 'household_management_page.dart';
import '../../../../core/services/local_key_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
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
                    'Haushalt & Sicherheit',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const MasterKeyCard(),

                // Haushalt beitreten Button
                Card(
                  margin: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: const Icon(Icons.group_add, color: Colors.green),
                    title: const Text('Haushalt beitreten'),
                    subtitle: const Text(
                      'QR-Code scannen um einem Haushalt beizutreten',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const JoinHouseholdPage(),
                        ),
                      );
                    },
                  ),
                ),

                // Haushalt verwalten Button
                Card(
                  margin: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                    title: const Text('Haushalte verwalten'),
                    subtitle: const Text(
                      'Zwischen Haushalten wechseln oder verlassen',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HouseholdManagementPage(),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Hilfe & Demo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.green,
                  ),
                  title: const Text('Demo-Lebensmittel laden'),
                  subtitle: const Text('3 Beispiel-Lebensmittel hinzufügen'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.read<FoodBloc>().add(const LoadDemoFoodsEvent());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Demo-Lebensmittel werden geladen...'),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'App-Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_packageInfo != null)
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Version'),
                    subtitle: Text(
                      '${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('App-Name'),
                  subtitle: Text(_packageInfo?.appName ?? 'Essensretter'),
                ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Debug',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report, color: Colors.red),
                  title: const Text('Debug-Info anzeigen'),
                  subtitle: const Text('Zeigt gespeicherte Keys und Daten'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    final keyService = await LocalKeyService.create();
                    final debugInfo = keyService.debugInfo();

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Debug Info'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Eigener Master Key: ${debugInfo['ownMasterKey'] ?? 'NONE'}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Created At: ${debugInfo['createdAt'] ?? 'NONE'}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'In fremdem Haushalt: ${debugInfo['isInForeignHousehold']}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aktiver Haushalt: ${debugInfo['activeHousehold'] ?? 'NONE'}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sub Keys: ${(debugInfo['subKeys'] as List).length}',
                                ),
                                const SizedBox(height: 8),
                                const Text('All SharedPrefs Keys:'),
                                ...(debugInfo['allPrefsKeys'] as List).map(
                                  (key) => Text('  • $key'),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Schließen'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await keyService.deleteMasterKeyPermanently();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Master Key gelöscht! App neu starten.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Key löschen',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
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
