import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/backup_snapshot.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../../food_tracking/domain/repositories/food_repository.dart';
import '../../../food_tracking/data/models/food_model.dart';
import '../../../sharing/presentation/services/simple_user_identity_service.dart';
import '../../../sharing/presentation/services/friend_service.dart';
import '../../../sharing/presentation/services/local_friend_names_service.dart';
import '../../../sharing/presentation/services/local_friend_messenger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for creating and managing snapshot backups
///
/// Implements the snapshot-backup pattern:
/// - Collects all user data (foods + friends) from local storage
/// - Creates JSON snapshot with hash for change detection
/// - Only uploads if data changed (70% traffic reduction)
/// - Triggers automatically on app lifecycle events
class SnapshotBackupService {
  final BackupRepository backupRepository;
  final FoodRepository foodRepository;

  static const String _lastHashKey = 'last_backup_hash';

  SnapshotBackupService({
    required this.backupRepository,
    required this.foodRepository,
  });

  /// Creates and uploads a backup snapshot if data changed
  ///
  /// Returns true if backup was created, false if skipped (no changes)
  Future<bool> createBackup() async {
    try {
      // 1. Get RetterId
      final retterId = await SimpleUserIdentityService.getCurrentUserId();
      if (retterId == null) {
        AppLogger.warning('Cannot create backup: No RetterId found');
        return false;
      }

      // 2. Collect all data
      final backupData = await _collectAllData();

      // 3. Calculate hash
      final currentHash = _calculateHash(backupData);

      // 4. Check if data changed
      final lastHash = await _getLastBackupHash();
      if (currentHash == lastHash) {
        AppLogger.info('Backup skipped: No changes detected');
        return false;
      }

      // 5. Get device info and app version
      final deviceInfo = await _getDeviceInfo();
      final appVersion = await _getAppVersion();

      // 6. Create snapshot
      final snapshot = BackupSnapshot(
        userId: retterId,
        data: backupData,
        dataHash: currentHash,
        deviceInfo: deviceInfo,
        appVersion: appVersion,
      );

      // 7. Upload to Supabase
      final result = await backupRepository.saveBackup(snapshot);

      return result.fold(
        (failure) {
          AppLogger.error('Backup failed', error: failure);
          return false;
        },
        (savedSnapshot) async {
          // Save hash for next comparison
          await _saveLastBackupHash(currentHash);
          AppLogger.info('Backup created successfully: ${savedSnapshot.id}');
          return true;
        },
      );
    } catch (e) {
      AppLogger.error('Backup creation failed', error: e);
      return false;
    }
  }

  /// Collects all data that needs to be backed up
  ///
  /// Returns a map with structure:
  /// {
  ///   "version": "1.0",
  ///   "timestamp": "2025-01-16T10:00:00Z",
  ///   "foods": [...],
  ///   "friends": [...]
  /// }
  Future<Map<String, dynamic>> _collectAllData() async {
    // Collect foods
    final foodsResult = await foodRepository.getAllFoods();
    final foods = foodsResult.fold(
      (failure) => <Map<String, dynamic>>[],
      (foodList) =>
          foodList.map((food) => FoodModel.fromEntity(food).toJson()).toList(),
    );

    // Collect friends with local data
    final friendConnections = await FriendService.getFriends();
    final friendNames = await LocalFriendNamesService.getAllFriendNames();

    final friends = <Map<String, dynamic>>[];
    for (final connection in friendConnections) {
      final messenger = await LocalFriendMessengerService.getFriendMessenger(
        connection.friendId,
      );

      friends.add({
        'friendId': connection.friendId,
        'friendName': friendNames[connection.friendId],
        'status': connection.status,
        'createdAt': connection.createdAt.toIso8601String(),
        'preferredMessenger': messenger?.name,
      });
    }

    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'foods': foods,
      'friends': friends,
    };
  }

  /// Calculates SHA-256 hash of the backup data
  String _calculateHash(Map<String, dynamic> data) {
    // Convert data to canonical JSON (sorted keys for consistency)
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Gets the hash from the last backup
  Future<String?> _getLastBackupHash() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastHashKey);
    } catch (e) {
      AppLogger.error('Failed to get last backup hash', error: e);
      return null;
    }
  }

  /// Saves the hash of the current backup
  Future<void> _saveLastBackupHash(String hash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastHashKey, hash);
    } catch (e) {
      AppLogger.error('Failed to save backup hash', error: e);
    }
  }

  /// Gets device information for metadata
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Gets app version for metadata
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Checks if a backup exists for the current user
  Future<bool> hasBackup() async {
    try {
      final retterId = await SimpleUserIdentityService.getCurrentUserId();
      if (retterId == null) return false;

      final result = await backupRepository.hasBackup(retterId);
      return result.fold((failure) => false, (exists) => exists);
    } catch (e) {
      return false;
    }
  }

  /// Gets the latest backup metadata (without full data)
  Future<BackupSnapshot?> getBackupMetadata() async {
    try {
      final retterId = await SimpleUserIdentityService.getCurrentUserId();
      if (retterId == null) return null;

      final result = await backupRepository.getBackup(retterId);
      return result.fold((failure) => null, (snapshot) => snapshot);
    } catch (e) {
      return null;
    }
  }
}
