import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/core/usecases/usecase.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/domain/repositories/food_repository.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/get_all_foods.dart';

class MockFoodRepository extends Mock implements FoodRepository {}

void main() {
  late GetAllFoods usecase;
  late MockFoodRepository mockFoodRepository;

  setUp(() {
    mockFoodRepository = MockFoodRepository();
    usecase = GetAllFoods(mockFoodRepository);
    registerFallbackValue(Food(
      id: 'fallback',
      name: 'fallback',
      expiryDate: DateTime.now(),
      addedDate: DateTime.now(),
    ));
  });

  group('GetAllFoods', () {
    final tFoodList = [
      Food(
        id: '1',
        name: 'Milch',
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        addedDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Food(
        id: '2',
        name: 'Brot',
        expiryDate: DateTime.now().add(const Duration(days: 1)),
        addedDate: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];

    test('should get foods from the repository', () async {
      // arrange
      when(() => mockFoodRepository.getAllFoods())
          .thenAnswer((_) async => Right(tFoodList));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, Right(tFoodList));
      verify(() => mockFoodRepository.getAllFoods());
      verifyNoMoreInteractions(mockFoodRepository);
    });

    test('should return failure when repository fails', () async {
      // arrange
      const tFailure = CacheFailure('Database error');
      when(() => mockFoodRepository.getAllFoods())
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockFoodRepository.getAllFoods());
      verifyNoMoreInteractions(mockFoodRepository);
    });

    test('should return empty list when no foods exist', () async {
      // arrange
      when(() => mockFoodRepository.getAllFoods())
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, const Right<Failure, List<Food>>([]));  
      verify(() => mockFoodRepository.getAllFoods());
      verifyNoMoreInteractions(mockFoodRepository);
    });
  });
}