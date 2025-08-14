import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification_settings.dart';
import '../repositories/settings_repository.dart';

class SaveNotificationSettings
    implements UseCase<void, SaveNotificationSettingsParams> {
  final SettingsRepository repository;

  SaveNotificationSettings(this.repository);

  @override
  Future<Either<Failure, void>> call(
    SaveNotificationSettingsParams params,
  ) async {
    return await repository.saveNotificationSettings(params.settings);
  }
}

class SaveNotificationSettingsParams extends Equatable {
  final NotificationSettings settings;

  const SaveNotificationSettingsParams({required this.settings});

  @override
  List<Object> get props => [settings];
}
