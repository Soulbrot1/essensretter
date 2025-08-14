import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/food.dart';
import '../repositories/food_repository.dart';

class ToggleFoodConsumed implements UseCase<Food, ToggleFoodConsumedParams> {
  final FoodRepository repository;

  ToggleFoodConsumed(this.repository);

  @override
  Future<Either<Failure, Food>> call(ToggleFoodConsumedParams params) async {
    final updatedFood = params.food.copyWith(
      isConsumed: !params.food.isConsumed,
    );
    return await repository.updateFood(updatedFood);
  }
}

class ToggleFoodConsumedParams {
  final Food food;

  ToggleFoodConsumedParams({required this.food});
}
