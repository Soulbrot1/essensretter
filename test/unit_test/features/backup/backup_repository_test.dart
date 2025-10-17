import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:essensretter/features/backup/domain/entities/backup_snapshot.dart';
import 'package:essensretter/features/backup/data/models/backup_snapshot_model.dart';
import 'package:essensretter/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:essensretter/features/backup/data/datasources/backup_remote_data_source.dart';
import 'package:essensretter/core/error/failures.dart';

// Mock classes
class MockBackupRemoteDataSource extends Mock
    implements BackupRemoteDataSource {}

void main() {
  late BackupRepositoryImpl repository;
  late MockBackupRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockBackupRemoteDataSource();
    repository = BackupRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('BackupRepository', () {
    const testUserId = 'ER-TEST1234';

    final testBackupData = {
      'version': '1.0',
      'timestamp': '2025-01-16T10:00:00Z',
      'foods': [],
      'friends': [],
    };

    final testSnapshot = BackupSnapshot(
      userId: testUserId,
      data: testBackupData,
      dataHash: 'test-hash',
      deviceInfo: 'Test Device',
      appVersion: '1.0.0',
    );

    final testSnapshotModel = BackupSnapshotModel(
      id: 'backup-123',
      userId: testUserId,
      data: testBackupData,
      dataHash: 'test-hash',
      deviceInfo: 'Test Device',
      appVersion: '1.0.0',
      createdAt: DateTime(2025, 1, 16),
      updatedAt: DateTime(2025, 1, 16),
    );

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(BackupSnapshotModel.fromEntity(testSnapshot));
    });

    group('saveBackup', () {
      test('should return BackupSnapshot when save is successful', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.saveBackup(any()),
        ).thenAnswer((_) async => testSnapshotModel);

        // Act
        final result = await repository.saveBackup(testSnapshot);

        // Assert
        expect(result, isA<Right<Failure, BackupSnapshot>>());
        result.fold((failure) => fail('Expected Right but got Left'), (
          snapshot,
        ) {
          expect(snapshot.userId, testUserId);
          expect(snapshot.dataHash, 'test-hash');
        });
        verify(() => mockRemoteDataSource.saveBackup(any())).called(1);
      });

      test('should return ServerFailure when save fails', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.saveBackup(any()),
        ).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.saveBackup(testSnapshot);

        // Assert
        expect(result, isA<Left<Failure, BackupSnapshot>>());
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Failed to save backup'));
        }, (snapshot) => fail('Expected Left but got Right'));
      });
    });

    group('getBackup', () {
      test('should return BackupSnapshot when backup exists', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getBackup(testUserId),
        ).thenAnswer((_) async => testSnapshotModel);

        // Act
        final result = await repository.getBackup(testUserId);

        // Assert
        expect(result, isA<Right<Failure, BackupSnapshot?>>());
        result.fold((failure) => fail('Expected Right but got Left'), (
          snapshot,
        ) {
          expect(snapshot, isNotNull);
          expect(snapshot!.userId, testUserId);
        });
        verify(() => mockRemoteDataSource.getBackup(testUserId)).called(1);
      });

      test('should return null when no backup exists', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getBackup(testUserId),
        ).thenAnswer((_) async => null);

        // Act
        final result = await repository.getBackup(testUserId);

        // Assert
        expect(result, isA<Right<Failure, BackupSnapshot?>>());
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (snapshot) => expect(snapshot, null),
        );
      });

      test('should return ServerFailure when get fails', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getBackup(testUserId),
        ).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.getBackup(testUserId);

        // Assert
        expect(result, isA<Left<Failure, BackupSnapshot?>>());
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (snapshot) => fail('Expected Left but got Right'),
        );
      });
    });

    group('deleteBackup', () {
      test('should complete successfully when delete succeeds', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.deleteBackup(testUserId),
        ).thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteBackup(testUserId);

        // Assert
        expect(result, isA<Right<Failure, void>>());
        verify(() => mockRemoteDataSource.deleteBackup(testUserId)).called(1);
      });

      test('should return ServerFailure when delete fails', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.deleteBackup(testUserId),
        ).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.deleteBackup(testUserId);

        // Assert
        expect(result, isA<Left<Failure, void>>());
      });
    });

    group('hasBackup', () {
      test('should return true when backup exists', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.hasBackup(testUserId),
        ).thenAnswer((_) async => true);

        // Act
        final result = await repository.hasBackup(testUserId);

        // Assert
        expect(result, isA<Right<Failure, bool>>());
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (exists) => expect(exists, true),
        );
      });

      test('should return false when no backup exists', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.hasBackup(testUserId),
        ).thenAnswer((_) async => false);

        // Act
        final result = await repository.hasBackup(testUserId);

        // Assert
        expect(result, isA<Right<Failure, bool>>());
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (exists) => expect(exists, false),
        );
      });
    });
  });
}
