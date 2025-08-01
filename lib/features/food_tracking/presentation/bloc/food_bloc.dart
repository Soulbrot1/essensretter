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

  FoodBloc({
    required this.getAllFoods,
    required this.getFoodsByExpiry,
    required this.addFoodFromText,
    required this.addFoods,
    required this.parseFoodsFromText,
    required this.deleteFood,
    required this.updateFood,
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
  }

  Future<void> _onLoadFoods(
    LoadFoodsEvent event,
    Emitter<FoodState> emit,
  ) async {
    emit(FoodLoading());
    
    final result = await getAllFoods(NoParams());
    
    result.fold(
      (failure) => emit(FoodError(failure.message)),
      (foods) {
        final currentState = state;
        final sortOption = currentState is FoodLoaded ? currentState.sortOption : SortOption.date;
        final sortedFoods = _sortFoods(foods, sortOption);
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

    final updatedFoods = currentState.foods.map((food) {
      if (food.id == event.id) {
        return food.copyWith(isConsumed: !food.isConsumed);
      }
      return food;
    }).toList();

    final sortedFoods = _sortFoods(updatedFoods, currentState.sortOption);
    
    List<Food> filteredFoods;
    if (currentState.activeFilter != null) {
      filteredFoods = sortedFoods
          .where((food) => food.expiresInDays(currentState.activeFilter!))
          .toList();
    } else {
      filteredFoods = sortedFoods;
    }

    emit(FoodLoaded(
      foods: sortedFoods,
      filteredFoods: filteredFoods,
      activeFilter: currentState.activeFilter,
      sortOption: currentState.sortOption,
    ));
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

  List<Food> _sortFoodsByExpiry(List<Food> foods) {
    return _sortFoods(foods, SortOption.date);
  }
}