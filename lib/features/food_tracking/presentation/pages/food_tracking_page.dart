import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_event.dart';
import '../bloc/food_state.dart';
import '../widgets/food_card.dart';
import '../widgets/food_preview_dialog.dart';
import '../widgets/recipe_generation_button.dart';
import '../widgets/food_filter_bar.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

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
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/image.png',
              height: 40,
              width: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: Colors.white,
                    size: 20,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'Food Rescue',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<SettingsBloc>(),
                    child: const SettingsPage(),
                  ),
                ),
              );
            },
            tooltip: 'Einstellungen',
          ),
        ],
      ),
      body: Column(
        children: [
          const FoodFilterBar(),
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
}