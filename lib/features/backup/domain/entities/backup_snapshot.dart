import 'package:equatable/equatable.dart';

/// Entity representing a complete backup snapshot
///
/// Contains all user data (foods and friends) that needs to be backed up
/// to Supabase cloud storage. Used for device migration and data recovery.
class BackupSnapshot extends Equatable {
  /// Unique identifier for this backup (UUID from Supabase)
  final String? id;

  /// User's RetterId (format: ER-XXXXXXXX)
  final String userId;

  /// JSON data containing foods and friends
  final Map<String, dynamic> data;

  /// SHA-256 hash of the data for integrity check and duplicate detection
  final String? dataHash;

  /// Device information (e.g., "iPhone 14", "Samsung Galaxy S21")
  final String? deviceInfo;

  /// App version at time of backup (e.g., "1.0.0")
  final String? appVersion;

  /// When this backup was created
  final DateTime? createdAt;

  /// When this backup was last updated
  final DateTime? updatedAt;

  const BackupSnapshot({
    this.id,
    required this.userId,
    required this.data,
    this.dataHash,
    this.deviceInfo,
    this.appVersion,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    data,
    dataHash,
    deviceInfo,
    appVersion,
    createdAt,
    updatedAt,
  ];

  /// Creates a copy with updated fields
  BackupSnapshot copyWith({
    String? id,
    String? userId,
    Map<String, dynamic>? data,
    String? dataHash,
    String? deviceInfo,
    String? appVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BackupSnapshot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      dataHash: dataHash ?? this.dataHash,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
