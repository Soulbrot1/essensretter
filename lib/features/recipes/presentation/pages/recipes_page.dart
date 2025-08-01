import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/recipe_bloc.dart';
import '../bloc/recipe_event.dart';
import '../bloc/recipe_state.dart';
import '../widgets/recipe_card.dart';
import 'bookmarked_recipes_page.dart';
import '../../../../injection_container.dart' as di;

class RecipesPage extends StatelessWidget {
  final List<String>? availableIngredients;
  
  const RecipesPage({super.key, this.availableIngredients});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'KI-Rezeptvorschläge',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _regenerateRecipe(context),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Neues Rezept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBookmarkedRecipes(context),
                    icon: const Icon(Icons.bookmark_border, color: Colors.orange),
                    label: const Text('Gespeicherte', style: TextStyle(color: Colors.orange)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<RecipeBloc, RecipeState>(
              builder: (context, state) {
                if (state is RecipeLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Rezepte werden generiert...'),
                      ],
                    ),
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

                if (state is RecipeLoaded) {
                  if (state.recipes.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Keine Rezepte gefunden',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: state.recipes.isNotEmpty
                        ? RecipeCard(
                            recipe: state.recipes.first,
                            onBookmark: () {
                              context.read<RecipeBloc>().add(
                                BookmarkRecipeEvent(recipe: state.recipes.first),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  );
                }

                return const Center(
                  child: Text('Keine Rezepte verfügbar'),
                );
              },
            ),
          ),
        ],
      );
  }

  void _regenerateRecipe(BuildContext context) {
    if (availableIngredients != null && availableIngredients!.isNotEmpty) {
      context.read<RecipeBloc>().add(
        GenerateRecipesEvent(availableIngredients: availableIngredients!),
      );
    }
  }

  void _showBookmarkedRecipes(BuildContext context) {
    final recipeBloc = di.sl<RecipeBloc>();
    recipeBloc.add(LoadBookmarkedRecipesEvent());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.93,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BlocProvider.value(
          value: recipeBloc,
          child: const BookmarkedRecipesPage(),
        ),
      ),
    );
  }
}