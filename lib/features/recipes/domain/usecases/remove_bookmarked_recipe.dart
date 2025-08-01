import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/recipe_repository.dart';

class RemoveBookmarkedRecipe implements UseCase<void, RemoveBookmarkedRecipeParams> {
  final RecipeRepository repository;

  RemoveBookmarkedRecipe(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveBookmarkedRecipeParams params) async {
    return await repository.removeBookmarkedRecipe(params.recipeTitle);
  }
}

class RemoveBookmarkedRecipeParams extends Equatable {
  final String recipeTitle;

  const RemoveBookmarkedRecipeParams({required this.recipeTitle});

  @override
  List<Object> get props => [recipeTitle];
}