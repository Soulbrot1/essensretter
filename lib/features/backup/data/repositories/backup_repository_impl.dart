import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/backup_snapshot.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/backup_remote_data_source.dart';
import '../models/backup_snapshot_model.dart';
import '../../../../core/utils/app_logger.dart';

/// Implementation of BackupRepository
///
/// Handles error wrapping and conversion between entities and models
class BackupRepositoryImpl implements BackupRepository {
  final BackupRemoteDataSource remoteDataSource;

  BackupRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, BackupSnapshot>> saveBackup(
    BackupSnapshot snapshot,
  ) async {
    try {
      final model = BackupSnapshotModel.fromEntity(snapshot);
      final result = await remoteDataSource.saveBackup(model);
      return Right(result.toEntity());
    } catch (e) {
      AppLogger.error('Repository: Failed to save backup', error: e);
      return Left(ServerFailure('Failed to save backup: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BackupSnapshot?>> getBackup(String userId) async {
    try {
      final result = await remoteDataSource.getBackup(userId);
      return Right(result?.toEntity());
    } catch (e) {
      AppLogger.error('Repository: Failed to get backup', error: e);
      return Left(ServerFailure('Failed to get backup: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBackup(String userId) async {
    try {
      await remoteDataSource.deleteBackup(userId);
      return const Right(null);
    } catch (e) {
      AppLogger.error('Repository: Failed to delete backup', error: e);
      return Left(ServerFailure('Failed to delete backup: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasBackup(String userId) async {
    try {
      final result = await remoteDataSource.hasBackup(userId);
      return Right(result);
    } catch (e) {
      AppLogger.error('Repository: Failed to check backup', error: e);
      return Left(ServerFailure('Failed to check backup: ${e.toString()}'));
    }
  }
}
