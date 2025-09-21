import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/core/usecases/usecase.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/get_all_foods.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/add_foods.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/delete_food.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/update_food.dart';
import 'package:essensretter/features/recipes/domain/usecases/update_recipes_after_food_deletion.dart';
import 'package:essensretter/features/statistics/domain/repositories/statistics_repository.dart';

import 'package:essensretter/features/food_tracking/presentation/bloc/food_data_bloc.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_data_event.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_data_state.dart';

// Mock Classes
class MockGetAllFoods extends Mock implements GetAllFoods {}

class MockAddFoods extends Mock implements AddFoods {}

class MockDeleteFood extends Mock implements DeleteFood {}

class MockUpdateFood extends Mock implements UpdateFood {}

class MockUpdateRecipesAfterFoodDeletion extends Mock
    implements UpdateRecipesAfterFoodDeletion {}

class MockStatisticsRepository extends Mock implements StatisticsRepository {}

// Fake Classes für Mocktail Fallback Values
class FakeFood extends Fake implements Food {}

class FakeNoParams extends Fake implements NoParams {}

class FakeAddFoodsParams extends Fake implements AddFoodsParams {}

class FakeDeleteFoodParams extends Fake implements DeleteFoodParams {}

class FakeUpdateRecipesParams extends Fake implements UpdateRecipesParams {}

