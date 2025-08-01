import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/food.dart';
import '../../domain/usecases/add_food_from_text.dart';
import '../../domain/usecases/add_foods.dart';
import '../../domain/usecases/delete_food.dart';
import '../../domain/usecases/get_all_foods.dart';
import '../../domain/usecases/get_foods_by_expiry.dart';
import '../../domain/usecases/parse_foods_from_text.dart';
import 'food_event.dart';
import 'food_state.dart';

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final GetAllFoods getAllFoods;
  final GetFoodsByExpiry getFoodsByExpiry;
  final AddFoodFromText addFoodFromText;
  final AddFoods addFoods;
  final ParseFoodsFromText parseFoodsFromText;
  final DeleteFood deleteFood;

  FoodBloc({
    required this.getAllFoods,
    required this.getFoodsByExpiry,
    required this.addFoodFromText,
    required this.addFoods,
    required this.parseFoodsFromText,
    required this.deleteFood,
  }) : super(FoodInitial()) {
    on<LoadFoodsEvent>(_onLoadFoods);
    on<AddFoodFromTextEvent>(_onAddFoodFromText);
    on<ShowFoodPreviewEvent>(_onShowFoodPreview);
    on<ConfirmFoodsEvent>(_onConfirmFoods);
    on<FilterFoodsByExpiryEvent>(_onFilterFoodsByExpiry);
    on<DeleteFoodEvent>(_onDeleteFood);
    on<ToggleConsumedEvent>(_onToggleConsumed);
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
        final sortedFoods = _sortFoodsByExpiry(foods);
        emit(FoodLoaded(
          foods: sortedFoods,
          filteredFoods: sortedFoods,
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
        activeFilter: null,
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

    final sortedFoods = _sortFoodsByExpiry(updatedFoods);
    
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
    ));
  }

  List<Food> _sortFoodsByExpiry(List<Food> foods) {
    final sorted = List<Food>.from(foods);
    sorted.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return sorted;
  }
}