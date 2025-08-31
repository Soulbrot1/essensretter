import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/food.dart';
import '../repositories/food_repository.dart';

class UpdateFood {
  final FoodRepository repository;

  UpdateFood(this.repository);

  Future<Either<Failure, Food>> call(Food food) async {
    try {
      return await repository.updateFood(food);
    } catch (e) {
      return Left(CacheFailure('Update fehlgeschlagen: $e'));
    }
  }
}
