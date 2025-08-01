import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';

abstract class RecipeLocalDataSource {
  Future<List<RecipeModel>> getBookmarkedRecipes();
  Future<void> saveBookmarkedRecipe(RecipeModel recipe);
  Future<void> removeBookmarkedRecipe(String recipeTitle);
  Future<void> clearBookmarkedRecipes();
}

class RecipeLocalDataSourceImpl implements RecipeLocalDataSource {
  // In-memory storage for now (later can be replaced with SharedPreferences or SQLite)
  static final List<RecipeModel> _bookmarkedRecipes = [];

  @override
  Future<List<RecipeModel>> getBookmarkedRecipes() async {
    try {
      debugPrint('Loading ${_bookmarkedRecipes.length} bookmarked recipes');
      return List.from(_bookmarkedRecipes);
    } catch (e) {
      debugPrint('Error loading bookmarked recipes: $e');
      return [];
    }
  }

  @override
  Future<void> saveBookmarkedRecipe(RecipeModel recipe) async {
    try {
      // Check if recipe already exists (by title)
      final existingIndex = _bookmarkedRecipes.indexWhere(
        (r) => r.title == recipe.title,
      );
      
      if (existingIndex >= 0) {
        // Update existing recipe
        _bookmarkedRecipes[existingIndex] = recipe.copyWith(isBookmarked: true);
      } else {
        // Add new recipe
        _bookmarkedRecipes.add(recipe.copyWith(isBookmarked: true));
      }

      debugPrint('Saved recipe: ${recipe.title}. Total bookmarks: ${_bookmarkedRecipes.length}');
    } catch (e) {
      debugPrint('Error saving bookmarked recipe: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeBookmarkedRecipe(String recipeTitle) async {
    try {
      _bookmarkedRecipes.removeWhere((recipe) => recipe.title == recipeTitle);
      debugPrint('Removed recipe: $recipeTitle. Total bookmarks: ${_bookmarkedRecipes.length}');
    } catch (e) {
      debugPrint('Error removing bookmarked recipe: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearBookmarkedRecipes() async {
    try {
      _bookmarkedRecipes.clear();
      debugPrint('Cleared all bookmarked recipes');
    } catch (e) {
      debugPrint('Error clearing bookmarked recipes: $e');
      rethrow;
    }
  }
}