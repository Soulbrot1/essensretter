import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class NotificationSettings extends Equatable {
  final bool isEnabled;
  final TimeOfDay notificationTime;

  const NotificationSettings({
    required this.isEnabled,
    required this.notificationTime,
  });

  NotificationSettings copyWith({
    bool? isEnabled,
    TimeOfDay? notificationTime,
  }) {
    return NotificationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }

  @override
  List<Object> get props => [isEnabled, notificationTime];
}