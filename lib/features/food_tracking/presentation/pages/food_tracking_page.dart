import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_event.dart';
import '../bloc/food_state.dart';
import '../widgets/expiry_filter_chips.dart';
import '../widgets/food_card.dart';
import '../widgets/food_input_field.dart';
import '../widgets/food_preview_dialog.dart';
import '../widgets/recipe_generation_button.dart';

class FoodTrackingPage extends StatefulWidget {
  const FoodTrackingPage({super.key});

  @override
  State<FoodTrackingPage> createState() => _FoodTrackingPageState();
}

class _FoodTrackingPageState extends State<FoodTrackingPage> {
  @override
  void initState() {
    super.initState();
    context.read<FoodBloc>().add(LoadFoodsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Essensretter 3'),
        centerTitle: true,
        actions: [
          BlocBuilder<FoodBloc, FoodState>(
            builder: (context, state) {
              if (state is FoodLoaded && _hasConsumedFoods(state.foods)) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showDeleteConsumedDialog(context),
                  tooltip: 'Verbrauchte Lebensmittel löschen',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const FoodInputField(),
          const Divider(),
          const ExpiryFilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: BlocListener<FoodBloc, FoodState>(
              listener: (context, state) {
                if (state is FoodPreviewReady) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => FoodPreviewDialog(
                      foods: state.previewFoods,
                      onConfirm: (confirmedFoods) {
                        Navigator.of(dialogContext).pop();
                        context.read<FoodBloc>().add(
                          ConfirmFoodsEvent(confirmedFoods),
                        );
                      },
                      onCancel: () {
                        Navigator.of(dialogContext).pop();
                        context.read<FoodBloc>().add(LoadFoodsEvent());
                      },
                    ),
                  );
                }
              },
              child: BlocBuilder<FoodBloc, FoodState>(
                builder: (context, state) {
                if (state is FoodLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (state is FoodError) {
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
                          onPressed: () {
                            context.read<FoodBloc>().add(LoadFoodsEvent());
                          },
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (state is FoodLoaded || state is FoodOperationInProgress) {
                  final foods = state is FoodLoaded 
                      ? state.filteredFoods 
                      : (state as FoodOperationInProgress).filteredFoods;
                  
                  if (foods.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Keine Lebensmittel vorhanden',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fügen Sie Lebensmittel über das Eingabefeld hinzu',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Stack(
                    children: [
                      ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: foods.length,
                        itemBuilder: (context, index) {
                          return FoodCard(food: foods[index]);
                        },
                      ),
                      if (state is FoodOperationInProgress)
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  );
                }
                
                return const SizedBox.shrink();
              },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const RecipeGenerationButton(),
    );
  }

  bool _hasConsumedFoods(List foods) {
    return foods.any((food) => food.isConsumed);
  }

  void _showDeleteConsumedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Verbrauchte Lebensmittel löschen'),
          content: const Text(
            'Möchten Sie alle als verbraucht markierten Lebensmittel dauerhaft löschen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteAllConsumedFoods(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAllConsumedFoods(BuildContext context) async {
    final foodBloc = context.read<FoodBloc>();
    final currentState = foodBloc.state;
    
    if (currentState is FoodLoaded) {
      final consumedFoods = currentState.foods.where((food) => food.isConsumed).toList();
      
      // Delete each consumed food
      for (final food in consumedFoods) {
        foodBloc.add(DeleteFoodEvent(id: food.id));
      }
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${consumedFoods.length} verbrauchte Lebensmittel gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}