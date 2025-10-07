import 'package:flutter_test/flutter_test.dart';

import 'package:essensretter/features/food_tracking/domain/entities/food.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final tFood = Food(
    id: '1',
    name: 'Test Food',
    expiryDate: today.add(const Duration(days: 5)),
    addedDate: today,
    category: 'Test Category',
    notes: 'Test notes',
    isConsumed: false,
    isShared: false,
  );

  group('Food equality', () {
    test('should be equal when all properties are the same', () {
      // arrange
      final food1 = Food(
        id: '1',
        name: 'Test Food',
        expiryDate: today,
        addedDate: today,
        category: 'Test',
        notes: 'Notes',
        isConsumed: false,
        isShared: true,
      );
      final food2 = Food(
        id: '1',
        name: 'Test Food',
        expiryDate: today,
        addedDate: today,
        category: 'Test',
        notes: 'Notes',
        isConsumed: false,
        isShared: true,
      );

      // assert
      expect(food1, equals(food2));
      expect(food1.hashCode, equals(food2.hashCode));
    });

    test('should not be equal when id is different', () {
      // arrange
      final food1 = Food(id: '1', name: 'Test', addedDate: today);
      final food2 = Food(id: '2', name: 'Test', addedDate: today);

      // assert
      expect(food1, isNot(equals(food2)));
    });

    test('should not be equal when name is different', () {
      // arrange
      final food1 = Food(id: '1', name: 'Test1', addedDate: today);
      final food2 = Food(id: '1', name: 'Test2', addedDate: today);

      // assert
      expect(food1, isNot(equals(food2)));
    });

    test('should not be equal when isConsumed is different', () {
      // arrange
      final food1 = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        isConsumed: false,
      );
      final food2 = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        isConsumed: true,
      );

      // assert
      expect(food1, isNot(equals(food2)));
    });
  });

  group('Food.copyWith', () {
    test('should return new Food with updated name', () {
      // act
      final result = tFood.copyWith(name: 'Updated Name');

      // assert
      expect(result.name, 'Updated Name');
      expect(result.id, tFood.id);
      expect(result.expiryDate, tFood.expiryDate);
    });

    test('should return new Food with updated expiryDate', () {
      // arrange
      final newDate = today.add(const Duration(days: 10));

      // act
      final result = tFood.copyWith(expiryDate: newDate);

      // assert
      expect(result.expiryDate, newDate);
      expect(result.name, tFood.name);
    });

    test('should return new Food with updated category', () {
      // act
      final result = tFood.copyWith(category: 'New Category');

      // assert
      expect(result.category, 'New Category');
    });

    test('should return new Food with updated notes', () {
      // act
      final result = tFood.copyWith(notes: 'New Notes');

      // assert
      expect(result.notes, 'New Notes');
    });

    test('should return new Food with updated isConsumed', () {
      // act
      final result = tFood.copyWith(isConsumed: true);

      // assert
      expect(result.isConsumed, true);
      expect(result.isShared, tFood.isShared);
    });

    test('should return new Food with updated isShared', () {
      // act
      final result = tFood.copyWith(isShared: true);

      // assert
      expect(result.isShared, true);
      expect(result.isConsumed, tFood.isConsumed);
    });

    test('should clear expiryDate when clearExpiryDate is true', () {
      // act
      final result = tFood.copyWith(clearExpiryDate: true);

      // assert
      expect(result.expiryDate, isNull);
      expect(result.name, tFood.name);
    });

    test('should preserve expiryDate when clearExpiryDate is false', () {
      // act
      final result = tFood.copyWith(clearExpiryDate: false);

      // assert
      expect(result.expiryDate, tFood.expiryDate);
    });

    test('should update multiple properties at once', () {
      // act
      final result = tFood.copyWith(
        name: 'New Name',
        category: 'New Category',
        isConsumed: true,
        isShared: true,
      );

      // assert
      expect(result.name, 'New Name');
      expect(result.category, 'New Category');
      expect(result.isConsumed, true);
      expect(result.isShared, true);
      expect(result.id, tFood.id);
    });

    test('should preserve all properties when no arguments given', () {
      // act
      final result = tFood.copyWith();

      // assert
      expect(result.id, tFood.id);
      expect(result.name, tFood.name);
      expect(result.expiryDate, tFood.expiryDate);
      expect(result.category, tFood.category);
      expect(result.notes, tFood.notes);
      expect(result.isConsumed, tFood.isConsumed);
      expect(result.isShared, tFood.isShared);
    });
  });

  group('Food.daysUntilExpiry', () {
    test('should return correct days for food expiring in 5 days', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.add(const Duration(days: 5)),
      );

      // assert
      expect(food.daysUntilExpiry, 5);
    });

    test('should return 0 for food expiring today', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today,
      );

      // assert
      expect(food.daysUntilExpiry, 0);
    });

    test('should return negative number for expired food', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.subtract(const Duration(days: 2)),
      );

      // assert
      expect(food.daysUntilExpiry, -2);
    });

    test('should return 999 for food without expiry date', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: null,
      );

      // assert
      expect(food.daysUntilExpiry, 999);
    });
  });

  group('Food.isExpired', () {
    test('should return true for expired food', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.subtract(const Duration(days: 1)),
      );

      // assert
      expect(food.isExpired, true);
    });

    test('should return false for food expiring today', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today,
      );

      // assert
      expect(food.isExpired, false);
    });

    test('should return false for food expiring in future', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.add(const Duration(days: 5)),
      );

      // assert
      expect(food.isExpired, false);
    });

    test('should return false for food without expiry date', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: null,
      );

      // assert
      expect(food.isExpired, false);
    });
  });

  group('Food.expiresInDays', () {
    test('should return true for food expiring within given days', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.add(const Duration(days: 3)),
      );

      // assert
      expect(food.expiresInDays(5), true);
    });

    test('should return true for food expiring exactly on given days', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.add(const Duration(days: 5)),
      );

      // assert
      expect(food.expiresInDays(5), true);
    });

    test('should return false for food expiring after given days', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.add(const Duration(days: 10)),
      );

      // assert
      expect(food.expiresInDays(5), false);
    });

    test('should return false for food without expiry date', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: null,
      );

      // assert
      expect(food.expiresInDays(5), false);
    });

    test('should return true for already expired food', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.subtract(const Duration(days: 2)),
      );

      // assert
      expect(food.expiresInDays(5), true);
    });
  });

  group('Food.expiryStatus', () {
    test('should return "ohne Datum" for food without expiry date', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: null,
      );

      // assert
      expect(food.expiryStatus, 'ohne Datum');
    });

    test('should return "heute" for food expiring today', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today,
      );

      // assert
      expect(food.expiryStatus, 'heute');
    });

    test('should return "Morgen" for food expiring tomorrow', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.add(const Duration(days: 1)),
      );

      // assert
      expect(food.expiryStatus, 'Morgen');
    });

    test('should return "Übermorgen" for food expiring in 2 days', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.add(const Duration(days: 2)),
      );

      // assert
      expect(food.expiryStatus, 'Übermorgen');
    });

    test('should return "X Tage" for food expiring in more than 2 days', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.add(const Duration(days: 5)),
      );

      // assert
      expect(food.expiryStatus, '5 Tage');
    });

    test('should return "vor X Tagen" for expired food (plural)', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.subtract(const Duration(days: 3)),
      );

      // assert
      expect(food.expiryStatus, 'vor 3 Tagen');
    });

    test('should return "vor X Tag" for food expired 1 day ago (singular)', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test',
        addedDate: today,
        expiryDate: today.subtract(const Duration(days: 1)),
      );

      // assert
      expect(food.expiryStatus, 'vor 1 Tag');
    });
  });

  group('Food default values', () {
    test('should have default isConsumed = false', () {
      // arrange
      final food = Food(id: '1', name: 'Test', addedDate: today);

      // assert
      expect(food.isConsumed, false);
    });

    test('should have default isShared = false', () {
      // arrange
      final food = Food(id: '1', name: 'Test', addedDate: today);

      // assert
      expect(food.isShared, false);
    });
  });
}
