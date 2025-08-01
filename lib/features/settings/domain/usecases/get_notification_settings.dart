import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification_settings.dart';
import '../repositories/settings_repository.dart';

class GetNotificationSettings implements UseCase<NotificationSettings, NoParams> {
  final SettingsRepository repository;

  GetNotificationSettings(this.repository);

  @override
  Future<Either<Failure, NotificationSettings>> call(NoParams params) async {
    return await repository.getNotificationSettings();
  }
}