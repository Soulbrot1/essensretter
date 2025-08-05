import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/recipe_repository.dart';

class UpdateRecipesAfterFoodDeletion implements UseCase<void, UpdateRecipesParams> {
  final RecipeRepository repository;

  UpdateRecipesAfterFoodDeletion(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateRecipesParams params) async {
    return await repository.updateRecipesAfterFoodDeletion(params.foodName);
  }
}

class UpdateRecipesParams extends Equatable {
  final String foodName;

  const UpdateRecipesParams({required this.foodName});

  @override
  List<Object> get props => [foodName];
}