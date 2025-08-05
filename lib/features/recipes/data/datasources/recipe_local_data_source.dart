import 'dart:convert';
import 'package:flutter/foundation.dart';
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
        debugPrint('No bookmarked recipes found');
        return [];
      }

      final List<dynamic> recipesJson = json.decode(recipesJsonString);
      final recipes = recipesJson.map((json) => RecipeModel.fromJson(json)).toList();
      debugPrint('Loaded ${recipes.length} bookmarked recipes from storage');
      return recipes;
    } catch (e) {
      debugPrint('Error loading bookmarked recipes: $e');
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
      debugPrint('Saved recipe: ${recipe.title}. Total bookmarks: ${bookmarkedRecipes.length}');
    } catch (e) {
      debugPrint('Error saving bookmarked recipe: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeBookmarkedRecipe(String recipeTitle) async {
    try {
      final bookmarkedRecipes = await getBookmarkedRecipes();
      bookmarkedRecipes.removeWhere((recipe) => recipe.title == recipeTitle);
      await _saveRecipes(bookmarkedRecipes);
      debugPrint('Removed recipe: $recipeTitle. Total bookmarks: ${bookmarkedRecipes.length}');
    } catch (e) {
      debugPrint('Error removing bookmarked recipe: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearBookmarkedRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bookmarkedRecipesKey);
      debugPrint('Cleared all bookmarked recipes');
    } catch (e) {
      debugPrint('Error clearing bookmarked recipes: $e');
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
        if (recipe.vorhanden.any((ingredient) => 
            ingredient.toLowerCase().contains(foodName.toLowerCase()))) {
          // Move the ingredient from vorhanden to ueberpruefen
          final updatedVorhanden = recipe.vorhanden
              .where((ingredient) => 
                  !ingredient.toLowerCase().contains(foodName.toLowerCase()))
              .toList();
          
          final matchingIngredients = recipe.vorhanden
              .where((ingredient) => 
                  ingredient.toLowerCase().contains(foodName.toLowerCase()))
              .toList();
          
          final updatedUeberpruefen = [
            ...recipe.ueberpruefen,
            ...matchingIngredients,
          ];
          
          updatedRecipes.add(RecipeModel(
            title: recipe.title,
            cookingTime: recipe.cookingTime,
            vorhanden: updatedVorhanden,
            ueberpruefen: updatedUeberpruefen,
            instructions: recipe.instructions,
            isBookmarked: recipe.isBookmarked,
          ));
        } else {
          // Recipe doesn't contain the deleted food, keep as is
          updatedRecipes.add(recipe);
        }
      }
      
      await _saveRecipes(updatedRecipes);
      debugPrint('Updated recipes after deletion of: $foodName');
    } catch (e) {
      debugPrint('Error updating recipes after food deletion: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateAllBookmarkedRecipes(List<RecipeModel> recipes) async {
    try {
      await _saveRecipes(recipes);
      debugPrint('Updated all bookmarked recipes. Total: ${recipes.length}');
    } catch (e) {
      debugPrint('Error updating all bookmarked recipes: $e');
      rethrow;
    }
  }
}