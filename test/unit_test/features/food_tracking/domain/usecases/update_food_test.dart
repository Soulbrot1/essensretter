import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/domain/repositories/food_repository.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/update_food.dart';

class MockFoodRepository extends Mock implements FoodRepository {}

class FakeFood extends Fake implements Food {}

void main() {
  late UpdateFood updateFood;
  late MockFoodRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeFood());
  });

  setUp(() {
    mockRepository = MockFoodRepository();
    updateFood = UpdateFood(mockRepository);
  });

  group('UpdateFood', () {
    final testFood = Food(
      id: 'test-id',
      name: 'Test Food',
      expiryDate: DateTime.now().add(const Duration(days: 3)),
      addedDate: DateTime.now(),
      category: 'Test Category',
      isConsumed: false,
    );

    test('sollte Food erfolgreich aktualisieren', () async {
      // arrange
      final updatedFood = testFood.copyWith(
        name: 'Updated Food',
        expiryDate: DateTime.now().add(const Duration(days: 5)),
      );

      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(updatedFood));

      // act
      final result = await updateFood(updatedFood);

      // assert
      expect(result, Right(updatedFood));
      verify(() => mockRepository.updateFood(updatedFood)).called(1);
    });

    test('sollte isConsumed Status aktualisieren können', () async {
      // arrange
      final consumedFood = testFood.copyWith(isConsumed: true);

      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(consumedFood));

      // act
      final result = await updateFood(consumedFood);

      // assert
      expect(result.isRight(), true);
      result.fold((_) => fail('Should have returned updated food'), (food) {
        expect(food.isConsumed, true);
        expect(food.name, testFood.name);
      });
    });

    test('sollte Ablaufdatum aktualisieren können', () async {
      // arrange
      final newExpiryDate = DateTime.now().add(const Duration(days: 10));
      final updatedFood = testFood.copyWith(expiryDate: newExpiryDate);

      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(updatedFood));

      // act
      final result = await updateFood(updatedFood);

      // assert
      expect(result.isRight(), true);
      result.fold((_) => fail('Should have returned updated food'), (food) {
        expect(food.expiryDate, newExpiryDate);
      });
    });

    test(
      'sollte CacheFailure zurückgeben wenn Repository fehlschlägt',
      () async {
        // arrange
        when(() => mockRepository.updateFood(any())).thenAnswer(
          (_) async => const Left(CacheFailure('Update fehlgeschlagen')),
        );

        // act
        final result = await updateFood(testFood);

        // assert
        expect(
          result,
          const Left<Failure, Food>(CacheFailure('Update fehlgeschlagen')),
        );
        verify(() => mockRepository.updateFood(testFood)).called(1);
      },
    );

    test('sollte mit Food ohne Ablaufdatum umgehen', () async {
      // arrange
      final foodWithoutExpiry = Food(
        id: 'test-id',
        name: 'Food ohne Ablaufdatum',
        expiryDate: null,
        addedDate: DateTime.now(),
      );

      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(foodWithoutExpiry));

      // act
      final result = await updateFood(foodWithoutExpiry);

      // assert
      expect(result.isRight(), true);
      result.fold((_) => fail('Should have returned updated food'), (food) {
        expect(food.expiryDate, null);
        expect(food.name, 'Food ohne Ablaufdatum');
      });
    });

    test('sollte Kategorie aktualisieren können', () async {
      // arrange
      final updatedFood = testFood.copyWith(category: 'Neue Kategorie');

      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(updatedFood));

      // act
      final result = await updateFood(updatedFood);

      // assert
      expect(result.isRight(), true);
      result.fold((_) => fail('Should have returned updated food'), (food) {
        expect(food.category, 'Neue Kategorie');
      });
    });

    test('sollte Exception als CacheFailure behandeln', () async {
      // arrange
      when(
        () => mockRepository.updateFood(any()),
      ).thenThrow(Exception('Database error'));

      // act
      final result = await updateFood(testFood);

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Should have returned a failure'),
      );
    });

    test('sollte mehrere Eigenschaften gleichzeitig aktualisieren', () async {
      // arrange
      final completelyUpdatedFood = testFood.copyWith(
        name: 'Komplett Neu',
        expiryDate: DateTime.now().add(const Duration(days: 7)),
        category: 'Andere Kategorie',
        isConsumed: true,
      );

      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(completelyUpdatedFood));

      // act
      final result = await updateFood(completelyUpdatedFood);

      // assert
      expect(result.isRight(), true);
      result.fold((_) => fail('Should have returned updated food'), (food) {
        expect(food.name, 'Komplett Neu');
        expect(food.category, 'Andere Kategorie');
        expect(food.isConsumed, true);
      });
    });
  });
}
