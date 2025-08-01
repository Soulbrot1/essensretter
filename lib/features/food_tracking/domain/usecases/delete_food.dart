import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/food_repository.dart';

class DeleteFood implements UseCase<void, DeleteFoodParams> {
  final FoodRepository repository;

  DeleteFood(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteFoodParams params) async {
    return await repository.deleteFood(params.id);
  }
}

class DeleteFoodParams extends Equatable {
  final String id;

  const DeleteFoodParams({required this.id});

  @override
  List<Object> get props => [id];
}