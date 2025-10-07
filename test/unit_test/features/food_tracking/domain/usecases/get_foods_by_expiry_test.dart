import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/domain/repositories/food_repository.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/get_foods_by_expiry.dart';

class MockFoodRepository extends Mock implements FoodRepository {}

void main() {
  late GetFoodsByExpiry usecase;
  late MockFoodRepository mockRepository;

  setUp(() {
    mockRepository = MockFoodRepository();
    usecase = GetFoodsByExpiry(mockRepository);
  });

  final tDateTime = DateTime(2024, 1, 15);
  final tFoodList = [
    Food(
      id: '1',
      name: 'Expiring Soon',
      addedDate: tDateTime,
      expiryDate: tDateTime.add(const Duration(days: 2)),
    ),
    Food(
      id: '2',
      name: 'Expiring Later',
      addedDate: tDateTime,
      expiryDate: tDateTime.add(const Duration(days: 5)),
    ),
  ];

  group('GetFoodsByExpiry', () {
    test(
      'should get foods expiring within specified days from repository',
      () async {
        // arrange
        const tDays = 7;
        when(
          () => mockRepository.getFoodsByExpiryDays(tDays),
        ).thenAnswer((_) async => Right(tFoodList));

        // act
        final result = await usecase(
          const GetFoodsByExpiryParams(daysUntilExpiry: tDays),
        );

        // assert
        expect(result, Right(tFoodList));
        verify(() => mockRepository.getFoodsByExpiryDays(tDays)).called(1);
      },
    );

    test('should return CacheFailure when repository fails', () async {
      // arrange
      const tDays = 7;
      when(
        () => mockRepository.getFoodsByExpiryDays(tDays),
      ).thenAnswer((_) async => const Left(CacheFailure('Fehler beim Laden')));

      // act
      final result = await usecase(
        const GetFoodsByExpiryParams(daysUntilExpiry: tDays),
      );

      // assert
      expect(result, const Left(CacheFailure('Fehler beim Laden')));
      verify(() => mockRepository.getFoodsByExpiryDays(tDays)).called(1);
    });

    test('should return empty list when no foods are expiring', () async {
      // arrange
      const tDays = 1;
      when(
        () => mockRepository.getFoodsByExpiryDays(tDays),
      ).thenAnswer((_) async => const Right([]));

      // act
      final result = await usecase(
        const GetFoodsByExpiryParams(daysUntilExpiry: tDays),
      );

      // assert
      expect(result.isRight(), true);
      result.fold((l) => null, (foods) => expect(foods, isEmpty));
      verify(() => mockRepository.getFoodsByExpiryDays(tDays)).called(1);
    });

    test('should pass correct days parameter to repository', () async {
      // arrange
      const tDays = 3;
      when(
        () => mockRepository.getFoodsByExpiryDays(tDays),
      ).thenAnswer((_) async => Right(tFoodList));

      // act
      await usecase(const GetFoodsByExpiryParams(daysUntilExpiry: tDays));

      // assert
      verify(() => mockRepository.getFoodsByExpiryDays(tDays)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle different day values correctly', () async {
      // arrange
      final testCases = [1, 3, 7, 14, 30];

      for (final days in testCases) {
        when(
          () => mockRepository.getFoodsByExpiryDays(days),
        ).thenAnswer((_) async => Right(tFoodList));

        // act
        await usecase(GetFoodsByExpiryParams(daysUntilExpiry: days));

        // assert
        verify(() => mockRepository.getFoodsByExpiryDays(days)).called(1);
      }
    });
  });

  group('GetFoodsByExpiryParams', () {
    test('should be equal when daysUntilExpiry is the same', () {
      // arrange
      const params1 = GetFoodsByExpiryParams(daysUntilExpiry: 7);
      const params2 = GetFoodsByExpiryParams(daysUntilExpiry: 7);

      // assert
      expect(params1, params2);
      expect(params1.hashCode, params2.hashCode);
    });

    test('should not be equal when daysUntilExpiry is different', () {
      // arrange
      const params1 = GetFoodsByExpiryParams(daysUntilExpiry: 7);
      const params2 = GetFoodsByExpiryParams(daysUntilExpiry: 3);

      // assert
      expect(params1, isNot(params2));
    });

    test('should have correct props', () {
      // arrange
      const params = GetFoodsByExpiryParams(daysUntilExpiry: 7);

      // assert
      expect(params.props, [7]);
    });
  });
}
