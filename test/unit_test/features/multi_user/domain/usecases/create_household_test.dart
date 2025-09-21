import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/core/usecases/usecase.dart';
import 'package:essensretter/features/multi_user/domain/entities/household.dart';
import 'package:essensretter/features/multi_user/domain/repositories/household_repository.dart';
import 'package:essensretter/features/multi_user/domain/usecases/create_household.dart';

class MockHouseholdRepository extends Mock implements HouseholdRepository {}

void main() {
  late CreateHousehold usecase;
  late MockHouseholdRepository mockRepository;

  setUp(() {
    mockRepository = MockHouseholdRepository();
    usecase = CreateHousehold(repository: mockRepository);
  });

  group('CreateHousehold', () {
    const tHousehold = Household(
      id: 'test-id',
      masterKey: 'test-master-key',
      createdAt: '2025-01-21T10:00:00Z',
    );

    test('sollte neuen Haushalt erfolgreich erstellen', () async {
      // Arrange
      when(
        () => mockRepository.createHousehold(),
      ).thenAnswer((_) async => const Right(tHousehold));

      // Act
      final result = await usecase(NoParams());

      // Assert
      expect(result, const Right(tHousehold));
      verify(() => mockRepository.createHousehold()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test(
      'sollte ServerFailure zurückgeben wenn Repository fehlschlägt',
      () async {
        // Arrange
        const tFailure = ServerFailure('Haushalt konnte nicht erstellt werden');
        when(
          () => mockRepository.createHousehold(),
        ).thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await usecase(NoParams());

        // Assert
        expect(result, const Left(tFailure));
        verify(() => mockRepository.createHousehold()).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );
  });
}
