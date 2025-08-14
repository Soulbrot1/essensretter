import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/food.dart';
import '../repositories/food_repository.dart';

class GetFoodsByExpiry implements UseCase<List<Food>, GetFoodsByExpiryParams> {
  final FoodRepository repository;

  GetFoodsByExpiry(this.repository);

  @override
  Future<Either<Failure, List<Food>>> call(
    GetFoodsByExpiryParams params,
  ) async {
    return await repository.getFoodsByExpiryDays(params.daysUntilExpiry);
  }
}

class GetFoodsByExpiryParams extends Equatable {
  final int daysUntilExpiry;

  const GetFoodsByExpiryParams({required this.daysUntilExpiry});

  @override
  List<Object> get props => [daysUntilExpiry];
}
