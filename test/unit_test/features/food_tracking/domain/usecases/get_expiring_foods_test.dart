import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/domain/repositories/food_repository.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/get_expiring_foods.dart';

class MockFoodRepository extends Mock implements FoodRepository {}

void main() {
  late GetExpiringFoods usecase;
  late MockFoodRepository mockRepository;

  setUp(() {
    mockRepository = MockFoodRepository();
    usecase = GetExpiringFoods(mockRepository);
  });

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final tAllFoods = [
    Food(
      id: '1',
      name: 'Expired Yesterday',
      addedDate: today.subtract(const Duration(days: 5)),
      expiryDate: today.subtract(const Duration(days: 1)),
    ),
    Food(
      id: '2',
      name: 'Expires Today',
      addedDate: today.subtract(const Duration(days: 3)),
      expiryDate: today,
    ),
    Food(
      id: '3',
      name: 'Expires Tomorrow',
      addedDate: today.subtract(const Duration(days: 2)),
      expiryDate: today.add(const Duration(days: 1)),
    ),
    Food(
      id: '4',
      name: 'Expires In 5 Days',
      addedDate: today.subtract(const Duration(days: 1)),
      expiryDate: today.add(const Duration(days: 5)),
    ),
    Food(
      id: '5',
      name: 'Expires In 10 Days',
      addedDate: today,
      expiryDate: today.add(const Duration(days: 10)),
    ),
    Food(id: '6', name: 'No Expiry Date', addedDate: today, expiryDate: null),
  ];

  group('GetExpiringFoods', () {
    test('should get foods expiring within specified days', () async {
      // arrange
      const tDaysAhead = 7;
      when(
        () => mockRepository.getAllFoods(),
      ).thenAnswer((_) async => Right(tAllFoods));

      // act
      final result = await usecase(
        const GetExpiringFoodsParams(daysAhead: tDaysAhead),
      );

      // assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should return foods'), (foods) {
        // Should include: expired, today, tomorrow, 5 days (within 7 days)
        // Should exclude: 10 days (beyond 7 days), no expiry date
        expect(foods.length, 4);
        expect(foods[0].name, 'Expired Yesterday'); // sorted by date
        expect(foods[1].name, 'Expires Today');
        expect(foods[2].name, 'Expires Tomorrow');
        expect(foods[3].name, 'Expires In 5 Days');
      });
    });

    test('should include expired foods (before today)', () async {
      // arrange
      const tDaysAhead = 3;
      when(
        () => mockRepository.getAllFoods(),
      ).thenAnswer((_) async => Right(tAllFoods));

      // act
      final result = await usecase(
        const GetExpiringFoodsParams(daysAhead: tDaysAhead),
      );

      // assert
      result.fold((l) => fail('Should return foods'), (foods) {
        // Should include expired food
        expect(foods.any((f) => f.name == 'Expired Yesterday'), true);
      });
    });

    test('should sort foods by expiry date (earliest first)', () async {
      // arrange
      const tDaysAhead = 7;
      when(
        () => mockRepository.getAllFoods(),
      ).thenAnswer((_) async => Right(tAllFoods));

      // act
      final result = await usecase(
        const GetExpiringFoodsParams(daysAhead: tDaysAhead),
      );

      // assert
      result.fold((l) => fail('Should return foods'), (foods) {
        // Verify sorting
        for (int i = 0; i < foods.length - 1; i++) {
          expect(
            foods[i].expiryDate!.isBefore(foods[i + 1].expiryDate!) ||
                foods[i].expiryDate!.isAtSameMomentAs(foods[i + 1].expiryDate!),
            true,
            reason: 'Foods should be sorted by expiry date',
          );
        }
      });
    });

    test('should exclude foods without expiry date', () async {
      // arrange
      const tDaysAhead = 30;
      when(
        () => mockRepository.getAllFoods(),
      ).thenAnswer((_) async => Right(tAllFoods));

      // act
      final result = await usecase(
        const GetExpiringFoodsParams(daysAhead: tDaysAhead),
      );

      // assert
      result.fold((l) => fail('Should return foods'), (foods) {
        expect(foods.any((f) => f.expiryDate == null), false);
        expect(foods.any((f) => f.name == 'No Expiry Date'), false);
      });
    });

    test(
      'should return empty list when no foods are expiring in timeframe',
      () async {
        // arrange
        final farFutureFoods = [
          Food(
            id: '1',
            name: 'Far Future',
            addedDate: today,
            expiryDate: today.add(const Duration(days: 100)),
          ),
        ];
        when(
          () => mockRepository.getAllFoods(),
        ).thenAnswer((_) async => Right(farFutureFoods));

        // act
        final result = await usecase(
          const GetExpiringFoodsParams(daysAhead: 7),
        );

        // assert
        result.fold(
          (l) => fail('Should return empty list'),
          (foods) => expect(foods, isEmpty),
        );
      },
    );

    test('should return CacheFailure when repository fails', () async {
      // arrange
      when(
        () => mockRepository.getAllFoods(),
      ).thenAnswer((_) async => const Left(CacheFailure('Fehler beim Laden')));

      // act
      final result = await usecase(const GetExpiringFoodsParams(daysAhead: 7));

      // assert
      expect(result, const Left(CacheFailure('Fehler beim Laden')));
    });

    test('should handle daysAhead = 0 (only today and expired)', () async {
      // arrange
      when(
        () => mockRepository.getAllFoods(),
      ).thenAnswer((_) async => Right(tAllFoods));

      // act
      final result = await usecase(const GetExpiringFoodsParams(daysAhead: 0));

      // assert
      result.fold((l) => fail('Should return foods'), (foods) {
        // Should include: expired yesterday, expires today
        // Should exclude: tomorrow onwards
        expect(foods.length, 2);
        expect(foods[0].name, 'Expired Yesterday');
        expect(foods[1].name, 'Expires Today');
      });
    });

    test('should handle daysAhead = 1 (today and tomorrow)', () async {
      // arrange
      when(
        () => mockRepository.getAllFoods(),
      ).thenAnswer((_) async => Right(tAllFoods));

      // act
      final result = await usecase(const GetExpiringFoodsParams(daysAhead: 1));

      // assert
      result.fold((l) => fail('Should return foods'), (foods) {
        expect(foods.length, 3);
        expect(foods.any((f) => f.name == 'Expired Yesterday'), true);
        expect(foods.any((f) => f.name == 'Expires Today'), true);
        expect(foods.any((f) => f.name == 'Expires Tomorrow'), true);
      });
    });

    test('should handle empty food list', () async {
      // arrange
      when(
        () => mockRepository.getAllFoods(),
      ).thenAnswer((_) async => const Right([]));

      // act
      final result = await usecase(const GetExpiringFoodsParams(daysAhead: 7));

      // assert
      result.fold(
        (l) => fail('Should return empty list'),
        (foods) => expect(foods, isEmpty),
      );
    });
  });

  group('GetExpiringFoodsParams', () {
    test('should be equal when daysAhead is the same', () {
      // arrange
      const params1 = GetExpiringFoodsParams(daysAhead: 7);
      const params2 = GetExpiringFoodsParams(daysAhead: 7);

      // assert
      expect(params1, params2);
      expect(params1.hashCode, params2.hashCode);
    });

    test('should not be equal when daysAhead is different', () {
      // arrange
      const params1 = GetExpiringFoodsParams(daysAhead: 7);
      const params2 = GetExpiringFoodsParams(daysAhead: 3);

      // assert
      expect(params1, isNot(params2));
    });

    test('should have correct props', () {
      // arrange
      const params = GetExpiringFoodsParams(daysAhead: 7);

      // assert
      expect(params.props, [7]);
    });
  });
}
