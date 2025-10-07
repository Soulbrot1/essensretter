import 'package:flutter_test/flutter_test.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_event.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_sorting_helper.dart';

void main() {
  group('FoodSortingHelper', () {
    late List<Food> testFoods;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      testFoods = [
        Food(
          id: '1',
          name: 'Zitrone',
          addedDate: now,
          expiryDate: now.add(const Duration(days: 3)),
          category: 'Obst',
          isShared: false,
        ),
        Food(
          id: '2',
          name: 'Apfel',
          addedDate: now,
          expiryDate: now.add(const Duration(days: 7)),
          category: 'Obst',
          isShared: true,
        ),
        Food(
          id: '3',
          name: 'Banane',
          addedDate: now,
          expiryDate: now.add(const Duration(days: 1)),
          category: 'Gemüse',
          isShared: false,
        ),
        Food(
          id: '4',
          name: 'Milch',
          addedDate: now,
          expiryDate: null,
          category: 'Milchprodukte',
          isShared: true,
        ),
      ];
    });

    group('sortFoods with SortOption.alphabetical', () {
      test('sorts foods alphabetically by name', () {
        final result = FoodSortingHelper.sortFoods(
          testFoods,
          SortOption.alphabetical,
        );

        expect(result[0].name, 'Apfel');
        expect(result[1].name, 'Banane');
        expect(result[2].name, 'Milch');
        expect(result[3].name, 'Zitrone');
      });

      test('is case-insensitive', () {
        final mixedCaseFoods = [
          Food(id: '1', name: 'zebra', addedDate: now),
          Food(id: '2', name: 'Affe', addedDate: now),
          Food(id: '3', name: 'BANANE', addedDate: now),
        ];

        final result = FoodSortingHelper.sortFoods(
          mixedCaseFoods,
          SortOption.alphabetical,
        );

        expect(result[0].name, 'Affe');
        expect(result[1].name, 'BANANE');
        expect(result[2].name, 'zebra');
      });

      test('does not modify original list', () {
        final original = List.from(testFoods);
        FoodSortingHelper.sortFoods(testFoods, SortOption.alphabetical);

        expect(testFoods, equals(original));
      });
    });

    group('sortFoods with SortOption.date', () {
      test('sorts foods by expiry date (earliest first)', () {
        final result = FoodSortingHelper.sortFoods(testFoods, SortOption.date);

        expect(result[0].name, 'Banane'); // 1 day
        expect(result[1].name, 'Zitrone'); // 3 days
        expect(result[2].name, 'Apfel'); // 7 days
        expect(result[3].name, 'Milch'); // null (goes last)
      });

      test('puts foods without expiry date at the end', () {
        final foodsWithoutDates = [
          Food(id: '1', name: 'A', addedDate: now, expiryDate: null),
          Food(
            id: '2',
            name: 'B',
            addedDate: now,
            expiryDate: now.add(const Duration(days: 5)),
          ),
          Food(id: '3', name: 'C', addedDate: now, expiryDate: null),
        ];

        final result = FoodSortingHelper.sortFoods(
          foodsWithoutDates,
          SortOption.date,
        );

        expect(result[0].name, 'B');
        expect(result[1].name, 'A');
        expect(result[2].name, 'C');
      });

      test('handles all foods without expiry dates', () {
        final noDateFoods = [
          Food(id: '1', name: 'A', addedDate: now, expiryDate: null),
          Food(id: '2', name: 'B', addedDate: now, expiryDate: null),
        ];

        final result = FoodSortingHelper.sortFoods(
          noDateFoods,
          SortOption.date,
        );

        expect(result.length, 2);
        // Order should remain stable when all dates are null
      });
    });

    group('sortFoods with SortOption.category', () {
      test('sorts foods by category alphabetically', () {
        final result = FoodSortingHelper.sortFoods(
          testFoods,
          SortOption.category,
        );

        expect(result[0].category, 'Gemüse');
        expect(result[1].category, 'Milchprodukte');
        // Next two are both "Obst"
        expect(result[2].category, 'Obst');
        expect(result[3].category, 'Obst');
      });

      test('sorts alphabetically within same category', () {
        final result = FoodSortingHelper.sortFoods(
          testFoods,
          SortOption.category,
        );

        // Within "Obst" category: Apfel before Zitrone
        final obstFoods = result.where((f) => f.category == 'Obst').toList();
        expect(obstFoods[0].name, 'Apfel');
        expect(obstFoods[1].name, 'Zitrone');
      });

      test('treats null category as "Sonstiges"', () {
        final foodsWithNullCategory = [
          Food(id: '1', name: 'B', addedDate: now, category: 'Obst'),
          Food(id: '2', name: 'A', addedDate: now, category: null),
          Food(id: '3', name: 'C', addedDate: now, category: 'Gemüse'),
        ];

        final result = FoodSortingHelper.sortFoods(
          foodsWithNullCategory,
          SortOption.category,
        );

        // "Gemüse" < "Obst" < "Sonstiges"
        expect(result[0].category, 'Gemüse');
        expect(result[1].category, 'Obst');
        expect(result[2].category, null);
      });
    });

    group('sortFoods with SortOption.shared', () {
      test('puts shared foods first', () {
        final result = FoodSortingHelper.sortFoods(
          testFoods,
          SortOption.shared,
        );

        expect(result[0].isShared, true);
        expect(result[1].isShared, true);
        expect(result[2].isShared, false);
        expect(result[3].isShared, false);
      });

      test('sorts by expiry date within shared/non-shared groups', () {
        final result = FoodSortingHelper.sortFoods(
          testFoods,
          SortOption.shared,
        );

        // Shared foods: Apfel (7 days), Milch (null)
        expect(result[0].name, 'Apfel'); // 7 days
        expect(result[1].name, 'Milch'); // null goes last

        // Non-shared foods: Banane (1 day), Zitrone (3 days)
        expect(result[2].name, 'Banane'); // 1 day
        expect(result[3].name, 'Zitrone'); // 3 days
      });

      test('handles foods without expiry dates in shared group', () {
        final sharedWithoutDate = [
          Food(
            id: '1',
            name: 'A',
            addedDate: now,
            isShared: true,
            expiryDate: null,
          ),
          Food(
            id: '2',
            name: 'B',
            addedDate: now,
            isShared: true,
            expiryDate: now.add(const Duration(days: 5)),
          ),
          Food(
            id: '3',
            name: 'C',
            addedDate: now,
            isShared: false,
            expiryDate: now.add(const Duration(days: 2)),
          ),
        ];

        final result = FoodSortingHelper.sortFoods(
          sharedWithoutDate,
          SortOption.shared,
        );

        expect(result[0].name, 'B'); // shared with date
        expect(result[1].name, 'A'); // shared without date
        expect(result[2].name, 'C'); // not shared
      });

      test('handles all foods being non-shared', () {
        final allNonShared = testFoods
            .map((f) => f.copyWith(isShared: false))
            .toList();

        final result = FoodSortingHelper.sortFoods(
          allNonShared,
          SortOption.shared,
        );

        // Should sort by date when all have same shared status
        expect(result[0].name, 'Banane'); // 1 day
        expect(result[1].name, 'Zitrone'); // 3 days
      });
    });

    group('edge cases', () {
      test('handles empty list', () {
        final result = FoodSortingHelper.sortFoods([], SortOption.alphabetical);

        expect(result, isEmpty);
      });

      test('handles single item list', () {
        final singleFood = [testFoods.first];

        final result = FoodSortingHelper.sortFoods(
          singleFood,
          SortOption.alphabetical,
        );

        expect(result.length, 1);
        expect(result.first, testFoods.first);
      });
    });
  });
}
