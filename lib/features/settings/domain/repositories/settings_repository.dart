import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, NotificationSettings>> getNotificationSettings();
  Future<Either<Failure, void>> saveNotificationSettings(
    NotificationSettings settings,
  );
}
