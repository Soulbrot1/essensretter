import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/recipe_service.dart';
import '../datasources/recipe_local_data_source.dart';
import '../models/recipe_model.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final RecipeService recipeService;
  final RecipeLocalDataSource localDataSource;

  RecipeRepositoryImpl({
    required this.recipeService,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Recipe>>> generateRecipes(List<String> availableIngredients) async {
    try {
      final recipes = await recipeService.generateRecipes(availableIngredients);
      return Right(recipes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Recipe>>> getBookmarkedRecipes() async {
    try {
      final recipes = await localDataSource.getBookmarkedRecipes();
      return Right(recipes);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveBookmarkedRecipe(Recipe recipe) async {
    try {
      final recipeModel = RecipeModel.fromEntity(recipe);
      await localDataSource.saveBookmarkedRecipe(recipeModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeBookmarkedRecipe(String recipeTitle) async {
    try {
      await localDataSource.removeBookmarkedRecipe(recipeTitle);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}