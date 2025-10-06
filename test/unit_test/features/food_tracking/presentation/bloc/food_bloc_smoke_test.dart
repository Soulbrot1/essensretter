import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/core/usecases/usecase.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/add_food_from_text.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/add_foods.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/delete_food.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/get_all_foods.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/get_foods_by_expiry.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/parse_foods_from_text.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/update_food.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_bloc.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_event.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_state.dart';
import 'package:essensretter/features/recipes/domain/usecases/update_recipes_after_food_deletion.dart';
import 'package:essensretter/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
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

// Fake für mocktail
class FakeNoParams extends Fake implements NoParams {}

/// Smoke Tests für FoodBloc
///
/// Diese Tests prüfen nur das absolute Minimum:
/// - Kann der BLoC ohne Crash erstellt werden?
/// - Funktionieren die grundlegendsten Events?
/// - Kein Crash bei kritischen Operationen?
///
/// NICHT getestet (absichtlich):
/// - Detaillierte Business Logic (dafür gibt es die normalen BLoC Tests)
/// - Edge Cases
/// - Komplexe State-Transitions
///
/// Zweck: Schutz vor Refactoring-Fehlern, die zu Crashes führen
void main() {
  late FoodBloc bloc;
  late MockGetAllFoods mockGetAllFoods;
  late MockGetFoodsByExpiry mockGetFoodsByExpiry;
  late MockAddFoodFromText mockAddFoodFromText;
  late MockAddFoods mockAddFoods;
  late MockParseFoodsFromText mockParseFoodsFromText;
  late MockDeleteFood mockDeleteFood;
  late MockUpdateFood mockUpdateFood;
  late MockUpdateRecipesAfterFoodDeletion mockUpdateRecipesAfterFoodDeletion;
  late MockStatisticsRepository mockStatisticsRepository;

  setUpAll(() {
    registerFallbackValue(FakeNoParams());
  });

  setUp(() {
    mockGetAllFoods = MockGetAllFoods();
    mockGetFoodsByExpiry = MockGetFoodsByExpiry();
    mockAddFoodFromText = MockAddFoodFromText();
    mockAddFoods = MockAddFoods();
    mockParseFoodsFromText = MockParseFoodsFromText();
    mockDeleteFood = MockDeleteFood();
    mockUpdateFood = MockUpdateFood();
    mockUpdateRecipesAfterFoodDeletion = MockUpdateRecipesAfterFoodDeletion();
    mockStatisticsRepository = MockStatisticsRepository();

    // Default-Mocks, damit nichts crasht
    when(
      () => mockGetAllFoods(any()),
    ).thenAnswer((_) async => const Right(<Food>[]));
    when(
      () => mockStatisticsRepository.recordConsumedFood(any(), any(), any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockStatisticsRepository.recordWastedFood(any(), any(), any()),
    ).thenAnswer((_) async => const Right(null));

    bloc = FoodBloc(
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
    bloc.close();
  });

  group('FoodBloc Smoke Tests', () {
    test('kann ohne Crash erstellt werden', () {
      // Wenn wir hier ankommen, ist kein Crash passiert ✅
      expect(bloc, isNotNull);
      expect(bloc.state, equals(FoodInitial()));
    });

    blocTest<FoodBloc, FoodState>(
      'LoadFoodsEvent verarbeiten ohne Crash',
      build: () {
        when(
          () => mockGetAllFoods(NoParams()),
        ).thenAnswer((_) async => const Right(<Food>[]));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadFoodsEvent()),
      expect: () => [
        FoodLoading(),
        FoodLoaded(
          foods: const [],
          filteredFoods: const [],
          sortOption: SortOption.date,
        ),
      ],
    );

    blocTest<FoodBloc, FoodState>(
      'LoadFoodsEvent mit Fehler crasht nicht',
      build: () {
        when(
          () => mockGetAllFoods(NoParams()),
        ).thenAnswer((_) async => const Left(CacheFailure('Test error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadFoodsEvent()),
      expect: () => [FoodLoading(), const FoodError('Test error')],
    );

    blocTest<FoodBloc, FoodState>(
      'FilterFoodsByExpiryEvent crasht nicht',
      build: () {
        when(() => mockGetAllFoods(NoParams())).thenAnswer(
          (_) async => Right([
            Food(
              id: '1',
              name: 'Test',
              expiryDate: DateTime.now().add(const Duration(days: 1)),
              addedDate: DateTime.now(),
            ),
          ]),
        );
        return bloc;
      },
      act: (bloc) {
        bloc.add(const LoadFoodsEvent());
        return bloc.stream.first.then(
          (_) => bloc.add(const FilterFoodsByExpiryEvent(7)),
        );
      },
      skip: 2, // Skip Loading + Initial FoodLoaded
      expect: () => [
        isA<FoodLoaded>(), // Filter angewendet
      ],
    );

    blocTest<FoodBloc, FoodState>(
      'SortFoodsEvent crasht nicht',
      build: () {
        when(() => mockGetAllFoods(NoParams())).thenAnswer(
          (_) async => Right([
            Food(
              id: '1',
              name: 'Banane',
              expiryDate: DateTime.now(),
              addedDate: DateTime.now(),
            ),
            Food(
              id: '2',
              name: 'Apfel',
              expiryDate: DateTime.now(),
              addedDate: DateTime.now(),
            ),
          ]),
        );
        return bloc;
      },
      act: (bloc) {
        bloc.add(const LoadFoodsEvent());
        return bloc.stream.first.then(
          (_) => bloc.add(const SortFoodsEvent(SortOption.alphabetical)),
        );
      },
      skip: 2, // Skip Loading + Initial FoodLoaded
      expect: () => [
        isA<FoodLoaded>(), // Sortiert
      ],
    );
  });
}
