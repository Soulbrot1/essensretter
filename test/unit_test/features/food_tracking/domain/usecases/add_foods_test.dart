import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/domain/repositories/food_repository.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/add_foods.dart';

class MockFoodRepository extends Mock implements FoodRepository {}

void main() {
  late AddFoods usecase;
  late MockFoodRepository mockFoodRepository;

  setUp(() {
    mockFoodRepository = MockFoodRepository();
    usecase = AddFoods(mockFoodRepository);
    registerFallbackValue(
      Food(
        id: 'fallback',
        name: 'fallback',
        expiryDate: DateTime.now(),
        addedDate: DateTime.now(),
      ),
    );
  });

  group('AddFoods', () {
    final tFood1 = Food(
      id: '1',
      name: 'Milch',
      expiryDate: DateTime.now().add(const Duration(days: 2)),
      addedDate: DateTime.now(),
    );

    final tFood2 = Food(
      id: '2',
      name: 'Brot',
      expiryDate: DateTime.now().add(const Duration(days: 1)),
      addedDate: DateTime.now(),
    );

    final tFoodList = [tFood1, tFood2];
    final tParams = AddFoodsParams(foods: tFoodList);

    test('should add all foods successfully', () async {
      // arrange
      when(() => mockFoodRepository.addFood(any())).thenAnswer(
        (invocation) async => Right(invocation.positionalArguments[0] as Food),
      );

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Right(null));
      verify(() => mockFoodRepository.addFood(tFood1)).called(1);
      verify(() => mockFoodRepository.addFood(tFood2)).called(1);
      verifyNoMoreInteractions(mockFoodRepository);
    });

    test('should return failure when first food fails to add', () async {
      // arrange
      const tFailure = CacheFailure('Failed to add food');
      when(
        () => mockFoodRepository.addFood(tFood1),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockFoodRepository.addFood(tFood1)).called(1);
      verifyNever(() => mockFoodRepository.addFood(tFood2));
    });

    test('should return failure when second food fails to add', () async {
      // arrange
      const tFailure = CacheFailure('Failed to add food');
      when(
        () => mockFoodRepository.addFood(tFood1),
      ).thenAnswer((_) async => Right(tFood1));
      when(
        () => mockFoodRepository.addFood(tFood2),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockFoodRepository.addFood(tFood1)).called(1);
      verify(() => mockFoodRepository.addFood(tFood2)).called(1);
    });

    test('should handle empty food list', () async {
      // arrange
      final emptyParams = AddFoodsParams(foods: []);

      // act
      final result = await usecase(emptyParams);

      // assert
      expect(result, const Right(null));
      verifyNever(() => mockFoodRepository.addFood(any()));
    });

    test('should return cache failure on exception', () async {
      // arrange
      when(
        () => mockFoodRepository.addFood(any()),
      ).thenThrow(Exception('Database error'));

      // act
      final result = await usecase(tParams);

      // assert
      expect(
        result,
        const Left(CacheFailure('Fehler beim Speichern der Lebensmittel')),
      );
      verify(() => mockFoodRepository.addFood(tFood1)).called(1);
    });
  });
}
