import '../models/recipe_model.dart';

abstract class RecipeService {
  Future<List<RecipeModel>> generateRecipes(List<String> availableIngredients);
}