import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/domain/repositories/food_repository.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/toggle_food_consumed.dart';

class MockFoodRepository extends Mock implements FoodRepository {}

class FakeFood extends Fake implements Food {}

void main() {
  late ToggleFoodConsumed usecase;
  late MockFoodRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeFood());
  });

  setUp(() {
    mockRepository = MockFoodRepository();
    usecase = ToggleFoodConsumed(mockRepository);
  });

  final tDateTime = DateTime(2024, 1, 15);
  final tFood = Food(
    id: '1',
    name: 'Test Food',
    addedDate: tDateTime,
    expiryDate: tDateTime.add(const Duration(days: 5)),
    isConsumed: false,
  );

  group('ToggleFoodConsumed', () {
    test('should toggle isConsumed from false to true', () async {
      // arrange
      final expectedFood = tFood.copyWith(isConsumed: true);
      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(expectedFood));

      // act
      final result = await usecase(ToggleFoodConsumedParams(food: tFood));

      // assert
      expect(result, Right(expectedFood));

      // Verify the food passed to updateFood has isConsumed = true
      final captured = verify(
        () => mockRepository.updateFood(captureAny()),
      ).captured;
      expect(captured.first.isConsumed, true);
      expect(captured.first.id, tFood.id);
      expect(captured.first.name, tFood.name);
    });

    test('should toggle isConsumed from true to false', () async {
      // arrange
      final consumedFood = tFood.copyWith(isConsumed: true);
      final expectedFood = consumedFood.copyWith(isConsumed: false);
      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(expectedFood));

      // act
      final result = await usecase(
        ToggleFoodConsumedParams(food: consumedFood),
      );

      // assert
      expect(result, Right(expectedFood));

      // Verify the food passed to updateFood has isConsumed = false
      final captured = verify(
        () => mockRepository.updateFood(captureAny()),
      ).captured;
      expect(captured.first.isConsumed, false);
    });

    test('should preserve all other food properties when toggling', () async {
      // arrange
      final detailedFood = Food(
        id: '2',
        name: 'Detailed Food',
        addedDate: tDateTime,
        expiryDate: tDateTime.add(const Duration(days: 3)),
        category: 'Obst',
        notes: 'Test notes',
        isConsumed: false,
        isShared: true,
      );
      final expectedFood = detailedFood.copyWith(isConsumed: true);
      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(expectedFood));

      // act
      await usecase(ToggleFoodConsumedParams(food: detailedFood));

      // assert
      final captured = verify(
        () => mockRepository.updateFood(captureAny()),
      ).captured;
      final updatedFood = captured.first as Food;
      expect(updatedFood.id, detailedFood.id);
      expect(updatedFood.name, detailedFood.name);
      expect(updatedFood.category, detailedFood.category);
      expect(updatedFood.notes, detailedFood.notes);
      expect(updatedFood.expiryDate, detailedFood.expiryDate);
      expect(updatedFood.isShared, detailedFood.isShared);
      expect(updatedFood.isConsumed, true); // Only this changed
    });

    test('should return CacheFailure when repository fails', () async {
      // arrange
      when(() => mockRepository.updateFood(any())).thenAnswer(
        (_) async =>
            const Left(CacheFailure('Fehler beim Aktualisieren des Status')),
      );

      // act
      final result = await usecase(ToggleFoodConsumedParams(food: tFood));

      // assert
      expect(
        result,
        const Left(CacheFailure('Fehler beim Aktualisieren des Status')),
      );
      verify(() => mockRepository.updateFood(any())).called(1);
    });

    test('should handle food without expiry date', () async {
      // arrange
      final foodWithoutExpiry = Food(
        id: '3',
        name: 'No Expiry',
        addedDate: tDateTime,
        expiryDate: null,
        isConsumed: false,
      );
      final expectedFood = foodWithoutExpiry.copyWith(isConsumed: true);
      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(expectedFood));

      // act
      final result = await usecase(
        ToggleFoodConsumedParams(food: foodWithoutExpiry),
      );

      // assert
      expect(result, Right(expectedFood));
      final captured = verify(
        () => mockRepository.updateFood(captureAny()),
      ).captured;
      expect(captured.first.expiryDate, null);
      expect(captured.first.isConsumed, true);
    });

    test('should handle food without category', () async {
      // arrange
      final foodWithoutCategory = Food(
        id: '4',
        name: 'No Category',
        addedDate: tDateTime,
        category: null,
        isConsumed: false,
      );
      final expectedFood = foodWithoutCategory.copyWith(isConsumed: true);
      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(expectedFood));

      // act
      final result = await usecase(
        ToggleFoodConsumedParams(food: foodWithoutCategory),
      );

      // assert
      expect(result.isRight(), true);
      final captured = verify(
        () => mockRepository.updateFood(captureAny()),
      ).captured;
      expect(captured.first.category, null);
    });

    test('should call repository exactly once', () async {
      // arrange
      when(
        () => mockRepository.updateFood(any()),
      ).thenAnswer((_) async => Right(tFood.copyWith(isConsumed: true)));

      // act
      await usecase(ToggleFoodConsumedParams(food: tFood));

      // assert
      verify(() => mockRepository.updateFood(any())).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
