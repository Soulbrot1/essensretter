import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/usecases/get_notification_settings.dart';
import '../../domain/usecases/save_notification_settings.dart';
import '../../../notification/domain/usecases/schedule_daily_notification.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetNotificationSettings getNotificationSettings;
  final SaveNotificationSettings saveNotificationSettings;
  final ScheduleDailyNotification scheduleDailyNotification;

  SettingsBloc({
    required this.getNotificationSettings,
    required this.saveNotificationSettings,
    required this.scheduleDailyNotification,
  }) : super(SettingsInitial()) {
    on<LoadNotificationSettings>(_onLoadNotificationSettings);
    on<UpdateNotificationEnabled>(_onUpdateNotificationEnabled);
    on<UpdateNotificationTime>(_onUpdateNotificationTime);
  }

  Future<void> _onLoadNotificationSettings(
    LoadNotificationSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    final result = await getNotificationSettings(NoParams());

    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (settings) => emit(SettingsLoaded(settings)),
    );
  }

  Future<void> _onUpdateNotificationEnabled(
    UpdateNotificationEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).notificationSettings;
      final newSettings = currentSettings.copyWith(isEnabled: event.isEnabled);

      emit(SettingsLoading());

      final saveResult = await saveNotificationSettings(
        SaveNotificationSettingsParams(settings: newSettings),
      );

      await saveResult.fold(
        (failure) async => emit(SettingsError(failure.message)),
        (_) async {
          // Nach dem Speichern die Benachrichtigung neu planen
          await scheduleDailyNotification(NoParams());
          emit(SettingsLoaded(newSettings));
        },
      );
    }
  }

  Future<void> _onUpdateNotificationTime(
    UpdateNotificationTime event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).notificationSettings;
      final newSettings = currentSettings.copyWith(
        notificationTime: event.time,
      );

      emit(SettingsLoading());

      final saveResult = await saveNotificationSettings(
        SaveNotificationSettingsParams(settings: newSettings),
      );

      await saveResult.fold(
        (failure) async => emit(SettingsError(failure.message)),
        (_) async {
          // Nach dem Speichern die Benachrichtigung neu planen
          await scheduleDailyNotification(NoParams());
          emit(SettingsLoaded(newSettings));
        },
      );
    }
  }
}
