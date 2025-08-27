import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/food.dart';
import '../../domain/usecases/add_food_from_text.dart';
import '../../domain/usecases/parse_foods_from_text.dart';
import 'food_ui_event.dart';
import 'food_ui_state.dart';

class FoodUIBloc extends Bloc<FoodUIEvent, FoodUIState> {
  final AddFoodFromText addFoodFromText;
  final ParseFoodsFromText parseFoodsFromText;

  FoodUIBloc({required this.addFoodFromText, required this.parseFoodsFromText})
    : super(FoodUIInitial()) {
    on<UpdateFoodListEvent>(_onUpdateFoodList);
    on<FilterFoodsByExpiryEvent>(_onFilterFoodsByExpiry);
    on<SearchFoodsByNameEvent>(_onSearchFoodsByName);
    on<SortFoodsEvent>(_onSortFoods);
    on<ShowFoodPreviewEvent>(_onShowFoodPreview);
    on<AddFoodFromTextEvent>(_onAddFoodFromText);
    on<HideFoodPreviewEvent>(_onHideFoodPreview);
    on<ResetFiltersEvent>(_onResetFilters);
  }

  void _onUpdateFoodList(UpdateFoodListEvent event, Emitter<FoodUIState> emit) {
    final currentState = state;

    if (currentState is FoodUILoaded) {
      // Maintain current filters and sorting
      final updatedState = currentState.copyWith(allFoods: event.foods);
      final filteredAndSorted = _applyFiltersAndSort(
        event.foods,
        updatedState.activeFilter,
        updatedState.searchText,
        updatedState.sortOption,
      );

      emit(updatedState.copyWith(filteredFoods: filteredAndSorted));
    } else {
      // Initialize with new food list
      final sortedFoods = _sortFoods(event.foods, SortOption.date);
      emit(FoodUILoaded(allFoods: event.foods, filteredFoods: sortedFoods));
    }
  }

  void _onFilterFoodsByExpiry(
    FilterFoodsByExpiryEvent event,
    Emitter<FoodUIState> emit,
  ) {
    final currentState = state;
    if (currentState is! FoodUILoaded) return;

    final filteredAndSorted = _applyFiltersAndSort(
      currentState.allFoods,
      event.daysUntilExpiry,
      currentState.searchText,
      currentState.sortOption,
    );

    emit(
      currentState.copyWith(
        filteredFoods: filteredAndSorted,
        activeFilter: event.daysUntilExpiry,
        clearActiveFilter: event.daysUntilExpiry == null,
      ),
    );
  }

  void _onSearchFoodsByName(
    SearchFoodsByNameEvent event,
    Emitter<FoodUIState> emit,
  ) {
    final currentState = state;
    if (currentState is! FoodUILoaded) return;

    final filteredAndSorted = _applyFiltersAndSort(
      currentState.allFoods,
      currentState.activeFilter,
      event.searchText,
      currentState.sortOption,
    );

    emit(
      currentState.copyWith(
        filteredFoods: filteredAndSorted,
        searchText: event.searchText,
      ),
    );
  }

  void _onSortFoods(SortFoodsEvent event, Emitter<FoodUIState> emit) {
    final currentState = state;
    if (currentState is! FoodUILoaded) return;

    final filteredAndSorted = _applyFiltersAndSort(
      currentState.allFoods,
      currentState.activeFilter,
      currentState.searchText,
      event.sortOption,
    );

    emit(
      currentState.copyWith(
        filteredFoods: filteredAndSorted,
        sortOption: event.sortOption,
      ),
    );
  }

  Future<void> _onShowFoodPreview(
    ShowFoodPreviewEvent event,
    Emitter<FoodUIState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodUILoaded) return;

    final result = await parseFoodsFromText(
      ParseFoodsFromTextParams(text: event.text),
    );

