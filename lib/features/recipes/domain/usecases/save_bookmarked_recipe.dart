import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recipe.dart';
import '../repositories/recipe_repository.dart';

class SaveBookmarkedRecipe implements UseCase<void, SaveBookmarkedRecipeParams> {
  final RecipeRepository repository;

  SaveBookmarkedRecipe(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveBookmarkedRecipeParams params) async {
    return await repository.saveBookmarkedRecipe(params.recipe);
  }
}

class SaveBookmarkedRecipeParams extends Equatable {
  final Recipe recipe;

  const SaveBookmarkedRecipeParams({required this.recipe});

  @override
  List<Object> get props => [recipe];
}