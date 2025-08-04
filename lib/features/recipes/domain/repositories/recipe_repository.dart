import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/recipe.dart';

abstract class RecipeRepository {
  Future<Either<Failure, List<Recipe>>> generateRecipes(
    List<String> availableIngredients, {
    List<Recipe> previousRecipes = const [],
  });
  Future<Either<Failure, List<Recipe>>> getBookmarkedRecipes();
  Future<Either<Failure, void>> saveBookmarkedRecipe(Recipe recipe);
  Future<Either<Failure, void>> removeBookmarkedRecipe(String recipeTitle);
}