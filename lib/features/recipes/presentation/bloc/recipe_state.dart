import 'package:equatable/equatable.dart';
import '../../domain/entities/recipe.dart';

abstract class RecipeState extends Equatable {
  const RecipeState();

  @override
  List<Object> get props => [];
}

class RecipeInitial extends RecipeState {}

class RecipeLoading extends RecipeState {}

class RecipeLoaded extends RecipeState {
  final List<Recipe> recipes;
  final List<Recipe> previousRecipes;

  const RecipeLoaded({required this.recipes, this.previousRecipes = const []});

  @override
  List<Object> get props => [recipes, previousRecipes];

  RecipeLoaded copyWith({
    List<Recipe>? recipes,
    List<Recipe>? previousRecipes,
  }) {
    return RecipeLoaded(
      recipes: recipes ?? this.recipes,
      previousRecipes: previousRecipes ?? this.previousRecipes,
    );
  }
}

class BookmarkedRecipesLoaded extends RecipeState {
  final List<Recipe> bookmarkedRecipes;

  const BookmarkedRecipesLoaded({required this.bookmarkedRecipes});

  @override
  List<Object> get props => [bookmarkedRecipes];

  BookmarkedRecipesLoaded copyWith({List<Recipe>? bookmarkedRecipes}) {
    return BookmarkedRecipesLoaded(
      bookmarkedRecipes: bookmarkedRecipes ?? this.bookmarkedRecipes,
    );
  }
}

class RecipeError extends RecipeState {
  final String message;

  const RecipeError({required this.message});

  @override
  List<Object> get props => [message];
}
