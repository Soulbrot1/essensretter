part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadNotificationSettings extends SettingsEvent {}

class UpdateNotificationEnabled extends SettingsEvent {
  final bool isEnabled;

  const UpdateNotificationEnabled(this.isEnabled);

  @override
  List<Object> get props => [isEnabled];
}

class UpdateNotificationTime extends SettingsEvent {
  final TimeOfDay time;

  const UpdateNotificationTime(this.time);

  @override
  List<Object> get props => [time];
}