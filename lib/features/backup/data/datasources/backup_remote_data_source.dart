import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/backup_snapshot_model.dart';
import '../../../../core/utils/app_logger.dart';

/// Remote data source for backup operations via Supabase
///
/// Handles direct communication with Supabase 'backups' table
abstract class BackupRemoteDataSource {
  /// Saves backup to Supabase (upsert)
  Future<BackupSnapshotModel> saveBackup(BackupSnapshotModel snapshot);

  /// Retrieves backup from Supabase
  Future<BackupSnapshotModel?> getBackup(String userId);

  /// Deletes backup from Supabase
  Future<void> deleteBackup(String userId);

  /// Checks if backup exists
  Future<bool> hasBackup(String userId);
}

/// Implementation of BackupRemoteDataSource using Supabase
class BackupRemoteDataSourceImpl implements BackupRemoteDataSource {
  final SupabaseClient supabaseClient;

  BackupRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<BackupSnapshotModel> saveBackup(BackupSnapshotModel snapshot) async {
    try {
      // Upsert backup (insert or update)
      // Note: Using service_role key, so RLS policies are bypassed
      final response = await supabaseClient
          .from('backups')
          .upsert(snapshot.toJson(), onConflict: 'user_id')
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Backup save failed: no response from Supabase');
      }

      return BackupSnapshotModel.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to save backup', error: e);
      rethrow;
    }
  }

  @override
  Future<BackupSnapshotModel?> getBackup(String userId) async {
    try {
      final response = await supabaseClient
          .from('backups')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return BackupSnapshotModel.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get backup', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteBackup(String userId) async {
    try {
      await supabaseClient.from('backups').delete().eq('user_id', userId);
    } catch (e) {
      AppLogger.error('Failed to delete backup', error: e);
      rethrow;
    }
  }

  @override
  Future<bool> hasBackup(String userId) async {
    try {
      final response = await supabaseClient
          .from('backups')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.error('Failed to check backup existence', error: e);
      return false;
    }
  }
}
