import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:essensretter/features/sharing/data/repositories/share_code_repository_impl.dart';
import 'package:essensretter/features/sharing/data/datasources/share_code_remote_data_source.dart';
import 'package:essensretter/core/error/failures.dart';

// Mock classes
class MockShareCodeRemoteDataSource extends Mock
    implements ShareCodeRemoteDataSource {}

void main() {
  late ShareCodeRepositoryImpl repository;
  late MockShareCodeRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockShareCodeRemoteDataSource();
    repository = ShareCodeRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('ShareCodeRepository', () {
    const testRetterId = 'ER-TEST1234';
    const testShareCode = 'A3F9B2';
    const newShareCode = 'K8M5P2';

    group('getShareCode', () {
      test('should return share code when user exists', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getShareCode(testRetterId),
        ).thenAnswer((_) async => testShareCode);

        // Act
        final result = await repository.getShareCode(testRetterId);

        // Assert
        expect(result, isA<Right<Failure, String>>());
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (shareCode) => expect(shareCode, testShareCode),
        );
        verify(() => mockRemoteDataSource.getShareCode(testRetterId)).called(1);
      });

      test('should return ServerFailure when user not found', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getShareCode(testRetterId),
        ).thenThrow(Exception('Share-Code nicht gefunden'));

        // Act
        final result = await repository.getShareCode(testRetterId);

        // Assert
        expect(result, isA<Left<Failure, String>>());
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Fehler beim Abrufen'));
        }, (shareCode) => fail('Expected Left but got Right'));
      });

      test('should return ServerFailure on network error', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getShareCode(testRetterId),
        ).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.getShareCode(testRetterId);

        // Assert
        expect(result, isA<Left<Failure, String>>());
      });
    });

    group('getRetterIdByShareCode', () {
      test('should return RetterId when share code is valid', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getRetterIdByShareCode(testShareCode),
        ).thenAnswer((_) async => testRetterId);

        // Act
        final result = await repository.getRetterIdByShareCode(testShareCode);

        // Assert
        expect(result, isA<Right<Failure, String>>());
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (retterId) => expect(retterId, testRetterId),
        );
        verify(
          () => mockRemoteDataSource.getRetterIdByShareCode(testShareCode),
        ).called(1);
      });

      test('should return ServerFailure when share code invalid', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getRetterIdByShareCode(testShareCode),
        ).thenThrow(Exception('Ungültiger Share-Code'));

        // Act
        final result = await repository.getRetterIdByShareCode(testShareCode);

        // Assert
        expect(result, isA<Left<Failure, String>>());
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Fehler beim Auflösen'));
        }, (retterId) => fail('Expected Left but got Right'));
      });

      test('should handle uppercase conversion correctly', () async {
        // Arrange
        const lowercaseCode = 'a3f9b2';
        when(
          () => mockRemoteDataSource.getRetterIdByShareCode(lowercaseCode),
        ).thenAnswer((_) async => testRetterId);

        // Act
        final result = await repository.getRetterIdByShareCode(lowercaseCode);

        // Assert
        expect(result, isA<Right<Failure, String>>());
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (retterId) => expect(retterId, testRetterId),
        );
      });
    });

    group('regenerateShareCode', () {
      test('should return new share code when regeneration succeeds', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.regenerateShareCode(testRetterId),
        ).thenAnswer((_) async => newShareCode);

        // Act
        final result = await repository.regenerateShareCode(testRetterId);

        // Assert
        expect(result, isA<Right<Failure, String>>());
        result.fold((failure) => fail('Expected Right but got Left'), (
          shareCode,
        ) {
          expect(shareCode, newShareCode);
          expect(shareCode, isNot(testShareCode)); // Should be different
        });
        verify(
          () => mockRemoteDataSource.regenerateShareCode(testRetterId),
        ).called(1);
      });

      test('should return ServerFailure when regeneration fails', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.regenerateShareCode(testRetterId),
        ).thenThrow(Exception('Database error'));

        // Act
        final result = await repository.regenerateShareCode(testRetterId);

        // Assert
        expect(result, isA<Left<Failure, String>>());
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Fehler beim Regenerieren'));
        }, (shareCode) => fail('Expected Left but got Right'));
      });
    });

    group('createShareCode', () {
      test('should return new share code for new user', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.createShareCode(testRetterId),
        ).thenAnswer((_) async => testShareCode);

        // Act
        final result = await repository.createShareCode(testRetterId);

        // Assert
        expect(result, isA<Right<Failure, String>>());
        result.fold((failure) => fail('Expected Right but got Left'), (
          shareCode,
        ) {
          expect(shareCode, testShareCode);
          expect(shareCode.length, 6); // Share codes are 6 characters
        });
        verify(
          () => mockRemoteDataSource.createShareCode(testRetterId),
        ).called(1);
      });

      test('should return existing share code if already exists', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.createShareCode(testRetterId),
        ).thenAnswer((_) async => testShareCode);

        // Act
        final result = await repository.createShareCode(testRetterId);

        // Assert
        expect(result, isA<Right<Failure, String>>());
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (shareCode) => expect(shareCode, testShareCode),
        );
      });

      test('should return ServerFailure when creation fails', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.createShareCode(testRetterId),
        ).thenThrow(Exception('Database error'));

        // Act
        final result = await repository.createShareCode(testRetterId);

        // Assert
        expect(result, isA<Left<Failure, String>>());
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Fehler beim Erstellen'));
        }, (shareCode) => fail('Expected Left but got Right'));
      });
    });

    group('Integration scenarios', () {
      test(
        'should handle complete lifecycle: create -> get -> regenerate',
        () async {
          // Create
          when(
            () => mockRemoteDataSource.createShareCode(testRetterId),
          ).thenAnswer((_) async => testShareCode);

          final createResult = await repository.createShareCode(testRetterId);
          expect(createResult, isA<Right<Failure, String>>());

          // Get
          when(
            () => mockRemoteDataSource.getShareCode(testRetterId),
          ).thenAnswer((_) async => testShareCode);

          final getResult = await repository.getShareCode(testRetterId);
          expect(getResult, isA<Right<Failure, String>>());

          // Regenerate
          when(
            () => mockRemoteDataSource.regenerateShareCode(testRetterId),
          ).thenAnswer((_) async => newShareCode);

          final regenerateResult = await repository.regenerateShareCode(
            testRetterId,
          );
          expect(regenerateResult, isA<Right<Failure, String>>());

          regenerateResult.fold(
            (failure) => fail('Expected Right but got Left'),
            (shareCode) => expect(shareCode, newShareCode),
          );
        },
      );
    });
  });
}
