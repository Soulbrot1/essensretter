import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../recipes/presentation/bloc/recipe_bloc.dart';
import '../../../recipes/presentation/bloc/recipe_event.dart';
import '../../../recipes/presentation/pages/recipes_page.dart';
import '../../../recipes/presentation/pages/bookmarked_recipes_page.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_state.dart';
import '../../../../injection_container.dart' as di;

class RecipeGenerationButton extends StatelessWidget {
  const RecipeGenerationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodBloc, FoodState>(
      builder: (context, state) {
        if (state is! FoodLoaded) {
          return const SizedBox.shrink();
        }

        if (state.foods.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generateRecipes(context, state.foods),
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Rezepte generieren'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _showBookmarkedRecipes(context),
                  icon: const Icon(Icons.bookmark, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  tooltip: 'Gespeicherte Rezepte',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _generateRecipes(BuildContext context, List foods) {
    // Prioritize foods expiring in the next 7 days
    final expiringFoods = foods
        .where((food) => food.daysUntilExpiry <= 7 && !food.isConsumed)
        .map((food) => food.name as String)
        .toList();

    // If no foods are expiring soon, use all available foods
    final availableIngredients = expiringFoods.isNotEmpty
        ? expiringFoods
        : foods
            .where((food) => !food.isConsumed)
            .map((food) => food.name as String)
            .toList();

    if (availableIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine verfügbaren Lebensmittel für Rezepte gefunden'),
        ),
      );
      return;
    }

    // Generate recipes and navigate to recipes page
    final recipeBloc = di.sl<RecipeBloc>();
    recipeBloc.add(
      GenerateRecipesEvent(availableIngredients: availableIngredients),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: recipeBloc,
          child: RecipesPage(availableIngredients: availableIngredients),
        ),
      ),
    );
  }

  void _showBookmarkedRecipes(BuildContext context) {
    final recipeBloc = di.sl<RecipeBloc>();
    recipeBloc.add(LoadBookmarkedRecipesEvent());

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: recipeBloc,
          child: const BookmarkedRecipesPage(),
        ),
      ),
    );
  }
}