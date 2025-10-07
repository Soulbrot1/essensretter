import 'package:flutter_test/flutter_test.dart';

import 'package:essensretter/features/food_tracking/data/models/food_model.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';

void main() {
  final tDateTime = DateTime(2024, 1, 15);
  final tExpiryDate = DateTime(2024, 1, 20);

  final tFoodModel = FoodModel(
    id: '1',
    name: 'Test Food',
    expiryDate: tExpiryDate,
    addedDate: tDateTime,
    category: 'Test Category',
    notes: 'Test notes',
    isConsumed: false,
    isShared: true,
  );

  group('FoodModel.fromJson', () {
    test('should create FoodModel from complete JSON', () {
      // arrange
      final json = {
        'id': '1',
        'name': 'Test Food',
        'expiryDate': '2024-01-20T00:00:00.000',
        'addedDate': '2024-01-15T00:00:00.000',
        'category': 'Test Category',
        'notes': 'Test notes',
        'isConsumed': 0,
        'isShared': 1,
      };

      // act
      final result = FoodModel.fromJson(json);

      // assert
      expect(result.id, '1');
      expect(result.name, 'Test Food');
      expect(result.expiryDate, isNotNull);
      expect(result.expiryDate?.year, 2024);
      expect(result.expiryDate?.month, 1);
      expect(result.expiryDate?.day, 20);
      expect(result.addedDate.year, 2024);
      expect(result.category, 'Test Category');
      expect(result.notes, 'Test notes');
      expect(result.isConsumed, false);
      expect(result.isShared, true);
    });

    test('should handle null expiryDate', () {
      // arrange
      final json = {
        'id': '1',
        'name': 'Test Food',
        'expiryDate': null,
        'addedDate': '2024-01-15T00:00:00.000',
        'category': 'Test',
        'notes': 'Test',
        'isConsumed': 0,
        'isShared': 0,
      };

      // act
      final result = FoodModel.fromJson(json);

      // assert
      expect(result.expiryDate, isNull);
    });

    test('should handle null category', () {
      // arrange
      final json = {
        'id': '1',
        'name': 'Test Food',
        'expiryDate': '2024-01-20T00:00:00.000',
        'addedDate': '2024-01-15T00:00:00.000',
        'category': null,
        'notes': 'Test',
        'isConsumed': 0,
        'isShared': 0,
      };

      // act
      final result = FoodModel.fromJson(json);

      // assert
      expect(result.category, isNull);
    });

    test('should handle null notes', () {
      // arrange
      final json = {
        'id': '1',
        'name': 'Test Food',
        'expiryDate': '2024-01-20T00:00:00.000',
        'addedDate': '2024-01-15T00:00:00.000',
        'category': 'Test',
        'notes': null,
        'isConsumed': 0,
        'isShared': 0,
      };

      // act
      final result = FoodModel.fromJson(json);

      // assert
      expect(result.notes, isNull);
    });

    test('should convert isConsumed int to bool correctly (0 = false)', () {
      // arrange
      final json = {
        'id': '1',
        'name': 'Test Food',
        'addedDate': '2024-01-15T00:00:00.000',
        'isConsumed': 0,
        'isShared': 0,
      };

      // act
      final result = FoodModel.fromJson(json);

      // assert
      expect(result.isConsumed, false);
    });

    test('should convert isConsumed int to bool correctly (1 = true)', () {
      // arrange
      final json = {
        'id': '1',
        'name': 'Test Food',
        'addedDate': '2024-01-15T00:00:00.000',
        'isConsumed': 1,
        'isShared': 0,
      };

      // act
      final result = FoodModel.fromJson(json);

      // assert
      expect(result.isConsumed, true);
    });

    test('should convert isShared int to bool correctly (0 = false)', () {
      // arrange
      final json = {
        'id': '1',
        'name': 'Test Food',
        'addedDate': '2024-01-15T00:00:00.000',
        'isConsumed': 0,
        'isShared': 0,
      };

      // act
      final result = FoodModel.fromJson(json);

      // assert
      expect(result.isShared, false);
    });

    test('should convert isShared int to bool correctly (1 = true)', () {
      // arrange
      final json = {
        'id': '1',
        'name': 'Test Food',
        'addedDate': '2024-01-15T00:00:00.000',
        'isConsumed': 0,
        'isShared': 1,
      };

      // act
      final result = FoodModel.fromJson(json);

      // assert
      expect(result.isShared, true);
    });

    test('should handle null isConsumed (defaults to false)', () {
      // arrange
      final json = {
        'id': '1',
        'name': 'Test Food',
        'addedDate': '2024-01-15T00:00:00.000',
        'isConsumed': null,
        'isShared': 0,
      };

      // act
      final result = FoodModel.fromJson(json);

      // assert
      expect(result.isConsumed, false);
    });

    test('should handle null isShared (defaults to false)', () {
      // arrange
      final json = {
        'id': '1',
        'name': 'Test Food',
        'addedDate': '2024-01-15T00:00:00.000',
        'isConsumed': 0,
        'isShared': null,
      };

      // act
      final result = FoodModel.fromJson(json);

      // assert
      expect(result.isShared, false);
    });
  });

  group('FoodModel.toJson', () {
    test('should convert FoodModel to complete JSON', () {
      // act
      final result = tFoodModel.toJson();

      // assert
      expect(result['id'], '1');
      expect(result['name'], 'Test Food');
      expect(result['expiryDate'], '2024-01-20T00:00:00.000');
      expect(result['addedDate'], '2024-01-15T00:00:00.000');
      expect(result['category'], 'Test Category');
      expect(result['notes'], 'Test notes');
      expect(result['isConsumed'], 0);
      expect(result['isShared'], 1);
    });

    test('should convert null expiryDate to null', () {
      // arrange
      final foodModel = FoodModel(
        id: '1',
        name: 'Test Food',
        expiryDate: null,
        addedDate: tDateTime,
      );

      // act
      final result = foodModel.toJson();

      // assert
      expect(result['expiryDate'], isNull);
    });

    test('should convert null category to null', () {
      // arrange
      final foodModel = FoodModel(
        id: '1',
        name: 'Test Food',
        addedDate: tDateTime,
        category: null,
      );

      // act
      final result = foodModel.toJson();

      // assert
      expect(result['category'], isNull);
    });

    test('should convert null notes to null', () {
      // arrange
      final foodModel = FoodModel(
        id: '1',
        name: 'Test Food',
        addedDate: tDateTime,
        notes: null,
      );

      // act
      final result = foodModel.toJson();

      // assert
      expect(result['notes'], isNull);
    });

    test('should convert isConsumed false to 0', () {
      // arrange
      final foodModel = FoodModel(
        id: '1',
        name: 'Test Food',
        addedDate: tDateTime,
        isConsumed: false,
      );

      // act
      final result = foodModel.toJson();

      // assert
      expect(result['isConsumed'], 0);
    });

    test('should convert isConsumed true to 1', () {
      // arrange
      final foodModel = FoodModel(
        id: '1',
        name: 'Test Food',
        addedDate: tDateTime,
        isConsumed: true,
      );

      // act
      final result = foodModel.toJson();

      // assert
      expect(result['isConsumed'], 1);
    });

    test('should convert isShared false to 0', () {
      // arrange
      final foodModel = FoodModel(
        id: '1',
        name: 'Test Food',
        addedDate: tDateTime,
        isShared: false,
      );

      // act
      final result = foodModel.toJson();

      // assert
      expect(result['isShared'], 0);
    });

    test('should convert isShared true to 1', () {
      // arrange
      final foodModel = FoodModel(
        id: '1',
        name: 'Test Food',
        addedDate: tDateTime,
        isShared: true,
      );

      // act
      final result = foodModel.toJson();

      // assert
      expect(result['isShared'], 1);
    });
  });

  group('FoodModel.fromEntity', () {
    test('should create FoodModel from Food entity with all properties', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test Food',
        expiryDate: tExpiryDate,
        addedDate: tDateTime,
        category: 'Test Category',
        notes: 'Test notes',
        isConsumed: true,
        isShared: false,
      );

      // act
      final result = FoodModel.fromEntity(food);

      // assert
      expect(result.id, food.id);
      expect(result.name, food.name);
      expect(result.expiryDate, food.expiryDate);
      expect(result.addedDate, food.addedDate);
      expect(result.category, food.category);
      expect(result.notes, food.notes);
      expect(result.isConsumed, food.isConsumed);
      expect(result.isShared, food.isShared);
    });

    test('should create FoodModel from Food entity with null optionals', () {
      // arrange
      final food = Food(
        id: '1',
        name: 'Test Food',
        expiryDate: null,
        addedDate: tDateTime,
        category: null,
        notes: null,
        isConsumed: false,
        isShared: false,
      );

      // act
      final result = FoodModel.fromEntity(food);

      // assert
      expect(result.expiryDate, isNull);
      expect(result.category, isNull);
      expect(result.notes, isNull);
    });

    test('should preserve all boolean flags correctly', () {
      // arrange
      final consumedShared = Food(
        id: '1',
        name: 'Test',
        addedDate: tDateTime,
        isConsumed: true,
        isShared: true,
      );

      // act
      final result = FoodModel.fromEntity(consumedShared);

      // assert
      expect(result.isConsumed, true);
      expect(result.isShared, true);
    });
  });

  group('FoodModel JSON round-trip', () {
    test('should maintain data integrity through toJson -> fromJson cycle', () {
      // arrange
      final original = tFoodModel;

      // act
      final json = original.toJson();
      final result = FoodModel.fromJson(json);

      // assert
      expect(result.id, original.id);
      expect(result.name, original.name);
      expect(result.expiryDate?.day, original.expiryDate?.day);
      expect(result.addedDate.day, original.addedDate.day);
      expect(result.category, original.category);
      expect(result.notes, original.notes);
      expect(result.isConsumed, original.isConsumed);
      expect(result.isShared, original.isShared);
    });
  });
}
