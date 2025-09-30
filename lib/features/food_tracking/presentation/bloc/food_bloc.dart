import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
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
    on<SearchFoodsByNameEvent>(_onSearchFoodsByName);
    on<DeleteFoodEvent>(_onDeleteFood);
    on<ToggleConsumedEvent>(_onToggleConsumed);
    on<UpdateFoodEvent>(_onUpdateFood);
    on<SortFoodsEvent>(_onSortFoods);
    on<ClearConsumedFoodsEvent>(_onClearConsumedFoods);
    on<FilterSharedFoodsEvent>(_onFilterSharedFoods);
  }

  Future<void> _onLoadFoods(
    LoadFoodsEvent event,
    Emitter<FoodState> emit,
  ) async {
    emit(FoodLoading());

    final result = await getAllFoods(NoParams());

    await result.fold((failure) async => emit(FoodError(failure.message)), (
      foods,
    ) async {
      List<Food> finalFoods = foods;

      final currentState = state;
      final sortOption = currentState is FoodLoaded
          ? currentState.sortOption
          : SortOption.date;
      final sortedFoods = _sortFoods(finalFoods, sortOption);
      emit(
        FoodLoaded(
          foods: sortedFoods,
          filteredFoods: sortedFoods,
          sortOption: sortOption,
        ),
      );
    });
  }

  Future<void> _onAddFoodFromText(
    AddFoodFromTextEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is FoodLoaded) {
      emit(
        FoodOperationInProgress(
          foods: currentState.foods,
          filteredFoods: currentState.filteredFoods,
          activeFilter: currentState.activeFilter,
          sortOption: currentState.sortOption,
        ),
      );
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
      (previewFoods) => emit(
        FoodPreviewReady(
          previewFoods: previewFoods,
          foods: currentState.foods,
          filteredFoods: currentState.filteredFoods,
          activeFilter: currentState.activeFilter,
          sortOption: currentState.sortOption,
        ),
      ),
    );
  }

  Future<void> _onConfirmFoods(
    ConfirmFoodsEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodPreviewReady) return;

    emit(
      FoodOperationInProgress(
        foods: currentState.foods,
        filteredFoods: currentState.filteredFoods,
        activeFilter: currentState.activeFilter,
      ),
    );

    final result = await addFoods(AddFoodsParams(foods: event.foods));

    await result.fold(
      (failure) async {
        emit(FoodError(failure.message));
        await Future.delayed(const Duration(seconds: 2));
        emit(
          FoodLoaded(
            foods: currentState.foods,
            filteredFoods: currentState.filteredFoods,
            activeFilter: currentState.activeFilter,
            sortOption: currentState.sortOption,
          ),
        );
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

    List<Food> filtered = currentState.foods;

    // Erst nach Namen filtern, falls Suchtext vorhanden
    if (currentState.searchText.isNotEmpty) {
      filtered = filtered
          .where(
            (food) => food.name.toLowerCase().contains(
              currentState.searchText.toLowerCase(),
            ),
          )
          .toList();
    }

    // Dann nach Ablaufdatum filtern
    if (event.daysUntilExpiry != null) {
      filtered = filtered
          .where((food) => food.expiresInDays(event.daysUntilExpiry!))
          .toList();
    }

    // Apply shared filter if active
    if (currentState.showOnlyShared) {
      filtered = filtered.where((food) => food.isShared).toList();
    }

    emit(
      currentState.copyWith(
        filteredFoods: filtered,
        activeFilter: event.daysUntilExpiry,
        clearActiveFilter: event.daysUntilExpiry == null,
      ),
    );
  }

  Future<void> _onSearchFoodsByName(
    SearchFoodsByNameEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodLoaded) return;

    List<Food> filtered = currentState.foods;

    // Erst nach Namen filtern
    if (event.searchText.isNotEmpty) {
      filtered = filtered
          .where(
            (food) => food.name.toLowerCase().contains(
              event.searchText.toLowerCase(),
            ),
          )
          .toList();
    }

    // Dann bestehenden Datumsfilter anwenden
    if (currentState.activeFilter != null) {
      filtered = filtered
          .where((food) => food.expiresInDays(currentState.activeFilter!))
          .toList();
    }

    // Apply shared filter if active
    if (currentState.showOnlyShared) {
      filtered = filtered.where((food) => food.isShared).toList();
    }

    emit(
      currentState.copyWith(
        filteredFoods: filtered,
        searchText: event.searchText,
      ),
    );
  }

  Future<void> _onDeleteFood(
    DeleteFoodEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is FoodLoaded) {
      emit(
        FoodOperationInProgress(
          foods: currentState.foods,
          filteredFoods: currentState.filteredFoods,
          activeFilter: currentState.activeFilter,
          sortOption: currentState.sortOption,
        ),
      );

      // Wenn es weggeworfen wurde, in Statistik erfassen
      if (event.wasDisposed) {
        final foodToDelete = currentState.foods.firstWhere(
          (food) => food.id == event.id,
          orElse: () => throw Exception('Food not found'),
        );

        // In Statistik als weggeworfen erfassen
        await statisticsRepository.recordWastedFood(
          foodToDelete.id,
          foodToDelete.name,
          foodToDelete.category,
        );
      }
    }

    final result = await deleteFood(DeleteFoodParams(id: event.id));

    result.fold((failure) {
      emit(FoodError(failure.message));
      if (currentState is FoodLoaded) {
        emit(currentState);
      }
    }, (_) => add(LoadFoodsEvent()));
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
    final updatedFood = foodToToggle.copyWith(
      isConsumed: !foodToToggle.isConsumed,
    );

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
        emit(currentState);
      },
      (_) {
        // Update local state and maintain filters
        final updatedFoods = currentState.foods.map((food) {
          return food.id == event.id ? updatedFood : food;
        }).toList();

        final sortedFoods = _sortFoods(updatedFoods, currentState.sortOption);

        // Re-apply current filters
        List<Food> filtered = sortedFoods;

        // Apply search filter if active
        if (currentState.searchText.isNotEmpty) {
          filtered = filtered
              .where(
                (food) => food.name.toLowerCase().contains(
                  currentState.searchText.toLowerCase(),
                ),
              )
              .toList();
        }

        // Apply expiry filter if active
        if (currentState.activeFilter != null) {
          filtered = filtered
              .where((food) => food.expiresInDays(currentState.activeFilter!))
              .toList();
        }

        emit(
          currentState.copyWith(foods: sortedFoods, filteredFoods: filtered),
        );
      },
    );
  }

  Future<void> _onUpdateFood(
    UpdateFoodEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is FoodLoaded) {
      emit(
        FoodOperationInProgress(
          foods: currentState.foods,
          filteredFoods: currentState.filteredFoods,
          activeFilter: currentState.activeFilter,
          sortOption: currentState.sortOption,
        ),
      );
    }

    final result = await updateFood(event.food);

    result.fold((failure) {
      emit(FoodError(failure.message));
      if (currentState is FoodLoaded) {
        emit(currentState);
      }
    }, (_) => add(LoadFoodsEvent()));
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

    emit(
      currentState.copyWith(
        foods: sortedFoods,
        filteredFoods: filteredFoods,
        sortOption: event.sortOption,
      ),
    );
  }

  List<Food> _sortFoods(List<Food> foods, SortOption sortOption) {
    final sorted = List<Food>.from(foods);

    switch (sortOption) {
      case SortOption.alphabetical:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
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
    final consumedFoods = currentState.foods
        .where((food) => food.isConsumed)
        .toList();

    if (consumedFoods.isEmpty) return;

    // Show loading state
    emit(
      FoodOperationInProgress(
        foods: currentState.foods,
        filteredFoods: currentState.filteredFoods,
        activeFilter: currentState.activeFilter,
        sortOption: currentState.sortOption,
      ),
    );

    try {
      // Delete all consumed foods
      for (final food in consumedFoods) {
        await deleteFood(DeleteFoodParams(id: food.id));
      }

      // Reload the foods list
      add(LoadFoodsEvent());
    } catch (e) {
      emit(FoodError('Fehler beim Löschen verbrauchter Lebensmittel: $e'));
      emit(currentState);
    }
  }

  Future<void> _onFilterSharedFoods(
    FilterSharedFoodsEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodLoaded) return;

    List<Food> filtered = currentState.foods;

    // Apply search filter first if active
    if (currentState.searchText.isNotEmpty) {
      filtered = filtered
          .where(
            (food) => food.name.toLowerCase().contains(
              currentState.searchText.toLowerCase(),
            ),
          )
          .toList();
    }

    // Apply expiry filter if active
    if (currentState.activeFilter != null) {
      filtered = filtered
          .where((food) => food.expiresInDays(currentState.activeFilter!))
          .toList();
    }

    // Apply shared filter
    if (event.showOnlyShared) {
      filtered = filtered.where((food) => food.isShared).toList();
    }

    emit(
      currentState.copyWith(
        filteredFoods: filtered,
        showOnlyShared: event.showOnlyShared,
      ),
    );
  }
}
