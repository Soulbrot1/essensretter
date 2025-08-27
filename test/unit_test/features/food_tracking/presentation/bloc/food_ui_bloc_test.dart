import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/add_food_from_text.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/parse_foods_from_text.dart';

import 'package:essensretter/features/food_tracking/presentation/bloc/food_ui_bloc.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_ui_event.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_ui_state.dart';

// Mock Classes
class MockAddFoodFromText extends Mock implements AddFoodFromText {}

class MockParseFoodsFromText extends Mock implements ParseFoodsFromText {}

// Fake Classes für Mocktail Fallback Values
class FakeAddFoodFromTextParams extends Fake implements AddFoodFromTextParams {}

class FakeParseFoodsFromTextParams extends Fake
    implements ParseFoodsFromTextParams {}

void main() {
  // Registriere Fallback-Werte für Mocktail
  setUpAll(() {
    registerFallbackValue(FakeAddFoodFromTextParams());
    registerFallbackValue(FakeParseFoodsFromTextParams());
  });

  group('FoodUIBloc Tests', () {
    late FoodUIBloc foodUIBloc;
    late MockAddFoodFromText mockAddFoodFromText;
    late MockParseFoodsFromText mockParseFoodsFromText;

    // Test Data - Use future dates to avoid conflicts with expiry tests
    final testFood1 = Food(
      id: '1',
      name: 'Salami',
      expiryDate: DateTime(2025, 12, 25),
      addedDate: DateTime(2025, 12, 20),
      category: 'Fleisch',
    );

    final testFood2 = Food(
      id: '2',
      name: 'Brot',
      expiryDate: DateTime(2025, 12, 22),
      addedDate: DateTime(2025, 12, 20),
      category: 'Getreide',
    );

    final testFoodList = [testFood1, testFood2];

    setUp(() {
      mockAddFoodFromText = MockAddFoodFromText();
      mockParseFoodsFromText = MockParseFoodsFromText();

      foodUIBloc = FoodUIBloc(
        addFoodFromText: mockAddFoodFromText,
        parseFoodsFromText: mockParseFoodsFromText,
      );
    });

    tearDown(() {
      foodUIBloc.close();
    });

    group('Initial State', () {
      test('sollte FoodUIInitial als Initial State haben', () {
        expect(foodUIBloc.state, equals(FoodUIInitial()));
      });
    });

    group('UpdateFoodListEvent', () {
      blocTest<FoodUIBloc, FoodUIState>(
        'sollte FoodUILoaded mit sortierten Lebensmitteln emittieren',
        build: () => foodUIBloc,
        act: (bloc) => bloc.add(UpdateFoodListEvent(testFoodList)),
        expect: () => [
          isA<FoodUILoaded>()
              .having((state) => state.allFoods.length, 'allFoods length', 2)
              .having(
                (state) => state.filteredFoods.length,
                'filteredFoods length',
                2,
              )
              .having(
                (state) => state.sortOption,
                'sortOption',
                SortOption.date,
              )
              // Nach Datum sortiert: Brot (22.12) vor Salami (25.12)
              .having(
                (state) => state.filteredFoods[0].name,
                'first food name',
                'Brot',
              )
              .having(
                (state) => state.filteredFoods[1].name,
                'second food name',
                'Salami',
              ),
        ],
      );

      blocTest<FoodUIBloc, FoodUIState>(
        'sollte bestehende Filter beibehalten bei Update',
        build: () => foodUIBloc,
        seed: () => FoodUILoaded(
          allFoods: [testFood1],
          filteredFoods: [testFood1],
          searchText: 'Salami',
        ),
        act: (bloc) => bloc.add(UpdateFoodListEvent([testFood1, testFood2])),
        expect: () => [
          isA<FoodUILoaded>()
              .having((state) => state.allFoods.length, 'allFoods length', 2)
              .having(
                (state) => state.filteredFoods.length,
                'filteredFoods length',
                1,
              ) // gefiltert
              .having((state) => state.searchText, 'searchText', 'Salami')
              .having(
                (state) => state.filteredFoods[0].name,
                'filtered food',
                'Salami',
              ),
        ],
      );
    });

    group('FilterFoodsByExpiryEvent', () {
      final expiredFood = Food(
        id: '3',
        name: 'Expired Food',
        expiryDate: DateTime(2024, 8, 22), // Fixed expired date
        addedDate: DateTime(2024, 8, 18), // Fixed added date
      );

      blocTest<FoodUIBloc, FoodUIState>(
        'sollte nur abgelaufene Lebensmittel filtern (daysUntilExpiry = 0)',
        build: () => foodUIBloc,
        seed: () => FoodUILoaded(
          allFoods: [expiredFood, testFood1],
          filteredFoods: [expiredFood, testFood1],
        ),
        act: (bloc) => bloc.add(const FilterFoodsByExpiryEvent(0)),
        expect: () => [
          isA<FoodUILoaded>()
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

      blocTest<FoodUIBloc, FoodUIState>(
        'sollte Filter entfernen wenn null übergeben wird',
        build: () => foodUIBloc,
        seed: () => FoodUILoaded(
          allFoods: [expiredFood, testFood1],
          filteredFoods: [expiredFood], // Gefiltert
          activeFilter: 0,
        ),
        act: (bloc) => bloc.add(const FilterFoodsByExpiryEvent(null)),
        expect: () => [
          isA<FoodUILoaded>()
              .having((state) => state.activeFilter, 'activeFilter', null)
              .having(
                (state) => state.filteredFoods.length,
                'filtered length',
                2,
              ), // Alle wieder sichtbar
        ],
      );
    });

    group('SearchFoodsByNameEvent', () {
      blocTest<FoodUIBloc, FoodUIState>(
        'sollte Lebensmittel nach Name filtern (case-insensitive)',
        build: () => foodUIBloc,
        seed: () =>
            FoodUILoaded(allFoods: testFoodList, filteredFoods: testFoodList),
        act: (bloc) => bloc.add(const SearchFoodsByNameEvent('salami')),
        expect: () => [
          isA<FoodUILoaded>()
              .having((state) => state.searchText, 'searchText', 'salami')
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
      blocTest<FoodUIBloc, FoodUIState>(
        'sollte Lebensmittel alphabetisch sortieren',
        build: () => foodUIBloc,
        seed: () => FoodUILoaded(
          allFoods: testFoodList, // [Salami, Brot]
          filteredFoods: testFoodList,
        ),
        act: (bloc) => bloc.add(const SortFoodsEvent(SortOption.alphabetical)),
        expect: () => [
          isA<FoodUILoaded>()
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
    });

    group('ShowFoodPreviewEvent', () {
      final previewFoods = [testFood1];

      blocTest<FoodUIBloc, FoodUIState>(
        'sollte FoodPreviewReady emittieren mit geparsten Lebensmitteln',
        build: () {
          when(
            () => mockParseFoodsFromText(any()),
          ).thenAnswer((_) async => Right(previewFoods));
          return foodUIBloc;
        },
        seed: () =>
            FoodUILoaded(allFoods: testFoodList, filteredFoods: testFoodList),
        act: (bloc) => bloc.add(const ShowFoodPreviewEvent('Salami 3 Tage')),
        expect: () => [
          isA<FoodPreviewReady>()
              .having(
                (state) => state.previewFoods.length,
                'preview foods length',
                1,
              )
              .having(
                (state) => state.previewFoods[0].name,
                'preview food name',
                'Salami',
              ),
        ],
        verify: (_) {
          verify(() => mockParseFoodsFromText(any())).called(1);
        },
      );

      blocTest<FoodUIBloc, FoodUIState>(
        'sollte FoodUIError emittieren wenn Parsen fehlschlägt',
        build: () {
          when(
            () => mockParseFoodsFromText(any()),
          ).thenAnswer((_) async => Left(ParsingFailure('Parse error')));
          return foodUIBloc;
        },
        seed: () =>
            FoodUILoaded(allFoods: testFoodList, filteredFoods: testFoodList),
        act: (bloc) => bloc.add(const ShowFoodPreviewEvent('invalid text')),
        expect: () => [
          isA<FoodUIError>().having(
            (state) => state.message,
            'error message',
            contains('Parse error'),
          ),
        ],
      );
    });

    group('HideFoodPreviewEvent', () {
      blocTest<FoodUIBloc, FoodUIState>(
        'sollte von FoodPreviewReady zu FoodUILoaded wechseln',
        build: () => foodUIBloc,
        seed: () => FoodPreviewReady(
          previewFoods: [testFood1],
          allFoods: testFoodList,
          filteredFoods: testFoodList,
        ),
        act: (bloc) => bloc.add(HideFoodPreviewEvent()),
        expect: () => [
          isA<FoodUILoaded>()
              .having((state) => state.allFoods.length, 'allFoods length', 2)
              .having(
                (state) => state.filteredFoods.length,
                'filteredFoods length',
                2,
              ),
        ],
      );
    });

    group('ResetFiltersEvent', () {
      blocTest<FoodUIBloc, FoodUIState>(
        'sollte alle Filter zurücksetzen und nach Datum sortieren',
        build: () => foodUIBloc,
        seed: () => FoodUILoaded(
          allFoods: testFoodList,
          filteredFoods: [testFood1], // Gefiltert
          activeFilter: 7,
          sortOption: SortOption.alphabetical,
          searchText: 'Salami',
        ),
        act: (bloc) => bloc.add(ResetFiltersEvent()),
        expect: () => [
          isA<FoodUILoaded>()
              .having((state) => state.activeFilter, 'activeFilter', null)
              .having(
                (state) => state.sortOption,
                'sortOption',
                SortOption.date,
              )
              .having((state) => state.searchText, 'searchText', '')
              .having(
                (state) => state.filteredFoods.length,
                'filteredFoods length',
                2,
              )
              // Nach Datum sortiert: Brot (22.12) vor Salami (25.12)
              .having(
                (state) => state.filteredFoods[0].name,
                'first food',
                'Brot',
              ),
        ],
      );
    });
  });
}
