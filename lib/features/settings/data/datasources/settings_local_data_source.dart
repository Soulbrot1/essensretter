import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_settings_model.dart';

abstract class SettingsLocalDataSource {
  Future<NotificationSettingsModel> getNotificationSettings();
  Future<void> saveNotificationSettings(NotificationSettingsModel settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences sharedPreferences;

  SettingsLocalDataSourceImpl({required this.sharedPreferences});

  static const _notificationEnabledKey = 'notification_enabled';
  static const _notificationHourKey = 'notification_hour';
  static const _notificationMinuteKey = 'notification_minute';

  @override
  Future<NotificationSettingsModel> getNotificationSettings() async {
    final isEnabled = sharedPreferences.getBool(_notificationEnabledKey) ?? false;
    final hour = sharedPreferences.getInt(_notificationHourKey) ?? 9;
    final minute = sharedPreferences.getInt(_notificationMinuteKey) ?? 0;

    return NotificationSettingsModel.fromJson({
      'isEnabled': isEnabled,
      'notificationHour': hour,
      'notificationMinute': minute,
    });
  }

  @override
  Future<void> saveNotificationSettings(NotificationSettingsModel settings) async {
    await sharedPreferences.setBool(_notificationEnabledKey, settings.isEnabled);
    await sharedPreferences.setInt(_notificationHourKey, settings.notificationTime.hour);
    await sharedPreferences.setInt(_notificationMinuteKey, settings.notificationTime.minute);
  }
}