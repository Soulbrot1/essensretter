import 'package:flutter/widgets.dart';
import '../../../../core/utils/app_logger.dart';
import 'snapshot_backup_service.dart';

/// Observer for app lifecycle events to trigger automatic backups
///
/// Listens for app state changes and creates a backup when:
/// - App goes to background (paused, inactive, detached)
/// - App is about to close
///
/// This ensures user data is always backed up before the app stops running.
class AppLifecycleObserver with WidgetsBindingObserver {
  final SnapshotBackupService backupService;
  bool _isBackupInProgress = false;

  AppLifecycleObserver({required this.backupService});

  /// Registers this observer with WidgetsBinding
  void register() {
    WidgetsBinding.instance.addObserver(this);
    AppLogger.info('AppLifecycleObserver registered');
  }

  /// Unregisters this observer
  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
    AppLogger.info('AppLifecycleObserver unregistered');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    AppLogger.info('App lifecycle state changed: $state');

    // Trigger backup when app goes to background
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _triggerBackup();
        break;
      case AppLifecycleState.resumed:
        // App came back to foreground - no action needed
        break;
    }
  }

  /// Triggers a backup if one is not already in progress
  void _triggerBackup() {
    if (_isBackupInProgress) {
      AppLogger.info('Backup already in progress, skipping');
      return;
    }

    _isBackupInProgress = true;

    backupService
        .createBackup()
        .then((success) {
          _isBackupInProgress = false;
          if (success) {
            AppLogger.info('Lifecycle backup completed successfully');
          } else {
            AppLogger.info('Lifecycle backup skipped (no changes)');
          }
        })
        .catchError((error) {
          _isBackupInProgress = false;
          AppLogger.error('Lifecycle backup failed', error: error);
        });
  }
}