    result.fold(
      (failure) => emit(
        FoodUIError('Fehler beim Parsen des Textes: ${failure.message}'),
      ),
      (foods) => emit(
        FoodPreviewReady(
          previewFoods: foods,
          allFoods: currentState.allFoods,
          filteredFoods: currentState.filteredFoods,
          activeFilter: currentState.activeFilter,
          sortOption: currentState.sortOption,
          searchText: currentState.searchText,
        ),
      ),
    );
  }

  Future<void> _onAddFoodFromText(
    AddFoodFromTextEvent event,
    Emitter<FoodUIState> emit,
  ) async {
    final result = await addFoodFromText(
      AddFoodFromTextParams(text: event.text),
    );

    result.fold(
      (failure) => emit(
        FoodUIError('Fehler beim Hinzufügen aus Text: ${failure.message}'),
      ),
      (_) {
        // Success - the UI will be updated via the data bloc
        final currentState = state;
        if (currentState is FoodPreviewReady) {
          emit(
            FoodUILoaded(
              allFoods: currentState.allFoods,
              filteredFoods: currentState.filteredFoods,
              activeFilter: currentState.activeFilter,
              sortOption: currentState.sortOption,
              searchText: currentState.searchText,
            ),
          );
        }
      },
    );
  }

  void _onHideFoodPreview(
    HideFoodPreviewEvent event,
    Emitter<FoodUIState> emit,
  ) {
    final currentState = state;
    if (currentState is FoodPreviewReady) {
      emit(
        FoodUILoaded(
          allFoods: currentState.allFoods,
          filteredFoods: currentState.filteredFoods,
          activeFilter: currentState.activeFilter,
          sortOption: currentState.sortOption,
          searchText: currentState.searchText,
        ),
      );
    }
  }

  void _onResetFilters(ResetFiltersEvent event, Emitter<FoodUIState> emit) {
    final currentState = state;
    if (currentState is! FoodUILoaded) return;

    final sortedFoods = _sortFoods(currentState.allFoods, SortOption.date);

    emit(
      FoodUILoaded(
        allFoods: currentState.allFoods,
        filteredFoods: sortedFoods,
        sortOption: SortOption.date,
      ),
    );
  }

  List<Food> _applyFiltersAndSort(
    List<Food> foods,
    int? daysFilter,
    String searchText,
    SortOption sortOption,
  ) {
    var filteredFoods = foods;

    // Apply expiry filter
    if (daysFilter != null) {
      final now = DateTime.now();
      final targetDate = now.add(Duration(days: daysFilter));

      filteredFoods = filteredFoods.where((food) {
        if (food.expiryDate == null) return false;

        if (daysFilter == 0) {
          // Show expired foods (expiry date is before today)
          return food.expiryDate!.isBefore(
            DateTime(now.year, now.month, now.day),
          );
        } else {
          // Show foods expiring within X days
          return food.expiryDate!.isBefore(targetDate) &&
              food.expiryDate!.isAfter(now);
        }
      }).toList();
    }

    // Apply search filter
    if (searchText.isNotEmpty) {
      filteredFoods = filteredFoods.where((food) {
        return food.name.toLowerCase().contains(searchText.toLowerCase());
      }).toList();
    }

    // Apply sorting
    return _sortFoods(filteredFoods, sortOption);
  }

  List<Food> _sortFoods(List<Food> foods, SortOption sortOption) {
    final sortedFoods = List<Food>.from(foods);

    switch (sortOption) {
      case SortOption.alphabetical:
        sortedFoods.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.date:
        sortedFoods.sort((a, b) {
          // Foods without expiry date go to the end
          if (a.expiryDate == null && b.expiryDate == null) return 0;
          if (a.expiryDate == null) return 1;
          if (b.expiryDate == null) return -1;
          return a.expiryDate!.compareTo(b.expiryDate!);
        });
        break;
      case SortOption.category:
        sortedFoods.sort((a, b) {
          final categoryA = a.category ?? 'Unbekannt';
          final categoryB = b.category ?? 'Unbekannt';
          final categoryComparison = categoryA.compareTo(categoryB);
          if (categoryComparison != 0) return categoryComparison;
          // Within same category, sort by name
          return a.name.compareTo(b.name);
        });
        break;
    }

    return sortedFoods;
  }
}
