import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';
import '../models/notification_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, NotificationSettings>> getNotificationSettings() async {
    try {
      final settings = await localDataSource.getNotificationSettings();
      return Right(settings);
    } on CacheException {
      return Left(CacheFailure('Failed to load notification settings'));
    }
  }

  @override
  Future<Either<Failure, void>> saveNotificationSettings(NotificationSettings settings) async {
    try {
      final settingsModel = NotificationSettingsModel.fromEntity(settings);
      await localDataSource.saveNotificationSettings(settingsModel);
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure('Failed to save notification settings'));
    }
  }
}