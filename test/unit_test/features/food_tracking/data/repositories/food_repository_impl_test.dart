import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:essensretter/core/error/exceptions.dart';
import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/features/food_tracking/data/datasources/food_local_data_source.dart';
import 'package:essensretter/features/food_tracking/data/models/food_model.dart';
import 'package:essensretter/features/food_tracking/data/repositories/food_repository_impl.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';

class MockFoodLocalDataSource extends Mock implements FoodLocalDataSource {}

class FakeFoodModel extends Fake implements FoodModel {}

void main() {
  late FoodRepositoryImpl repository;
  late MockFoodLocalDataSource mockLocalDataSource;

  setUpAll(() {
    registerFallbackValue(FakeFoodModel());
  });

  setUp(() {
    mockLocalDataSource = MockFoodLocalDataSource();
    repository = FoodRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  final tDateTime = DateTime(2024, 1, 15);
  final tFoodModel = FoodModel(
    id: '1',
    name: 'Test Food',
    expiryDate: tDateTime.add(const Duration(days: 5)),
    addedDate: tDateTime,
    category: 'Test',
    notes: 'Test notes',
    isConsumed: false,
    isShared: false,
  );

  final Food tFood = tFoodModel;

  group('getAllFoods', () {
    test(
      'should return list of foods when call to data source is successful',
      () async {
        // arrange
        final tFoodModels = [tFoodModel];
        when(
          () => mockLocalDataSource.getAllFoods(),
        ).thenAnswer((_) async => tFoodModels);

        // act
        final result = await repository.getAllFoods();

        // assert
        verify(() => mockLocalDataSource.getAllFoods());
        expect(result, Right(tFoodModels));
      },
    );

    test(
      'should return CacheFailure when data source throws CacheException',
      () async {
        // arrange
        when(
          () => mockLocalDataSource.getAllFoods(),
        ).thenThrow(CacheException());

        // act
        final result = await repository.getAllFoods();

        // assert
        verify(() => mockLocalDataSource.getAllFoods());
        expect(
          result,
          const Left(CacheFailure('Fehler beim Laden der Lebensmittel')),
        );
      },
    );

    test('should return empty list when no foods exist', () async {
      // arrange
      when(() => mockLocalDataSource.getAllFoods()).thenAnswer((_) async => []);

      // act
      final result = await repository.getAllFoods();

      // assert
      expect(result.isRight(), true);
      result.fold((l) => null, (foods) => expect(foods, isEmpty));
    });
  });

  group('getFoodsByExpiryDays', () {
    test('should return filtered foods when call is successful', () async {
      // arrange
      final tFoodModels = [tFoodModel];
      when(
        () => mockLocalDataSource.getFoodsByExpiryDays(7),
      ).thenAnswer((_) async => tFoodModels);

      // act
      final result = await repository.getFoodsByExpiryDays(7);

      // assert
      verify(() => mockLocalDataSource.getFoodsByExpiryDays(7));
      expect(result, Right(tFoodModels));
    });

    test(
      'should return CacheFailure when data source throws CacheException',
      () async {
        // arrange
        when(
          () => mockLocalDataSource.getFoodsByExpiryDays(7),
        ).thenThrow(CacheException());

        // act
        final result = await repository.getFoodsByExpiryDays(7);

        // assert
        expect(
          result,
          const Left(CacheFailure('Fehler beim Filtern der Lebensmittel')),
        );
      },
    );

    test('should return empty list when no foods match filter', () async {
      // arrange
      when(
        () => mockLocalDataSource.getFoodsByExpiryDays(1),
      ).thenAnswer((_) async => []);

      // act
      final result = await repository.getFoodsByExpiryDays(1);

      // assert
      expect(result.isRight(), true);
      result.fold((l) => null, (foods) => expect(foods, isEmpty));
    });
  });

  group('getFoodById', () {
    test('should return food when found', () async {
      // arrange
      final tFoodModels = [tFoodModel];
      when(
        () => mockLocalDataSource.getAllFoods(),
      ).thenAnswer((_) async => tFoodModels);

      // act
      final result = await repository.getFoodById('1');

      // assert
      verify(() => mockLocalDataSource.getAllFoods());
      expect(result, Right(tFoodModel));
    });

    test('should return CacheFailure when food not found', () async {
      // arrange
      final tFoodModels = [tFoodModel];
      when(
        () => mockLocalDataSource.getAllFoods(),
      ).thenAnswer((_) async => tFoodModels);

      // act
      final result = await repository.getFoodById('999');

      // assert
      expect(result, const Left(CacheFailure('Lebensmittel nicht gefunden')));
    });

    test(
      'should return CacheFailure when data source throws CacheException',
      () async {
        // arrange
        when(
          () => mockLocalDataSource.getAllFoods(),
        ).thenThrow(CacheException());

        // act
        final result = await repository.getFoodById('1');

        // assert
        expect(
          result,
          const Left(CacheFailure('Fehler beim Laden des Lebensmittels')),
        );
      },
    );

    test('should return correct food when multiple foods exist', () async {
      // arrange
      final tFoodModel2 = FoodModel(
        id: '2',
        name: 'Second Food',
        addedDate: tDateTime,
      );
      final tFoodModels = [tFoodModel, tFoodModel2];
      when(
        () => mockLocalDataSource.getAllFoods(),
      ).thenAnswer((_) async => tFoodModels);

      // act
      final result = await repository.getFoodById('2');

      // assert
      expect(result, Right(tFoodModel2));
    });
  });

  group('addFood', () {
    test('should add food and return it when successful', () async {
      // arrange
      when(
        () => mockLocalDataSource.addFood(any()),
      ).thenAnswer((_) async => tFoodModel);

      // act
      final result = await repository.addFood(tFood);

      // assert
      verify(() => mockLocalDataSource.addFood(any()));
      expect(result, Right(tFoodModel));
    });

    test(
      'should return CacheFailure when data source throws CacheException',
      () async {
        // arrange
        when(
          () => mockLocalDataSource.addFood(any()),
        ).thenThrow(CacheException());

        // act
        final result = await repository.addFood(tFood);

        // assert
        expect(
          result,
          const Left(CacheFailure('Fehler beim Speichern des Lebensmittels')),
        );
      },
    );

    test('should convert Food entity to FoodModel before adding', () async {
      // arrange
      when(
        () => mockLocalDataSource.addFood(any()),
      ).thenAnswer((_) async => tFoodModel);

      // act
      await repository.addFood(tFood);

      // assert
      final captured = verify(
        () => mockLocalDataSource.addFood(captureAny()),
      ).captured;
      expect(captured.first, isA<FoodModel>());
      expect(captured.first.id, tFood.id);
      expect(captured.first.name, tFood.name);
    });
  });

  group('deleteFood', () {
    test('should delete food successfully', () async {
      // arrange
      when(
        () => mockLocalDataSource.deleteFood('1'),
      ).thenAnswer((_) async => {});

      // act
      final result = await repository.deleteFood('1');

      // assert
      verify(() => mockLocalDataSource.deleteFood('1'));
      expect(result, const Right(null));
    });

    test(
      'should return CacheFailure when data source throws CacheException',
      () async {
        // arrange
        when(
          () => mockLocalDataSource.deleteFood('1'),
        ).thenThrow(CacheException());

        // act
        final result = await repository.deleteFood('1');

        // assert
        expect(
          result,
          const Left(CacheFailure('Fehler beim Löschen des Lebensmittels')),
        );
      },
    );

    test('should pass correct id to data source', () async {
      // arrange
      const testId = 'test-id-123';
      when(
        () => mockLocalDataSource.deleteFood(testId),
      ).thenAnswer((_) async => {});

      // act
      await repository.deleteFood(testId);

      // assert
      verify(() => mockLocalDataSource.deleteFood(testId));
    });
  });

  group('updateFood', () {
    test('should update food and return it when successful', () async {
      // arrange
      final updatedFood = FoodModel(
        id: tFoodModel.id,
        name: 'Updated Food',
        addedDate: tFoodModel.addedDate,
        expiryDate: tFoodModel.expiryDate,
        category: tFoodModel.category,
        notes: tFoodModel.notes,
      );
      when(
        () => mockLocalDataSource.updateFood(any()),
      ).thenAnswer((_) async => updatedFood);

      // act
      final result = await repository.updateFood(updatedFood);

      // assert
      verify(() => mockLocalDataSource.updateFood(any()));
      expect(result, Right(updatedFood));
    });

    test(
      'should return CacheFailure when data source throws CacheException',
      () async {
        // arrange
        when(
          () => mockLocalDataSource.updateFood(any()),
        ).thenThrow(CacheException());

        // act
        final result = await repository.updateFood(tFood);

        // assert
        expect(
          result,
          const Left(
            CacheFailure('Fehler beim Aktualisieren des Lebensmittels'),
          ),
        );
      },
    );

    test('should convert Food entity to FoodModel before updating', () async {
      // arrange
      when(
        () => mockLocalDataSource.updateFood(any()),
      ).thenAnswer((_) async => tFoodModel);

      // act
      await repository.updateFood(tFood);

      // assert
      final captured = verify(
        () => mockLocalDataSource.updateFood(captureAny()),
      ).captured;
      expect(captured.first, isA<FoodModel>());
      expect(captured.first.id, tFood.id);
      expect(captured.first.name, tFood.name);
    });

    test('should handle updating food with null expiryDate', () async {
      // arrange
      final foodWithoutExpiry = FoodModel(
        id: '1',
        name: 'No Expiry Food',
        addedDate: tDateTime,
        expiryDate: null,
      );
      when(
        () => mockLocalDataSource.updateFood(any()),
      ).thenAnswer((_) async => foodWithoutExpiry);

      // act
      final result = await repository.updateFood(foodWithoutExpiry);

      // assert
      expect(result, Right(foodWithoutExpiry));
    });

    test('should handle updating isConsumed status', () async {
      // arrange
      final consumedFood = FoodModel(
        id: tFoodModel.id,
        name: tFoodModel.name,
        addedDate: tFoodModel.addedDate,
        expiryDate: tFoodModel.expiryDate,
        category: tFoodModel.category,
        notes: tFoodModel.notes,
        isConsumed: true,
      );
      when(
        () => mockLocalDataSource.updateFood(any()),
      ).thenAnswer((_) async => consumedFood);

      // act
      final result = await repository.updateFood(consumedFood);

      // assert
      expect(result, Right(consumedFood));
      final captured = verify(
        () => mockLocalDataSource.updateFood(captureAny()),
      ).captured;
      expect(captured.first.isConsumed, true);
    });

    test('should handle updating isShared status', () async {
      // arrange
      final sharedFood = FoodModel(
        id: tFoodModel.id,
        name: tFoodModel.name,
        addedDate: tFoodModel.addedDate,
        expiryDate: tFoodModel.expiryDate,
        category: tFoodModel.category,
        notes: tFoodModel.notes,
        isShared: true,
      );
      when(
        () => mockLocalDataSource.updateFood(any()),
      ).thenAnswer((_) async => sharedFood);

      // act
      final result = await repository.updateFood(sharedFood);

      // assert
      expect(result, Right(sharedFood));
      final captured = verify(
        () => mockLocalDataSource.updateFood(captureAny()),
      ).captured;
      expect(captured.first.isShared, true);
    });
  });
}
