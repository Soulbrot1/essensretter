import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../recipes/presentation/bloc/recipe_bloc.dart';
import '../../../recipes/presentation/bloc/recipe_event.dart';
import '../../../recipes/presentation/pages/recipes_page.dart';
import '../../../recipes/presentation/pages/bookmarked_recipes_page.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_state.dart';
import '../bloc/food_event.dart';
import 'dictation_text_field.dart';
import '../../../../injection_container.dart' as di;

class RecipeGenerationButton extends StatelessWidget {
  const RecipeGenerationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodBloc, FoodState>(
      builder: (context, state) {
        final bool hasFood = state is FoodLoaded && state.foods.isNotEmpty;
        final List availableFoods = state is FoodLoaded ? state.foods : [];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Hinzufügen Button
                IconButton(
                  onPressed: () => _showAddFoodDialog(context),
                  icon: const Icon(Icons.add, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  tooltip: 'Lebensmittel hinzufügen',
                ),
                // Rezepte Button (nur Icon)
                IconButton(
                  onPressed: hasFood ? () => _generateRecipes(context, availableFoods) : null,
                  icon: const Icon(Icons.restaurant_menu, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: hasFood ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  tooltip: 'Rezepte generieren',
                ),
                // Bookmark Button
                IconButton(
                  onPressed: () => _showBookmarkedRecipes(context),
                  icon: const Icon(Icons.bookmark, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
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
          child: RecipesPage(availableIngredients: availableIngredients),
        ),
      ),
    );
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

  void _showAddFoodDialog(BuildContext context) {
    final foodBloc = context.read<FoodBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: foodBloc,
        child: const AddFoodBottomSheet(),
      ),
    );
  }


}


class AddFoodBottomSheet extends StatefulWidget {
  const AddFoodBottomSheet({super.key});

  @override
  State<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<AddFoodBottomSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitText() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<FoodBloc>().add(ShowFoodPreviewEvent(text));
      _controller.clear();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lebensmittel hinzufügen',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Text Field mit Diktierfunktion
              DictationTextField(
                controller: _controller,
                hintText: 'z.B. "Honig 5 Tage, Salami 4.08, Milch morgen"',
                onSubmitted: _submitText,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}