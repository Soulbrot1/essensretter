import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/backup_snapshot.dart';

/// Repository interface for backup operations
///
/// Abstracts the backup data source (Supabase) from the domain layer
abstract class BackupRepository {
  /// Creates or updates a backup snapshot
  ///
  /// Uses upsert logic - if backup for userId exists, it updates it;
  /// otherwise creates a new one
  Future<Either<Failure, BackupSnapshot>> saveBackup(BackupSnapshot snapshot);

  /// Retrieves the latest backup for a user
  ///
  /// Returns null if no backup exists for this userId
  Future<Either<Failure, BackupSnapshot?>> getBackup(String userId);

  /// Deletes the backup for a user
  ///
  /// Used during cleanup after successful restore
  Future<Either<Failure, void>> deleteBackup(String userId);

  /// Checks if a backup exists for a user
  Future<Either<Failure, bool>> hasBackup(String userId);
}
