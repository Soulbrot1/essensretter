import 'package:equatable/equatable.dart';
import '../../domain/entities/recipe.dart';

abstract class RecipeEvent extends Equatable {
  const RecipeEvent();

  @override
  List<Object> get props => [];
}

class GenerateRecipesEvent extends RecipeEvent {
  final List<String> availableIngredients;

  const GenerateRecipesEvent({required this.availableIngredients});

  @override
  List<Object> get props => [availableIngredients];
}

class BookmarkRecipeEvent extends RecipeEvent {
  final Recipe recipe;

  const BookmarkRecipeEvent({required this.recipe});

  @override
  List<Object> get props => [recipe];
}

class LoadBookmarkedRecipesEvent extends RecipeEvent {}

class RemoveBookmarkEvent extends RecipeEvent {
  final String recipeTitle;

  const RemoveBookmarkEvent({required this.recipeTitle});

  @override
  List<Object> get props => [recipeTitle];
}
