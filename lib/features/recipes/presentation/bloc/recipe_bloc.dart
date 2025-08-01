import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/usecases/generate_recipes.dart';
import '../../domain/usecases/get_bookmarked_recipes.dart';
import '../../domain/usecases/save_bookmarked_recipe.dart';
import '../../domain/usecases/remove_bookmarked_recipe.dart';
import 'recipe_event.dart';
import 'recipe_state.dart';

class RecipeBloc extends Bloc<RecipeEvent, RecipeState> {
  final GenerateRecipes generateRecipes;
  final GetBookmarkedRecipes getBookmarkedRecipes;
  final SaveBookmarkedRecipe saveBookmarkedRecipe;
  final RemoveBookmarkedRecipe removeBookmarkedRecipe;

  RecipeBloc({
    required this.generateRecipes,
    required this.getBookmarkedRecipes,
    required this.saveBookmarkedRecipe,
    required this.removeBookmarkedRecipe,
  }) : super(RecipeInitial()) {
    on<GenerateRecipesEvent>(_onGenerateRecipes);
    on<BookmarkRecipeEvent>(_onBookmarkRecipe);
    on<LoadBookmarkedRecipesEvent>(_onLoadBookmarkedRecipes);
    on<RemoveBookmarkEvent>(_onRemoveBookmark);
  }

  Future<void> _onGenerateRecipes(
    GenerateRecipesEvent event,
    Emitter<RecipeState> emit,
  ) async {
    emit(RecipeLoading());

    final result = await generateRecipes(
      GenerateRecipesParams(availableIngredients: event.availableIngredients),
    );

    result.fold(
      (failure) => emit(RecipeError(message: failure.message)),
      (recipes) => emit(RecipeLoaded(recipes: recipes)),
    );
  }

  Future<void> _onBookmarkRecipe(
    BookmarkRecipeEvent event,
    Emitter<RecipeState> emit,
  ) async {
    final recipe = event.recipe;
    
    if (recipe.isBookmarked) {
      // Remove bookmark
      await removeBookmarkedRecipe(
        RemoveBookmarkedRecipeParams(recipeTitle: recipe.title),
      );
    } else {
      // Add bookmark
      await saveBookmarkedRecipe(
        SaveBookmarkedRecipeParams(recipe: recipe.copyWith(isBookmarked: true)),
      );
    }

    // Update current state if it's RecipeLoaded
    final currentState = state;
    if (currentState is RecipeLoaded) {
      final updated = currentState.recipes.map((r) {
        if (r.title == recipe.title) {
          return r.copyWith(isBookmarked: !r.isBookmarked);
        }
        return r;
      }).toList();
      
      emit(currentState.copyWith(recipes: updated));
    }
  }

  Future<void> _onLoadBookmarkedRecipes(
    LoadBookmarkedRecipesEvent event,
    Emitter<RecipeState> emit,
  ) async {
    emit(RecipeLoading());

    final result = await getBookmarkedRecipes(NoParams());

    result.fold(
      (failure) => emit(RecipeError(message: failure.message)),
      (recipes) => emit(BookmarkedRecipesLoaded(bookmarkedRecipes: recipes)),
    );
  }

  Future<void> _onRemoveBookmark(
    RemoveBookmarkEvent event,
    Emitter<RecipeState> emit,
  ) async {
    await removeBookmarkedRecipe(
      RemoveBookmarkedRecipeParams(recipeTitle: event.recipeTitle),
    );

    // Reload bookmarked recipes if currently viewing them
    final currentState = state;
    if (currentState is BookmarkedRecipesLoaded) {
      add(LoadBookmarkedRecipesEvent());
    }
  }
}