void main() {
  // Registriere Fallback-Werte für Mocktail
  setUpAll(() {
    registerFallbackValue(FakeFood());
    registerFallbackValue(FakeNoParams());
    registerFallbackValue(FakeAddFoodsParams());
    registerFallbackValue(FakeDeleteFoodParams());
    registerFallbackValue(FakeUpdateRecipesParams());
  });

  group('FoodDataBloc Tests', () {
    late FoodDataBloc foodDataBloc;
    late MockGetAllFoods mockGetAllFoods;
    late MockAddFoods mockAddFoods;
    late MockDeleteFood mockDeleteFood;
    late MockUpdateFood mockUpdateFood;
    late MockUpdateRecipesAfterFoodDeletion mockUpdateRecipesAfterFoodDeletion;
    late MockStatisticsRepository mockStatisticsRepository;

    // Test Data
    final testFood1 = Food(
      id: '1',
      name: 'Salami',
      expiryDate: DateTime(2024, 12, 25),
      addedDate: DateTime(2024, 12, 20),
      category: 'Fleisch',
    );

    final testFood2 = Food(
      id: '2',
      name: 'Brot',
      expiryDate: DateTime(2024, 12, 22),
      addedDate: DateTime(2024, 12, 20),
      category: 'Getreide',
    );

    final testFoodList = [testFood1, testFood2];

    setUp(() {
      // Setup alle Mocks
      mockGetAllFoods = MockGetAllFoods();
      mockAddFoods = MockAddFoods();
      mockDeleteFood = MockDeleteFood();
      mockUpdateFood = MockUpdateFood();
      mockUpdateRecipesAfterFoodDeletion = MockUpdateRecipesAfterFoodDeletion();
      mockStatisticsRepository = MockStatisticsRepository();

      // Setup SharedPreferences Mock
      SharedPreferences.setMockInitialValues({});

      // FoodDataBloc erstellen
      foodDataBloc = FoodDataBloc(
        getAllFoods: mockGetAllFoods,
        addFoods: mockAddFoods,
        deleteFood: mockDeleteFood,
        updateFood: mockUpdateFood,
        updateRecipesAfterFoodDeletion: mockUpdateRecipesAfterFoodDeletion,
        statisticsRepository: mockStatisticsRepository,
      );
    });

    tearDown(() {
      foodDataBloc.close();
    });

    group('Initial State', () {
      test('sollte FoodDataInitial als Initial State haben', () {
        expect(foodDataBloc.state, equals(FoodDataInitial()));
      });
    });

    group('LoadFoodsEvent', () {
      blocTest<FoodDataBloc, FoodDataState>(
        'sollte FoodDataLoaded mit Lebensmitteln emittieren wenn erfolgreich',
        build: () {
          when(
            () => mockGetAllFoods(any()),
          ).thenAnswer((_) async => Right(testFoodList));
          return foodDataBloc;
        },
        act: (bloc) => bloc.add(LoadFoodsEvent()),
        expect: () => [FoodDataLoading(), FoodDataLoaded(testFoodList)],
        verify: (_) {
          verify(() => mockGetAllFoods(any())).called(1);
        },
      );

      blocTest<FoodDataBloc, FoodDataState>(
        'sollte FoodDataError emittieren wenn GetAllFoods fehlschlägt',
        build: () {
          when(
            () => mockGetAllFoods(any()),
          ).thenAnswer((_) async => Left(ServerFailure('Server error')));
          return foodDataBloc;
        },
        act: (bloc) => bloc.add(LoadFoodsEvent()),
        expect: () => [FoodDataLoading(), FoodDataError('Server error')],
      );
    });

    group('ConfirmFoodsEvent', () {
      blocTest<FoodDataBloc, FoodDataState>(
        'sollte Lebensmittel erfolgreich hinzufügen',
        build: () {
          when(
            () => mockAddFoods(any()),
          ).thenAnswer((_) async => const Right(null));
          when(
            () => mockGetAllFoods(any()),
          ).thenAnswer((_) async => Right([testFood1]));
          return foodDataBloc;
        },
        act: (bloc) => bloc.add(ConfirmFoodsEvent([testFood1])),
        expect: () => [
          FoodDataLoading(),
          FoodDataLoaded([testFood1]),
        ],
        verify: (_) {
          verify(() => mockAddFoods(any())).called(1);
          verify(() => mockGetAllFoods(any())).called(1);
        },
      );
    });

    group('ToggleConsumedEvent', () {
      blocTest<FoodDataBloc, FoodDataState>(
        'sollte isConsumed Status umschalten',
        build: () {
          final updatedFood = testFood1.copyWith(isConsumed: true);
          when(
            () => mockUpdateFood(any()),
          ).thenAnswer((_) async => Right(updatedFood));
          when(
            () => mockStatisticsRepository.recordConsumedFood(
              any(),
              any(),
              any(),
            ),
          ).thenAnswer((_) async {});
          return foodDataBloc;
        },
        seed: () => FoodDataLoaded([testFood1]),
        act: (bloc) => bloc.add(ToggleConsumedEvent('1')),
        expect: () => [
          FoodDataLoaded([testFood1.copyWith(isConsumed: true)]),
        ],
        verify: (_) {
          verify(() => mockUpdateFood(any())).called(1);
          verify(
            () => mockStatisticsRepository.recordConsumedFood(
              any(),
              any(),
              any(),
            ),
          ).called(1);
        },
      );
    });

    group('DeleteFoodEvent', () {
      blocTest<FoodDataBloc, FoodDataState>(
        'sollte Lebensmittel löschen mit Statistik-Aufzeichnung',
        build: () {
          when(
            () => mockDeleteFood(any()),
          ).thenAnswer((_) async => const Right(null));
          when(
            () => mockUpdateRecipesAfterFoodDeletion(any()),
          ).thenAnswer((_) async => const Right(null));
          when(
            () =>
                mockStatisticsRepository.recordWastedFood(any(), any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockGetAllFoods(any()),
          ).thenAnswer((_) async => const Right([]));
          return foodDataBloc;
        },
        seed: () => FoodDataLoaded([testFood1]),
        act: (bloc) => bloc.add(DeleteFoodEvent('1', wasDisposed: true)),
        expect: () => [
          FoodDataOperationInProgress([testFood1]),
          FoodDataLoading(), // From LoadFoodsEvent triggered after delete
          const FoodDataLoaded([]),
        ],
      );
    });
  });
}
