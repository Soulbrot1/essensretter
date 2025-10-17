import '../../domain/entities/backup_snapshot.dart';

/// Data model for BackupSnapshot with JSON serialization
///
/// Extends the domain entity to add fromJson/toJson methods
/// for Supabase communication.
class BackupSnapshotModel extends BackupSnapshot {
  const BackupSnapshotModel({
    super.id,
    required super.userId,
    required super.data,
    super.dataHash,
    super.deviceInfo,
    super.appVersion,
    super.createdAt,
    super.updatedAt,
  });

  /// Creates model from JSON (from Supabase response)
  factory BackupSnapshotModel.fromJson(Map<String, dynamic> json) {
    return BackupSnapshotModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      data: json['data'] as Map<String, dynamic>,
      dataHash: json['data_hash'] as String?,
      deviceInfo: json['device_info'] as String?,
      appVersion: json['app_version'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Converts model to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'data': data,
      if (dataHash != null) 'data_hash': dataHash,
      if (deviceInfo != null) 'device_info': deviceInfo,
      if (appVersion != null) 'app_version': appVersion,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Creates model from entity
  factory BackupSnapshotModel.fromEntity(BackupSnapshot entity) {
    return BackupSnapshotModel(
      id: entity.id,
      userId: entity.userId,
      data: entity.data,
      dataHash: entity.dataHash,
      deviceInfo: entity.deviceInfo,
      appVersion: entity.appVersion,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converts model to entity
  BackupSnapshot toEntity() {
    return BackupSnapshot(
      id: id,
      userId: userId,
      data: data,
      dataHash: dataHash,
      deviceInfo: deviceInfo,
      appVersion: appVersion,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
