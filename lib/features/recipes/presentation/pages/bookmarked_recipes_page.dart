import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/recipe_bloc.dart';
import '../bloc/recipe_event.dart';
import '../bloc/recipe_state.dart';
import '../widgets/recipe_card.dart';

class BookmarkedRecipesPage extends StatelessWidget {
  const BookmarkedRecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gespeicherte Rezepte'),
        centerTitle: true,
      ),
      body: BlocBuilder<RecipeBloc, RecipeState>(
        builder: (context, state) {
          if (state is RecipeLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is RecipeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Zurück'),
                  ),
                ],
              ),
            );
          }

          if (state is BookmarkedRecipesLoaded) {
            if (state.bookmarkedRecipes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keine gespeicherten Rezepte',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Speichern Sie Rezepte durch Tippen auf das Bookmark-Symbol',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.bookmarkedRecipes.length,
              itemBuilder: (context, index) {
                final recipe = state.bookmarkedRecipes[index];
                return RecipeCard(
                  recipe: recipe,
                  onBookmark: () {
                    context.read<RecipeBloc>().add(
                      RemoveBookmarkEvent(recipeTitle: recipe.title),
                    );
                  },
                );
              },
            );
          }

          return const Center(
            child: Text('Keine gespeicherten Rezepte verfügbar'),
          );
        },
      ),
    );
  }
}