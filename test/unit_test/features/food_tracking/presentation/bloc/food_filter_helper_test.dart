import 'package:flutter_test/flutter_test.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_filter_helper.dart';

void main() {
  group('FoodFilterHelper', () {
    late List<Food> testFoods;

    setUp(() {
      final now = DateTime.now();
      testFoods = [
        Food(
          id: '1',
          name: 'Apfel',
          addedDate: now,
          expiryDate: now.add(const Duration(days: 3)),
          isShared: false,
        ),
        Food(
          id: '2',
          name: 'Banane',
          addedDate: now,
          expiryDate: now.add(const Duration(days: 7)),
          isShared: true,
        ),
        Food(
          id: '3',
          name: 'Orange',
          addedDate: now,
          expiryDate: now.add(const Duration(days: 10)),
          isShared: false,
        ),
        Food(
          id: '4',
          name: 'Apfelsaft',
          addedDate: now,
          expiryDate: now.add(const Duration(days: 2)),
          isShared: true,
        ),
      ];
    });

    group('applySearchFilter', () {
      test('filters foods by name (case-insensitive)', () {
        final result = FoodFilterHelper.applySearchFilter(testFoods, 'apfel');

        expect(result.length, 2);
        expect(result.any((f) => f.name == 'Apfel'), true);
        expect(result.any((f) => f.name == 'Apfelsaft'), true);
      });

      test('returns empty list when no match', () {
        final result = FoodFilterHelper.applySearchFilter(testFoods, 'xyz');

        expect(result, isEmpty);
      });

      test('is case-insensitive', () {
        final result = FoodFilterHelper.applySearchFilter(testFoods, 'BANANE');

        expect(result.length, 1);
        expect(result.first.name, 'Banane');
      });

      test('returns all foods for empty search text', () {
        final result = FoodFilterHelper.applySearchFilter(testFoods, '');

        expect(result.length, testFoods.length);
      });
    });

    group('applyExpiryFilter', () {
      test('filters foods expiring within given days', () {
        final result = FoodFilterHelper.applyExpiryFilter(testFoods, 5);

        // Should include foods expiring in 2 and 3 days
        expect(result.length, 2);
        expect(result.any((f) => f.name == 'Apfel'), true);
        expect(result.any((f) => f.name == 'Apfelsaft'), true);
      });

      test('includes foods expiring exactly on the day limit', () {
        final result = FoodFilterHelper.applyExpiryFilter(testFoods, 7);

        // Should include foods expiring in 2, 3, and 7 days
        expect(result.length, 3);
        expect(result.any((f) => f.name == 'Banane'), true);
      });

      test('returns empty list when no foods expire in time', () {
        final result = FoodFilterHelper.applyExpiryFilter(testFoods, 1);

        expect(result, isEmpty);
      });
    });

    group('applySharedFilter', () {
      test('filters only shared foods', () {
        final result = FoodFilterHelper.applySharedFilter(testFoods);

        expect(result.length, 2);
        expect(result.any((f) => f.name == 'Banane'), true);
        expect(result.any((f) => f.name == 'Apfelsaft'), true);
        expect(result.every((f) => f.isShared), true);
      });

      test('returns empty list when no shared foods', () {
        final nonSharedFoods = testFoods
            .map((f) => f.copyWith(isShared: false))
            .toList();

        final result = FoodFilterHelper.applySharedFilter(nonSharedFoods);

        expect(result, isEmpty);
      });
    });

    group('applyAllFilters', () {
      test('applies no filters when all parameters are null/false', () {
        final result = FoodFilterHelper.applyAllFilters(testFoods);

        expect(result.length, testFoods.length);
      });

      test('applies only search filter when provided', () {
        final result = FoodFilterHelper.applyAllFilters(
          testFoods,
          searchText: 'apfel',
        );

        expect(result.length, 2);
      });

      test('applies only expiry filter when provided', () {
        final result = FoodFilterHelper.applyAllFilters(
          testFoods,
          activeFilter: 5,
        );

        expect(result.length, 2);
      });

      test('applies only shared filter when enabled', () {
        final result = FoodFilterHelper.applyAllFilters(
          testFoods,
          showOnlyShared: true,
        );

        expect(result.length, 2);
        expect(result.every((f) => f.isShared), true);
      });

      test('combines search and expiry filter', () {
        final result = FoodFilterHelper.applyAllFilters(
          testFoods,
          searchText: 'apfel',
          activeFilter: 5,
        );

        // Should only include "Apfel" (expires in 3 days) and "Apfelsaft" (2 days)
        expect(result.length, 2);
        expect(result.any((f) => f.name == 'Apfel'), true);
        expect(result.any((f) => f.name == 'Apfelsaft'), true);
      });

      test('combines all three filters', () {
        final result = FoodFilterHelper.applyAllFilters(
          testFoods,
          searchText: 'apfel',
          activeFilter: 5,
          showOnlyShared: true,
        );

        // Should only include "Apfelsaft" (has "apfel" in name, expires in 2 days, is shared)
        expect(result.length, 1);
        expect(result.first.name, 'Apfelsaft');
      });

      test('returns empty list when filters eliminate all foods', () {
        final result = FoodFilterHelper.applyAllFilters(
          testFoods,
          searchText: 'xyz',
          activeFilter: 1,
          showOnlyShared: true,
        );

        expect(result, isEmpty);
      });

      test('ignores empty search text', () {
        final result = FoodFilterHelper.applyAllFilters(
          testFoods,
          searchText: '',
        );

        expect(result.length, testFoods.length);
      });
    });
  });
}
