import 'package:flutter/material.dart';
import '../../domain/entities/notification_settings.dart';

class NotificationSettingsModel extends NotificationSettings {
  const NotificationSettingsModel({
    required super.isEnabled,
    required super.notificationTime,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      isEnabled: json['isEnabled'] ?? false,
      notificationTime: TimeOfDay(
        hour: json['notificationHour'] ?? 9,
        minute: json['notificationMinute'] ?? 0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'notificationHour': notificationTime.hour,
      'notificationMinute': notificationTime.minute,
    };
  }

  factory NotificationSettingsModel.fromEntity(NotificationSettings entity) {
    return NotificationSettingsModel(
      isEnabled: entity.isEnabled,
      notificationTime: entity.notificationTime,
    );
  }
}
