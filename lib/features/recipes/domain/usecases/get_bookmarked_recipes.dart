import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recipe.dart';
import '../entities/ingredient.dart';
import '../repositories/recipe_repository.dart';
import '../../../food_tracking/domain/repositories/food_repository.dart';

class GetBookmarkedRecipes implements UseCase<List<Recipe>, NoParams> {
  final RecipeRepository repository;
  final FoodRepository foodRepository;

  GetBookmarkedRecipes({
    required this.repository,
    required this.foodRepository,
  });

  @override
  Future<Either<Failure, List<Recipe>>> call(NoParams params) async {
    // First get all current foods
    final foodsResult = await foodRepository.getAllFoods();

    return foodsResult.fold((failure) => Left(failure), (foods) async {
      // Get bookmarked recipes
      final recipesResult = await repository.getBookmarkedRecipes();

      return recipesResult.fold((failure) => Left(failure), (recipes) async {
        // Create a set of available food names for quick lookup
        final availableFoodNames = foods
            .map((f) => f.name.toLowerCase())
            .toSet();

        // Synchronize each recipe with current food inventory
        final synchronizedRecipes = recipes.map((recipe) {
          final stillAvailable = <Ingredient>[];
          final needToCheck = <Ingredient>[];

          // Check which ingredients from "vorhanden" are still available
          for (final ingredient in recipe.vorhanden) {
            if (availableFoodNames.any(
              (foodName) =>
                  ingredient.name.toLowerCase().contains(foodName) ||
                  foodName.contains(ingredient.name.toLowerCase()),
            )) {
              stillAvailable.add(ingredient);
            } else {
              // Move to check/buy list if not available anymore
              needToCheck.add(ingredient);
            }
          }

          // Check which ingredients from "ueberpruefen" are now available
          for (final ingredient in recipe.ueberpruefen) {
            if (availableFoodNames.any(
              (foodName) =>
                  ingredient.name.toLowerCase().contains(foodName) ||
                  foodName.contains(ingredient.name.toLowerCase()),
            )) {
              // Move back to available list
              stillAvailable.add(ingredient);
            } else {
              // Keep in check/buy list
              needToCheck.add(ingredient);
            }
          }

          return recipe.copyWith(
            vorhanden: stillAvailable,
            ueberpruefen: needToCheck,
          );
        }).toList();

        // Check if any recipes were updated
        bool needsUpdate = false;
        for (int i = 0; i < recipes.length; i++) {
          if (recipes[i].vorhanden.length !=
                  synchronizedRecipes[i].vorhanden.length ||
              recipes[i].ueberpruefen.length !=
                  synchronizedRecipes[i].ueberpruefen.length) {
            needsUpdate = true;
            break;
          }
        }

        // Save the updated recipes if there were changes
        if (needsUpdate) {
          await repository.updateAllBookmarkedRecipes(synchronizedRecipes);
        }

        return Right(synchronizedRecipes);
      });
    });
  }
}
