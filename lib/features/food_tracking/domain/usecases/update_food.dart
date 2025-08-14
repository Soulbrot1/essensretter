import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/food.dart';
import '../repositories/food_repository.dart';

class UpdateFood {
  final FoodRepository repository;

  UpdateFood(this.repository);

  Future<Either<Failure, Food>> call(Food food) async {
    return await repository.updateFood(food);
  }
}
