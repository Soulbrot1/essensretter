import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/food.dart';

abstract class FoodRepository {
  Future<Either<Failure, List<Food>>> getAllFoods();
  Future<Either<Failure, List<Food>>> getFoodsByExpiryDays(int days);
  Future<Either<Failure, Food>> getFoodById(String id);
  Future<Either<Failure, Food>> addFood(Food food);
  Future<Either<Failure, void>> deleteFood(String id);
  Future<Either<Failure, Food>> updateFood(Food food);
}
