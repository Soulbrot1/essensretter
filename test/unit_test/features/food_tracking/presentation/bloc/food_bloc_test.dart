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
import 'package:essensretter/features/food_tracking/domain/usecases/add_food_from_text.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/parse_foods_from_text.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/get_foods_by_expiry.dart';
import 'package:essensretter/features/recipes/domain/usecases/update_recipes_after_food_deletion.dart';
import 'package:essensretter/features/statistics/domain/repositories/statistics_repository.dart';

import 'package:essensretter/features/food_tracking/presentation/bloc/food_bloc.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_event.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_state.dart';

// Mock Classes für alle Dependencies
class MockGetAllFoods extends Mock implements GetAllFoods {}

class MockGetFoodsByExpiry extends Mock implements GetFoodsByExpiry {}

class MockAddFoodFromText extends Mock implements AddFoodFromText {}

class MockAddFoods extends Mock implements AddFoods {}

class MockParseFoodsFromText extends Mock implements ParseFoodsFromText {}

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

  group('FoodBloc Tests', () {
    // Dependencies
    late FoodBloc foodBloc;
    late MockGetAllFoods mockGetAllFoods;
    late MockGetFoodsByExpiry mockGetFoodsByExpiry;
    late MockAddFoodFromText mockAddFoodFromText;
    late MockAddFoods mockAddFoods;
    late MockParseFoodsFromText mockParseFoodsFromText;
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
      mockGetFoodsByExpiry = MockGetFoodsByExpiry();
      mockAddFoodFromText = MockAddFoodFromText();
      mockAddFoods = MockAddFoods();
      mockParseFoodsFromText = MockParseFoodsFromText();
      mockDeleteFood = MockDeleteFood();
      mockUpdateFood = MockUpdateFood();
      mockUpdateRecipesAfterFoodDeletion = MockUpdateRecipesAfterFoodDeletion();
      mockStatisticsRepository = MockStatisticsRepository();

      // Setup SharedPreferences Mock
      SharedPreferences.setMockInitialValues({});

      // FoodBloc erstellen
      foodBloc = FoodBloc(
        getAllFoods: mockGetAllFoods,
        getFoodsByExpiry: mockGetFoodsByExpiry,
        addFoodFromText: mockAddFoodFromText,
        addFoods: mockAddFoods,
        parseFoodsFromText: mockParseFoodsFromText,
        deleteFood: mockDeleteFood,
        updateFood: mockUpdateFood,
        updateRecipesAfterFoodDeletion: mockUpdateRecipesAfterFoodDeletion,
        statisticsRepository: mockStatisticsRepository,
      );
    });

    tearDown(() {
      foodBloc.close();
    });

    group('Initial State', () {
      test('sollte FoodInitial als Initial State haben', () {
        expect(foodBloc.state, equals(FoodInitial()));
      });
    });

    group('LoadFoodsEvent', () {
      blocTest<FoodBloc, FoodState>(
        'sollte FoodLoaded mit Lebensmitteln emittieren wenn erfolgreich',
        build: () {
          // Mock Setup: GetAllFoods gibt Success mit testFoodList zurück
          when(
            () => mockGetAllFoods(any()),
          ).thenAnswer((_) async => Right(testFoodList));
          return foodBloc;
        },
        act: (bloc) => bloc.add(LoadFoodsEvent()),
        expect: () => [
          FoodLoading(), // Erst Loading State
          isA<FoodLoaded>() // Dann FoodLoaded State
              .having((state) => state.foods.length, 'foods length', 2)
              .having(
                (state) => state.foods[0].name,
                'first food name',
                'Brot', // Brot kommt zuerst, da nach Datum sortiert und früher abläuft
              )
              .having(
                (state) => state.foods[1].name,
                'second food name',
                'Salami',
              ),
        ],
      );

      blocTest<FoodBloc, FoodState>(
        'sollte FoodError emittieren wenn GetAllFoods fehlschlägt',
        build: () {
          // Mock Setup: GetAllFoods gibt Failure zurück
          when(
            () => mockGetAllFoods(any()),
          ).thenAnswer((_) async => Left(ServerFailure('Server error')));
          return foodBloc;
        },
        act: (bloc) => bloc.add(LoadFoodsEvent()),
        expect: () => [
          FoodLoading(),
          isA<FoodError>().having(
            (state) => state.message,
            'error message',
            'Server error', // Direkt die Fehlermeldung ohne Übersetzung
          ),
        ],
      );

      blocTest<FoodBloc, FoodState>(
        'sollte leere FoodLoaded emittieren wenn keine Lebensmittel vorhanden',
        setUp: () {
          // Setup SharedPreferences Mock - Demo-Foods wurden bereits geladen
          SharedPreferences.setMockInitialValues({'demo_foods_loaded': true});
        },
        build: () {
          // Mock Setup: GetAllFoods gibt leere Liste zurück
          when(
            () => mockGetAllFoods(any()),
          ).thenAnswer((_) async => const Right([]));
          return foodBloc;
        },
        act: (bloc) => bloc.add(LoadFoodsEvent()),
        expect: () => [
          FoodLoading(),
          isA<FoodLoaded>()
              .having((state) => state.foods.length, 'foods length', 0)
              .having(
                (state) => state.filteredFoods.length,
                'filtered foods length',
                0,
              ),
        ],
      );
    });

    group('ConfirmFoodsEvent', () {
      blocTest<FoodBloc, FoodState>(
        'sollte Lebensmittel erfolgreich hinzufügen und LoadFoodsEvent triggern',
        build: () {
          // Setup: AddFoods ist erfolgreich
          when(
            () => mockAddFoods(any()),
          ).thenAnswer((_) async => const Right(null));
          // Setup: Nach dem Hinzufügen wird LoadFoodsEvent getriggert
          when(
            () => mockGetAllFoods(any()),
          ).thenAnswer((_) async => Right([testFood1]));
          return foodBloc;
        },
        // Seed mit FoodPreviewReady state (ConfirmFoodsEvent erwartet diesen State)
        seed: () => FoodPreviewReady(
          previewFoods: [testFood1],
          foods: [],
          filteredFoods: [],
        ),
        act: (bloc) => bloc.add(ConfirmFoodsEvent([testFood1])),
        expect: () => [
          isA<FoodOperationInProgress>(),
          FoodLoading(),
          isA<FoodLoaded>()
              .having((state) => state.foods.length, 'foods length', 1)
              .having((state) => state.foods[0].name, 'food name', 'Salami'),
        ],
      );

      blocTest<FoodBloc, FoodState>(
        'sollte FoodError emittieren wenn AddFoods fehlschlägt',
        build: () {
          when(
            () => mockAddFoods(any()),
          ).thenAnswer((_) async => Left(CacheFailure('Database error')));
          return foodBloc;
        },
        // Seed mit FoodPreviewReady state (ConfirmFoodsEvent erwartet diesen State)
        seed: () => FoodPreviewReady(
          previewFoods: [testFood1],
          foods: [],
          filteredFoods: [],
        ),
        act: (bloc) => bloc.add(ConfirmFoodsEvent([testFood1])),
        expect: () => [
          isA<FoodOperationInProgress>(),
          isA<FoodError>().having(
            (state) => state.message,
            'error message',
            'Database error', // Direkt die Fehlermeldung
          ),
          // Nach 2 Sekunden wird der vorherige State wiederhergestellt
          isA<FoodLoaded>(),
        ],
        wait: const Duration(seconds: 3), // Warten auf Delay
      );
    });

    group('DeleteFoodEvent', () {
      blocTest<FoodBloc, FoodState>(
        'sollte Lebensmittel löschen und Statistik aufzeichnen',
        build: () {
          // Initial state mit einem Lebensmittel
          when(
            () => mockGetAllFoods(any()),
          ).thenAnswer((_) async => Right([testFood1]));
          when(
            () => mockDeleteFood(any()),
          ).thenAnswer((_) async => const Right(null));
          when(
            () =>
                mockStatisticsRepository.recordWastedFood(any(), any(), any()),
          ).thenAnswer((_) async {});
          return foodBloc;
        },
        seed: () => FoodLoaded(foods: [testFood1], filteredFoods: [testFood1]),
        act: (bloc) => bloc.add(DeleteFoodEvent('1', wasDisposed: true)),
        expect: () => [
          isA<FoodOperationInProgress>(), // Erst OperationInProgress
          FoodLoading(), // Dann Loading von LoadFoodsEvent
          isA<FoodLoaded>().having(
            (state) => state.foods.length,
            'foods length',
            1, // Nach dem Mock sollte noch 1 Food da sein
          ),
        ],
        verify: (_) {
          verify(() => mockDeleteFood(any())).called(1);
          verify(
            () =>
                mockStatisticsRepository.recordWastedFood(any(), any(), any()),
          ).called(1);
        },
      );
    });

    group('ToggleConsumedEvent', () {
      blocTest<FoodBloc, FoodState>(
        'sollte isConsumed Status umschalten',
        build: () {
          final updatedFood = testFood1.copyWith(isConsumed: true);
          when(
            () => mockUpdateFood(any()),
          ).thenAnswer((_) async => Right(updatedFood));
          when(
            () => mockUpdateRecipesAfterFoodDeletion(any()),
          ).thenAnswer((_) async => const Right(null));
          when(
            () => mockStatisticsRepository.recordConsumedFood(
              any(),
              any(),
              any(),
            ),
          ).thenAnswer((_) async {});
          return foodBloc;
        },
        seed: () => FoodLoaded(foods: [testFood1], filteredFoods: [testFood1]),
        act: (bloc) => bloc.add(ToggleConsumedEvent('1')),
        expect: () => [
          isA<FoodLoaded>().having(
            (state) => state.foods[0].isConsumed,
            'isConsumed',
            true,
          ),
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

    group('FilterFoodsByExpiryEvent', () {
      final expiredFood = Food(
        id: '3',
        name: 'Expired Food',
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        addedDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      final freshFood = Food(
        id: '4',
        name: 'Fresh Food',
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        addedDate: DateTime.now(),
      );

      blocTest<FoodBloc, FoodState>(
        'sollte nur abgelaufene Lebensmittel filtern (daysUntilExpiry = 0)',
        build: () => foodBloc,
        seed: () => FoodLoaded(
          foods: [expiredFood, freshFood],
          filteredFoods: [expiredFood, freshFood],
        ),
        act: (bloc) => bloc.add(const FilterFoodsByExpiryEvent(0)),
        expect: () => [
          isA<FoodLoaded>()
              .having((state) => state.activeFilter, 'activeFilter', 0)
              .having(
                (state) => state.filteredFoods.length,
                'filtered length',
                1,
              )
              .having(
                (state) => state.filteredFoods[0].name,
                'filtered food name',
                'Expired Food',
              ),
        ],
      );

      blocTest<FoodBloc, FoodState>(
        'sollte alle Lebensmittel zeigen wenn Filter aufgehoben wird (null)',
        build: () => foodBloc,
        seed: () => FoodLoaded(
          foods: [expiredFood, freshFood],
          filteredFoods: [expiredFood], // Aktuell gefiltert
          activeFilter: 0,
        ),
        act: (bloc) => bloc.add(const FilterFoodsByExpiryEvent(null)),
        expect: () => [
          isA<FoodLoaded>()
              .having((state) => state.activeFilter, 'activeFilter', null)
              .having(
                (state) => state.filteredFoods.length,
                'filtered length',
                2,
              ),
        ],
      );
    });

    group('SearchFoodsByNameEvent', () {
      blocTest<FoodBloc, FoodState>(
        'sollte Lebensmittel nach Name filtern',
        build: () => foodBloc,
        seed: () =>
            FoodLoaded(foods: testFoodList, filteredFoods: testFoodList),
        act: (bloc) => bloc.add(const SearchFoodsByNameEvent('Salami')),
        expect: () => [
          isA<FoodLoaded>()
              .having((state) => state.searchText, 'searchText', 'Salami')
              .having(
                (state) => state.filteredFoods.length,
                'filtered length',
                1,
              )
              .having(
                (state) => state.filteredFoods[0].name,
                'filtered food name',
                'Salami',
              ),
        ],
      );

      blocTest<FoodBloc, FoodState>(
        'sollte case-insensitive suchen',
        build: () => foodBloc,
        seed: () =>
            FoodLoaded(foods: testFoodList, filteredFoods: testFoodList),
        act: (bloc) => bloc.add(const SearchFoodsByNameEvent('salami')),
        expect: () => [
          isA<FoodLoaded>()
              .having(
                (state) => state.filteredFoods.length,
                'filtered length',
                1,
              )
              .having(
                (state) => state.filteredFoods[0].name,
                'filtered food name',
                'Salami',
              ),
        ],
      );
    });

    group('SortFoodsEvent', () {
      blocTest<FoodBloc, FoodState>(
        'sollte Lebensmittel alphabetisch sortieren',
        build: () => foodBloc,
        seed: () => FoodLoaded(
          foods: testFoodList, // [Salami, Brot]
          filteredFoods: testFoodList,
        ),
        act: (bloc) => bloc.add(const SortFoodsEvent(SortOption.alphabetical)),
        expect: () => [
          isA<FoodLoaded>()
              .having(
                (state) => state.sortOption,
                'sortOption',
                SortOption.alphabetical,
              )
              .having(
                (state) => state.filteredFoods[0].name,
                'first food',
                'Brot',
              ) // B vor S
              .having(
                (state) => state.filteredFoods[1].name,
                'second food',
                'Salami',
              ),
        ],
      );

      blocTest<FoodBloc, FoodState>(
        'sollte Lebensmittel nach Verfallsdatum sortieren',
        build: () => foodBloc,
        seed: () => FoodLoaded(
          foods: testFoodList, // Salami: 25.12, Brot: 22.12
          filteredFoods: testFoodList,
        ),
        act: (bloc) => bloc.add(const SortFoodsEvent(SortOption.date)),
        expect: () => [
          isA<FoodLoaded>()
              .having(
                (state) => state.sortOption,
                'sortOption',
                SortOption.date,
              )
              .having(
                (state) => state.filteredFoods[0].name,
                'first food',
                'Brot',
              ) // 22.12 vor 25.12
              .having(
                (state) => state.filteredFoods[1].name,
                'second food',
                'Salami',
              ),
        ],
      );
    });
  });
}
