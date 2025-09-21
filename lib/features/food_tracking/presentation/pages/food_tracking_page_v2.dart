import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/food_data_bloc.dart';
import '../bloc/food_data_event.dart';
import '../bloc/food_data_state.dart';
import '../bloc/food_ui_bloc.dart';
import '../bloc/food_ui_event.dart';
import '../bloc/food_ui_state.dart';
import '../bloc/food_bloc_coordinator.dart';
import '../widgets/food_card.dart';
import '../widgets/food_preview_dialog.dart';
import '../widgets/recipe_generation_button.dart';
import '../widgets/food_filter_bar.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../domain/entities/food.dart';

/// Neue Version der FoodTrackingPage mit aufgeteilten BLoCs
class FoodTrackingPageV2 extends StatefulWidget {
  const FoodTrackingPageV2({super.key});

  @override
  State<FoodTrackingPageV2> createState() => _FoodTrackingPageV2State();
}

class _FoodTrackingPageV2State extends State<FoodTrackingPageV2> {
  late final FoodDataBloc _dataBloc;
  late final FoodUIBloc _uiBloc;
  late final FoodBlocCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _dataBloc = di.sl<FoodDataBloc>();
    _uiBloc = di.sl<FoodUIBloc>();

    _coordinator = FoodBlocCoordinator(dataBloc: _dataBloc, uiBloc: _uiBloc);

    // Initial load
    _dataBloc.add(LoadFoodsEvent());
  }

  @override
  void dispose() {
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FoodDataBloc>.value(value: _dataBloc),
        BlocProvider<FoodUIBloc>.value(value: _uiBloc),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          title: const Text(
            'Lebensmittel',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (_) => di.sl<SettingsBloc>(),
                      child: const SettingsPage(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocListener<FoodDataBloc, FoodDataState>(
          listener: (context, state) {
            if (state is FoodDataError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocListener<FoodUIBloc, FoodUIState>(
            listener: (context, state) {
              if (state is FoodPreviewReady) {
                _showFoodPreviewDialog(context, state.previewFoods);
              } else if (state is FoodUIError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Column(
              children: [
                // Filter Bar
                FoodFilterBarV2(),

                // Food List
                Expanded(
                  child: BlocBuilder<FoodUIBloc, FoodUIState>(
                    builder: (context, uiState) {
                      return BlocBuilder<FoodDataBloc, FoodDataState>(
                        builder: (context, dataState) {
                          if (dataState is FoodDataLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (dataState is FoodDataError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Fehler beim Laden',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    dataState.message,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _dataBloc.add(LoadFoodsEvent()),
                                    child: const Text('Erneut versuchen'),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (uiState is FoodUILoaded) {
                            final foods = uiState.filteredFoods;

                            if (foods.isEmpty) {
                              return _buildEmptyState(context);
                            }

                            return _buildFoodList(
                              context,
                              foods,
                              uiState.sortOption,
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine Lebensmittel',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Füge deine ersten Lebensmittel hinzu!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(
    BuildContext context,
    List<Food> foods,
    SortOption sortOption,
  ) {
    if (sortOption == SortOption.category) {
      return _buildGroupedFoodList(context, foods);
    }

    return RefreshIndicator(
      onRefresh: () async => _dataBloc.add(LoadFoodsEvent()),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: foods.length + 1, // +1 for recipe button
        itemBuilder: (context, index) {
          if (index == foods.length) {
            return const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 32),
              child: RecipeGenerationButton(),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FoodCard(food: foods[index]),
          );
        },
      ),
    );
  }

  Widget _buildGroupedFoodList(BuildContext context, List<Food> foods) {
    final groupedFoods = <String, List<Food>>{};

    for (final food in foods) {
      final category = food.category ?? 'Unbekannt';
      groupedFoods.putIfAbsent(category, () => []).add(food);
    }

    return RefreshIndicator(
      onRefresh: () async => _dataBloc.add(LoadFoodsEvent()),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedFoods.keys.length + 1, // +1 for recipe button
        itemBuilder: (context, index) {
          if (index == groupedFoods.keys.length) {
            return const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 32),
              child: RecipeGenerationButton(),
            );
          }

          final category = groupedFoods.keys.elementAt(index);
          final categoryFoods = groupedFoods[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              ...categoryFoods.map(
                (food) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FoodCard(food: food),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFoodPreviewDialog(BuildContext context, List<Food> previewFoods) {
    showDialog(
      context: context,
      builder: (context) => FoodPreviewDialog(
        foods: previewFoods,
        onConfirm: (confirmedFoods) {
          Navigator.of(context).pop();
          _dataBloc.add(ConfirmFoodsEvent(confirmedFoods));
          _uiBloc.add(HideFoodPreviewEvent());
        },
        onCancel: () {
          Navigator.of(context).pop();
          _uiBloc.add(HideFoodPreviewEvent());
        },
      ),
    );
  }
}

/// Angepasste FoodFilterBar für die neuen BLoCs
class FoodFilterBarV2 extends StatelessWidget {
  const FoodFilterBarV2({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodUIBloc, FoodUIState>(
      builder: (context, state) {
        if (state is! FoodUILoaded) {
          return const SizedBox.shrink();
        }

        return const FoodFilterBar();
      },
    );
  }
}
