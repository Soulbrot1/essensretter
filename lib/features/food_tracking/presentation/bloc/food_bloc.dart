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
import '../../../sharing/presentation/services/shared_foods_loader_service.dart';
import '../../../sharing/presentation/services/supabase_food_sync_service.dart';
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
    on<LoadFoodsWithSharedEvent>(_onLoadFoodsWithShared);
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
          showOnlyShared: false,
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
        add(const LoadFoodsWithSharedEvent());
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

    // Apply shared filter if specified in event, or keep current state
    final shouldShowOnlyShared =
        event.showOnlyShared ?? currentState.showOnlyShared;
    if (shouldShowOnlyShared) {
      filtered = filtered.where((food) => food.isShared).toList();
    }

    emit(
      currentState.copyWith(
        filteredFoods: filtered,
        activeFilter: event.daysUntilExpiry,
        clearActiveFilter: event.daysUntilExpiry == null,
        showOnlyShared: shouldShowOnlyShared,
        sortOption: shouldShowOnlyShared
            ? SortOption.shared
            : (currentState.sortOption == SortOption.shared
                  ? SortOption.date
                  : currentState.sortOption),
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
      // Check if this is a shared food (from a friend) - cannot be deleted
      if (SharedFoodsLoaderService.isSharedFoodId(event.id)) {
        emit(
          FoodError(
            'Geteilte Lebensmittel von Friends können nicht gelöscht werden',
          ),
        );
        emit(currentState);
        return;
      }
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

      // If this is a shared food from a friend, delete it from Supabase
      if (SharedFoodsLoaderService.isSharedFoodId(foodToToggle.id)) {
        try {
          // Extract the original Supabase ID and friend ID
          final originalSupabaseId =
              SharedFoodsLoaderService.getOriginalSupabaseId(foodToToggle.id);
          final friendId = SharedFoodsLoaderService.getFriendIdFromSharedFood(
            foodToToggle.id,
          );

          if (originalSupabaseId != null && friendId != null) {
            // Delete from Supabase so it doesn't appear for other users
            await SupabaseFoodSyncService.client
                .from('shared_foods')
                .delete()
                .eq('id', originalSupabaseId)
                .eq('user_id', friendId);
          }
        } catch (e) {
          // Non-critical error - don't fail the whole operation
        }
      }
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

        // Apply shared filter if active
        if (currentState.showOnlyShared) {
          filtered = filtered.where((food) => food.isShared).toList();
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
    if (currentState is! FoodLoaded) return;

    // Check if this is a shared food (from a friend) - cannot be updated
    if (SharedFoodsLoaderService.isSharedFoodId(event.food.id)) {
      emit(
        FoodError(
          'Geteilte Lebensmittel von Friends können nicht bearbeitet werden',
        ),
      );
      emit(currentState);
      return;
    }

    emit(
      FoodOperationInProgress(
        foods: currentState.foods,
        filteredFoods: currentState.filteredFoods,
        activeFilter: currentState.activeFilter,
        sortOption: currentState.sortOption,
      ),
    );

    final result = await updateFood(event.food);

    result.fold(
      (failure) {
        emit(FoodError(failure.message));
        emit(currentState);
      },
      (_) {
        // Update local state and maintain filters
        final updatedFoods = currentState.foods.map((food) {
          return food.id == event.food.id ? event.food : food;
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

        // Apply shared filter if active
        if (currentState.showOnlyShared) {
          filtered = filtered.where((food) => food.isShared).toList();
        }

        emit(
          currentState.copyWith(foods: sortedFoods, filteredFoods: filtered),
        );
      },
    );
  }

  Future<void> _onSortFoods(
    SortFoodsEvent event,
    Emitter<FoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodLoaded) return;

    // Check if this is shared sort - if so, filter by shared foods only
    final isSharedSort = event.sortOption == SortOption.shared;
    final sortedFoods = _sortFoods(currentState.foods, event.sortOption);

    List<Food> filteredFoods = sortedFoods;

    // Apply search filter if active
    if (currentState.searchText.isNotEmpty) {
      filteredFoods = filteredFoods
          .where(
            (food) => food.name.toLowerCase().contains(
              currentState.searchText.toLowerCase(),
            ),
          )
          .toList();
    }

    // Apply expiry filter if active
    if (currentState.activeFilter != null) {
      filteredFoods = filteredFoods
          .where((food) => food.expiresInDays(currentState.activeFilter!))
          .toList();
    }

    // Apply shared filter only if this is shared sort
    if (isSharedSort) {
      filteredFoods = filteredFoods.where((food) => food.isShared).toList();
    }

    emit(
      currentState.copyWith(
        foods: sortedFoods,
        filteredFoods: filteredFoods,
        sortOption: event.sortOption,
        showOnlyShared: isSharedSort,
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
      case SortOption.shared:
        // For shared sort, sort by date by default (shared foods first, then by expiry)
        sorted.sort((a, b) {
          // Shared foods first
          if (a.isShared && !b.isShared) return -1;
          if (!a.isShared && b.isShared) return 1;

          // If both shared or both not shared, sort by expiry date
          if (a.expiryDate == null && b.expiryDate == null) return 0;
          if (a.expiryDate == null) return 1;
          if (b.expiryDate == null) return -1;
          return a.expiryDate!.compareTo(b.expiryDate!);
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
      add(const LoadFoodsWithSharedEvent());
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

  Future<void> _onLoadFoodsWithShared(
    LoadFoodsWithSharedEvent event,
    Emitter<FoodState> emit,
  ) async {
    emit(FoodLoading());

    try {
      // 1. Load local foods
      final localFoodsResult = await getAllFoods(NoParams());
      List<Food> localFoods = [];

      localFoodsResult.fold(
        (failure) {
          emit(FoodError(failure.message));
          return;
        },
        (foods) {
          localFoods = foods;
        },
      );

      // 2. Load shared foods from friends
      final sharedFoods =
          await SharedFoodsLoaderService.loadSharedFoodsFromFriends();

      // 3. Combine local and shared foods
      final allFoods = [...localFoods, ...sharedFoods];

      // 4. Apply sorting
      final currentState = state;
      final sortOption = currentState is FoodLoaded
          ? currentState.sortOption
          : SortOption.date;
      final sortedFoods = _sortFoods(allFoods, sortOption);

      emit(
        FoodLoaded(
          foods: sortedFoods,
          filteredFoods: sortedFoods,
          sortOption: sortOption,
          showOnlyShared: false,
        ),
      );
    } catch (e) {
      emit(FoodError('Fehler beim Laden der Lebensmittel: $e'));
    }
  }
}
