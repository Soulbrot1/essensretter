import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/demo_foods.dart';
import '../../domain/entities/food.dart';
import '../../domain/usecases/add_food_from_text.dart';
import '../../domain/usecases/add_foods.dart';
import '../../domain/usecases/delete_food.dart';
import '../../domain/usecases/get_all_foods.dart';
import '../../domain/usecases/get_foods_by_expiry.dart';
import '../../domain/usecases/parse_foods_from_text.dart';
import '../../domain/usecases/update_food.dart';
import '../../../recipes/domain/usecases/update_recipes_after_food_deletion.dart';
import '../../../statistics/domain/repositories/statistics_repository.dart';
import 'food_event.dart';
import 'food_state.dart';

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final GetAllFoods getAllFoods;
  final GetFoodsByExpiry getFoodsByExpiry;
  final AddFoodFromText addFoodFromText;
  final AddFoods addFoods;
  final ParseFoodsFromText parseFoodsFromText;
  final DeleteFood deleteFood;
  final UpdateFood updateFood;
  final UpdateRecipesAfterFoodDeletion updateRecipesAfterFoodDeletion;
  final StatisticsRepository statisticsRepository;

  FoodBloc({
    required this.getAllFoods,
    required this.getFoodsByExpiry,
    required this.addFoodFromText,
    required this.addFoods,
    required this.parseFoodsFromText,
    required this.deleteFood,
    required this.updateFood,
    required this.updateRecipesAfterFoodDeletion,
    required this.statisticsRepository,
  }) : super(FoodInitial()) {
    on<LoadFoodsEvent>(_onLoadFoods);
    on<AddFoodFromTextEvent>(_onAddFoodFromText);
    on<ShowFoodPreviewEvent>(_onShowFoodPreview);
    on<ConfirmFoodsEvent>(_onConfirmFoods);
    on<FilterFoodsByExpiryEvent>(_onFilterFoodsByExpiry);
    on<DeleteFoodEvent>(_onDeleteFood);
    on<ToggleConsumedEvent>(_onToggleConsumed);
    on<UpdateFoodEvent>(_onUpdateFood);
    on<SortFoodsEvent>(_onSortFoods);
    on<ClearConsumedFoodsEvent>(_onClearConsumedFoods);
    on<LoadDemoFoodsEvent>(_onLoadDemoFoods);
  }

  Future<void> _onLoadFoods(
    LoadFoodsEvent event,
    Emitter<FoodState> emit,
  ) async {
    emit(FoodLoading());
    
    final result = await getAllFoods(NoParams());
    
    await result.fold(
      (failure) async => emit(FoodError(failure.message)),
      (foods) async {
        List<Food> finalFoods = foods;
        
        // Lade Demo-Lebensmittel beim ersten App-Start
        if (foods.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final demoLoaded = prefs.getBool(DemoFoods.demoLoadedKey) ?? false;
          
          if (!demoLoaded) {
            final demoFoods = DemoFoods.createDemoFoods();
            final addResult = await addFoods(AddFoodsParams(foods: demoFoods));
            
            await addResult.fold(
              (failure) => null, // Ignore failure, continue with empty state
              (success) async {
                finalFoods = demoFoods;
                await prefs.setBool(DemoFoods.demoLoadedKey, true);
              },
            );
          }
        }
        
        final currentState = state;
        final sortOption = currentState is FoodLoaded ? currentState.sortOption : SortOption.date;
        final sortedFoods = _sortFoods(finalFoods, sortOption);
        emit(FoodLoaded(
          foods: sortedFoods,
          filteredFoods: sortedFoods,
          sortOption: sortOption,
        ));
      },
    );
  }

  Future<void> _onAddFoodFromText(
    AddFoodFromTextEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is FoodLoaded) {
      emit(FoodOperationInProgress(
        foods: currentState.foods,
        filteredFoods: currentState.filteredFoods,
        activeFilter: currentState.activeFilter,
        sortOption: currentState.sortOption,
      ));
    }

    final result = await addFoodFromText(
      AddFoodFromTextParams(text: event.text),
    );

    await result.fold(
      (failure) async {
        emit(FoodError(failure.message));
        await Future.delayed(const Duration(seconds: 2));
        if (currentState is FoodLoaded) {
          emit(currentState);
        } else {
          add(LoadFoodsEvent());
        }
      },
      (addedFoods) async {
        add(LoadFoodsEvent());
      },
    );
  }

  Future<void> _onShowFoodPreview(
    ShowFoodPreviewEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodLoaded) return;

    final result = await parseFoodsFromText(
      ParseFoodsFromTextParams(text: event.text),
    );

    result.fold(
      (failure) => emit(FoodError(failure.message)),
      (previewFoods) => emit(FoodPreviewReady(
        previewFoods: previewFoods,
        foods: currentState.foods,
        filteredFoods: currentState.filteredFoods,
        activeFilter: currentState.activeFilter,
        sortOption: currentState.sortOption,
      )),
    );
  }

  Future<void> _onConfirmFoods(
    ConfirmFoodsEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodPreviewReady) return;

    emit(FoodOperationInProgress(
      foods: currentState.foods,
      filteredFoods: currentState.filteredFoods,
      activeFilter: currentState.activeFilter,
    ));

    final result = await addFoods(AddFoodsParams(foods: event.foods));

    await result.fold(
      (failure) async {
        emit(FoodError(failure.message));
        await Future.delayed(const Duration(seconds: 2));
        emit(FoodLoaded(
          foods: currentState.foods,
          filteredFoods: currentState.filteredFoods,
          activeFilter: currentState.activeFilter,
          sortOption: currentState.sortOption,
        ));
      },
      (_) async {
        add(LoadFoodsEvent());
      },
    );
  }

  Future<void> _onFilterFoodsByExpiry(
    FilterFoodsByExpiryEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodLoaded) return;

    if (event.daysUntilExpiry == null) {
      emit(currentState.copyWith(
        filteredFoods: currentState.foods,
        clearActiveFilter: true,
      ));
    } else {
      final filtered = currentState.foods
          .where((food) => food.expiresInDays(event.daysUntilExpiry!))
          .toList();
      
      emit(currentState.copyWith(
        filteredFoods: filtered,
        activeFilter: event.daysUntilExpiry,
      ));
    }
  }

  Future<void> _onDeleteFood(
    DeleteFoodEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is FoodLoaded) {
      emit(FoodOperationInProgress(
        foods: currentState.foods,
        filteredFoods: currentState.filteredFoods,
        activeFilter: currentState.activeFilter,
        sortOption: currentState.sortOption,
      ));
    }

    final result = await deleteFood(DeleteFoodParams(id: event.id));

    result.fold(
      (failure) {
        emit(FoodError(failure.message));
        if (currentState is FoodLoaded) {
          emit(currentState);
        }
      },
      (_) => add(LoadFoodsEvent()),
    );
  }

  Future<void> _onToggleConsumed(
    ToggleConsumedEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodLoaded) return;

    // Get the food to be toggled
    final foodToToggle = currentState.foods.firstWhere(
      (food) => food.id == event.id,
      orElse: () => throw Exception('Food not found'),
    );

    // Toggle the consumed status
    final updatedFood = foodToToggle.copyWith(isConsumed: !foodToToggle.isConsumed);

    // If marking as consumed for the first time, update recipes and record stats
    if (!foodToToggle.isConsumed && updatedFood.isConsumed) {
      // Update recipes - move this food from "vorhanden" to "ueberpruefen" 
      await updateRecipesAfterFoodDeletion(
        UpdateRecipesParams(foodName: foodToToggle.name),
      );

      // Record in statistics as consumed
      await statisticsRepository.recordConsumedFood(
        foodToToggle.id,
        foodToToggle.name,
        foodToToggle.category,
      );
    }

    // Update the food in the database
    final result = await updateFood(updatedFood);

    result.fold(
      (failure) {
        emit(FoodError(failure.message));
        if (currentState is FoodLoaded) {
          emit(currentState);
        }
      },
      (_) => add(LoadFoodsEvent()),
    );
  }

  Future<void> _onUpdateFood(
    UpdateFoodEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is FoodLoaded) {
      emit(FoodOperationInProgress(
        foods: currentState.foods,
        filteredFoods: currentState.filteredFoods,
        activeFilter: currentState.activeFilter,
        sortOption: currentState.sortOption,
      ));
    }

    final result = await updateFood(event.food);

    result.fold(
      (failure) {
        emit(FoodError(failure.message));
        if (currentState is FoodLoaded) {
          emit(currentState);
        }
      },
      (_) => add(LoadFoodsEvent()),
    );
  }

  Future<void> _onSortFoods(
    SortFoodsEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodLoaded) return;

    final sortedFoods = _sortFoods(currentState.foods, event.sortOption);
    
    List<Food> filteredFoods;
    if (currentState.activeFilter != null) {
      filteredFoods = sortedFoods
          .where((food) => food.expiresInDays(currentState.activeFilter!))
          .toList();
    } else {
      filteredFoods = sortedFoods;
    }

    emit(currentState.copyWith(
      foods: sortedFoods,
      filteredFoods: filteredFoods,
      sortOption: event.sortOption,
    ));
  }

  List<Food> _sortFoods(List<Food> foods, SortOption sortOption) {
    final sorted = List<Food>.from(foods);
    
    switch (sortOption) {
      case SortOption.alphabetical:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.date:
        sorted.sort((a, b) {
          // Foods without expiry date go to the end
          if (a.expiryDate == null && b.expiryDate == null) return 0;
          if (a.expiryDate == null) return 1;
          if (b.expiryDate == null) return -1;
          return a.expiryDate!.compareTo(b.expiryDate!);
        });
        break;
      case SortOption.category:
        sorted.sort((a, b) {
          final categoryA = a.category ?? 'Sonstiges';
          final categoryB = b.category ?? 'Sonstiges';
          final categoryCompare = categoryA.compareTo(categoryB);
          if (categoryCompare != 0) return categoryCompare;
          // If same category, sort by name
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
    }
    
    return sorted;
  }

  Future<void> _onClearConsumedFoods(
    ClearConsumedFoodsEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodLoaded) return;

    // Find all consumed foods
    final consumedFoods = currentState.foods.where((food) => food.isConsumed).toList();
    
    if (consumedFoods.isEmpty) return;

    // Show loading state
    emit(FoodOperationInProgress(
      foods: currentState.foods,
      filteredFoods: currentState.filteredFoods,
      activeFilter: currentState.activeFilter,
      sortOption: currentState.sortOption,
    ));

    try {
      // Delete all consumed foods
      for (final food in consumedFoods) {
        await deleteFood(DeleteFoodParams(id: food.id));
      }

      // Reload the foods list
      add(LoadFoodsEvent());
    } catch (e) {
      emit(FoodError('Fehler beim Löschen verbrauchter Lebensmittel: $e'));
      if (currentState is FoodLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onLoadDemoFoods(
    LoadDemoFoodsEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is FoodLoaded) {
      emit(FoodOperationInProgress(
        foods: currentState.foods,
        filteredFoods: currentState.filteredFoods,
        activeFilter: currentState.activeFilter,
        sortOption: currentState.sortOption,
      ));
    }

    try {
      final demoFoods = DemoFoods.createDemoFoods();
      final addResult = await addFoods(AddFoodsParams(foods: demoFoods));
      
      addResult.fold(
        (failure) => emit(FoodError('Fehler beim Laden der Demo-Lebensmittel: ${failure.message}')),
        (success) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(DemoFoods.demoLoadedKey, true);
          add(LoadFoodsEvent()); // Reload foods list
        },
      );
    } catch (e) {
      emit(FoodError('Fehler beim Laden der Demo-Lebensmittel: $e'));
    }
  }

  List<Food> _sortFoodsByExpiry(List<Food> foods) {
    return _sortFoods(foods, SortOption.date);
  }
}