import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_model.dart';

abstract class RecipeLocalDataSource {
  Future<List<RecipeModel>> getBookmarkedRecipes();
  Future<void> saveBookmarkedRecipe(RecipeModel recipe);
  Future<void> removeBookmarkedRecipe(String recipeTitle);
  Future<void> clearBookmarkedRecipes();
  Future<void> updateRecipesAfterFoodDeletion(String foodName);
  Future<void> updateAllBookmarkedRecipes(List<RecipeModel> recipes);
}

class RecipeLocalDataSourceImpl implements RecipeLocalDataSource {
  static const String _bookmarkedRecipesKey = 'bookmarked_recipes';

  @override
  Future<List<RecipeModel>> getBookmarkedRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recipesJsonString = prefs.getString(_bookmarkedRecipesKey);

      if (recipesJsonString == null) {
        return [];
      }

      final List<dynamic> recipesJson = json.decode(recipesJsonString);
      final recipes = recipesJson
          .map((json) => RecipeModel.fromJson(json))
          .toList();
      return recipes;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveBookmarkedRecipe(RecipeModel recipe) async {
    try {
      final bookmarkedRecipes = await getBookmarkedRecipes();

      // Check if recipe already exists (by title)
      final existingIndex = bookmarkedRecipes.indexWhere(
        (r) => r.title == recipe.title,
      );

      final recipeModel = RecipeModel(
        title: recipe.title,
        cookingTime: recipe.cookingTime,
        vorhanden: recipe.vorhanden,
        ueberpruefen: recipe.ueberpruefen,
        instructions: recipe.instructions,
        isBookmarked: true,
      );

      if (existingIndex >= 0) {
        // Update existing recipe
        bookmarkedRecipes[existingIndex] = recipeModel;
      } else {
        // Add new recipe
        bookmarkedRecipes.add(recipeModel);
      }

      await _saveRecipes(bookmarkedRecipes);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeBookmarkedRecipe(String recipeTitle) async {
    try {
      final bookmarkedRecipes = await getBookmarkedRecipes();
      bookmarkedRecipes.removeWhere((recipe) => recipe.title == recipeTitle);
      await _saveRecipes(bookmarkedRecipes);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearBookmarkedRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bookmarkedRecipesKey);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveRecipes(List<RecipeModel> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = recipes.map((recipe) => recipe.toJson()).toList();
    await prefs.setString(_bookmarkedRecipesKey, json.encode(recipesJson));
  }

  @override
  Future<void> updateRecipesAfterFoodDeletion(String foodName) async {
    try {
      final bookmarkedRecipes = await getBookmarkedRecipes();
      final updatedRecipes = <RecipeModel>[];

      for (final recipe in bookmarkedRecipes) {
        // Check if the deleted food is in vorhanden list
        if (recipe.vorhanden.any(
          (ingredient) =>
              ingredient.name.toLowerCase().contains(foodName.toLowerCase()),
        )) {
          // Move the ingredient from vorhanden to ueberpruefen
          final updatedVorhanden = recipe.vorhanden
              .where(
                (ingredient) => !ingredient.name.toLowerCase().contains(
                  foodName.toLowerCase(),
                ),
              )
              .toList();

          final matchingIngredients = recipe.vorhanden
              .where(
                (ingredient) => ingredient.name.toLowerCase().contains(
                  foodName.toLowerCase(),
                ),
              )
              .toList();

          final updatedUeberpruefen = [
            ...recipe.ueberpruefen,
            ...matchingIngredients,
          ];

          updatedRecipes.add(
            RecipeModel(
              title: recipe.title,
              cookingTime: recipe.cookingTime,
              vorhanden: updatedVorhanden,
              ueberpruefen: updatedUeberpruefen,
              instructions: recipe.instructions,
              isBookmarked: recipe.isBookmarked,
            ),
          );
        } else {
          // Recipe doesn't contain the deleted food, keep as is
          updatedRecipes.add(recipe);
        }
      }

      await _saveRecipes(updatedRecipes);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateAllBookmarkedRecipes(List<RecipeModel> recipes) async {
    try {
      await _saveRecipes(recipes);
    } catch (e) {
      rethrow;
    }
  }
}
