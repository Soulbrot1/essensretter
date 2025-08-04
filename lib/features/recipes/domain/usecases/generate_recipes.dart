import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recipe.dart';
import '../repositories/recipe_repository.dart';

class GenerateRecipes implements UseCase<List<Recipe>, GenerateRecipesParams> {
  final RecipeRepository repository;

  GenerateRecipes(this.repository);

  @override
  Future<Either<Failure, List<Recipe>>> call(GenerateRecipesParams params) async {
    return await repository.generateRecipes(
      params.availableIngredients,
      previousRecipes: params.previousRecipes,
    );
  }
}

class GenerateRecipesParams extends Equatable {
  final List<String> availableIngredients;
  final List<Recipe> previousRecipes;

  const GenerateRecipesParams({
    required this.availableIngredients,
    this.previousRecipes = const [],
  });

  @override
  List<Object> get props => [availableIngredients, previousRecipes];
}