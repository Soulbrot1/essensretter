import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/domain/repositories/food_repository.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/delete_food.dart';
import 'package:essensretter/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:essensretter/features/recipes/domain/usecases/update_recipes_after_food_deletion.dart';

class MockFoodRepository extends Mock implements FoodRepository {}

class MockStatisticsRepository extends Mock implements StatisticsRepository {}

class MockUpdateRecipesAfterFoodDeletion extends Mock
    implements UpdateRecipesAfterFoodDeletion {}

class FakeUpdateRecipesParams extends Fake implements UpdateRecipesParams {}

void main() {
  late DeleteFood deleteFood;
  late MockFoodRepository mockFoodRepository;
  late MockStatisticsRepository mockStatisticsRepository;
  late MockUpdateRecipesAfterFoodDeletion mockUpdateRecipes;

  setUpAll(() {
    registerFallbackValue(FakeUpdateRecipesParams());
  });

  setUp(() {
    mockFoodRepository = MockFoodRepository();
    mockStatisticsRepository = MockStatisticsRepository();
    mockUpdateRecipes = MockUpdateRecipesAfterFoodDeletion();
    deleteFood = DeleteFood(
      foodRepository: mockFoodRepository,
      statisticsRepository: mockStatisticsRepository,
      updateRecipesAfterFoodDeletion: mockUpdateRecipes,
    );
  });

  group('DeleteFood', () {
    const testId = 'test-food-id-123';
    final testFood = Food(
      id: testId,
      name: 'Test Food',
      expiryDate: DateTime.now().add(const Duration(days: 3)),
      addedDate: DateTime.now(),
      category: 'Test Category',
    );

    test(
      'sollte Food erfolgreich löschen und Statistik/Rezepte aktualisieren',
      () async {
        // arrange
        when(
          () => mockFoodRepository.getFoodById(any()),
        ).thenAnswer((_) async => Right(testFood));
        when(
          () => mockFoodRepository.deleteFood(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockStatisticsRepository.recordWastedFood(any(), any(), any()),
        ).thenAnswer((_) async => Future.value());
        when(
          () => mockUpdateRecipes(any()),
        ).thenAnswer((_) async => const Right(null));

        // act
        final result = await deleteFood(DeleteFoodParams(id: testId));

        // assert
        expect(result, const Right<Failure, void>(null));
        verify(() => mockFoodRepository.getFoodById(testId)).called(1);
        verify(() => mockFoodRepository.deleteFood(testId)).called(1);
        verify(
          () => mockStatisticsRepository.recordWastedFood(
            testId,
            'Test Food',
            'Test Category',
          ),
        ).called(1);
        verify(() => mockUpdateRecipes(any())).called(1);
      },
    );

    test(
      'sollte CacheFailure zurückgeben wenn getFoodById fehlschlägt',
      () async {
        // arrange
        when(() => mockFoodRepository.getFoodById(any())).thenAnswer(
          (_) async => const Left(CacheFailure('Food nicht gefunden')),
        );

        // act
        final result = await deleteFood(DeleteFoodParams(id: testId));

        // assert
        expect(
          result,
          const Left<Failure, void>(CacheFailure('Food nicht gefunden')),
        );
        verify(() => mockFoodRepository.getFoodById(testId)).called(1);
        verifyNever(() => mockFoodRepository.deleteFood(any()));
      },
    );

    test(
      'sollte Food löschen auch wenn Statistik-Update fehlschlägt',
      () async {
        // arrange
        when(
          () => mockFoodRepository.getFoodById(any()),
        ).thenAnswer((_) async => Right(testFood));
        when(
          () => mockFoodRepository.deleteFood(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockStatisticsRepository.recordWastedFood(any(), any(), any()),
        ).thenThrow(Exception('Statistics error'));
        when(
          () => mockUpdateRecipes(any()),
        ).thenAnswer((_) async => const Right(null));

        // act
        final result = await deleteFood(DeleteFoodParams(id: testId));

        // assert
        expect(result, const Right<Failure, void>(null));
        verify(() => mockFoodRepository.deleteFood(testId)).called(1);
      },
    );

    test('sollte Food löschen auch wenn Recipe-Update fehlschlägt', () async {
      // arrange
      when(
        () => mockFoodRepository.getFoodById(any()),
      ).thenAnswer((_) async => Right(testFood));
      when(
        () => mockFoodRepository.deleteFood(any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockStatisticsRepository.recordWastedFood(any(), any(), any()),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockUpdateRecipes(any()),
      ).thenThrow(Exception('Recipe update error'));

      // act
      final result = await deleteFood(DeleteFoodParams(id: testId));

      // assert
      expect(result, const Right(null));
      verify(() => mockFoodRepository.deleteFood(testId)).called(1);
    });

    test(
      'sollte CacheFailure zurückgeben wenn deleteFood fehlschlägt',
      () async {
        // arrange
        when(
          () => mockFoodRepository.getFoodById(any()),
        ).thenAnswer((_) async => Right(testFood));
        when(() => mockFoodRepository.deleteFood(any())).thenAnswer(
          (_) async => const Left(CacheFailure('Löschvorgang fehlgeschlagen')),
        );
        when(
          () => mockStatisticsRepository.recordWastedFood(any(), any(), any()),
        ).thenAnswer((_) async => Future.value());
        when(
          () => mockUpdateRecipes(any()),
        ).thenAnswer((_) async => const Right(null));

        // act
        final result = await deleteFood(DeleteFoodParams(id: testId));

        // assert
        expect(
          result,
          const Left<Failure, void>(
            CacheFailure('Löschvorgang fehlgeschlagen'),
          ),
        );
        verify(() => mockFoodRepository.deleteFood(testId)).called(1);
      },
    );
  });
}
