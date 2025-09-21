import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/food.dart';
import '../../domain/usecases/add_foods.dart';
import '../../domain/usecases/delete_food.dart';
import '../../domain/usecases/get_all_foods.dart';
import '../../domain/usecases/update_food.dart';
import '../../../recipes/domain/usecases/update_recipes_after_food_deletion.dart';
import '../../../statistics/domain/repositories/statistics_repository.dart';
import 'food_data_event.dart';
import 'food_data_state.dart';

class FoodDataBloc extends Bloc<FoodDataEvent, FoodDataState> {
  final GetAllFoods getAllFoods;
  final AddFoods addFoods;
  final DeleteFood deleteFood;
  final UpdateFood updateFood;
  final UpdateRecipesAfterFoodDeletion updateRecipesAfterFoodDeletion;
  final StatisticsRepository statisticsRepository;

  FoodDataBloc({
    required this.getAllFoods,
    required this.addFoods,
    required this.deleteFood,
    required this.updateFood,
    required this.updateRecipesAfterFoodDeletion,
    required this.statisticsRepository,
  }) : super(FoodDataInitial()) {
    on<LoadFoodsEvent>(_onLoadFoods);
    on<ConfirmFoodsEvent>(_onConfirmFoods);
    on<DeleteFoodEvent>(_onDeleteFood);
    on<UpdateFoodEvent>(_onUpdateFood);
    on<ToggleConsumedEvent>(_onToggleConsumed);
    on<ClearConsumedFoodsEvent>(_onClearConsumedFoods);
  }

  Future<void> _onLoadFoods(
    LoadFoodsEvent event,
    Emitter<FoodDataState> emit,
  ) async {
    emit(FoodDataLoading());

    final result = await getAllFoods(NoParams());

    await result.fold((failure) async => emit(FoodDataError(failure.message)), (
      foods,
    ) async {
      List<Food> finalFoods = foods;

      emit(FoodDataLoaded(finalFoods));
    });
  }

  Future<void> _onConfirmFoods(
    ConfirmFoodsEvent event,
    Emitter<FoodDataState> emit,
  ) async {
    emit(FoodDataLoading());

    final result = await addFoods(AddFoodsParams(foods: event.foods));

    result.fold(
      (failure) => emit(
        FoodDataError(
          'Fehler beim Hinzufügen der Lebensmittel: ${failure.message}',
        ),
      ),
      (_) {
        // Nach erfolgreichem Hinzufügen neu laden
        add(LoadFoodsEvent());
      },
    );
  }

  Future<void> _onDeleteFood(
    DeleteFoodEvent event,
    Emitter<FoodDataState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodDataLoaded) return;

    emit(FoodDataOperationInProgress(currentState.foods));

    // Statistik aufzeichnen wenn gewünscht
    if (event.wasDisposed) {
      try {
        final foodToDelete = currentState.foods.firstWhere(
          (food) => food.id == event.id,
          orElse: () => throw Exception('Food not found'),
        );

        await statisticsRepository.recordWastedFood(
          foodToDelete.id,
          foodToDelete.name,
          foodToDelete.category,
        );
      } catch (e) {
        // Statistik-Fehler ignorieren, Löschung trotzdem durchführen
      }
    }

    final result = await deleteFood(DeleteFoodParams(id: event.id));

    result.fold(
      (failure) =>
          emit(FoodDataError('Fehler beim Löschen: ${failure.message}')),
      (_) {
        // Nach erfolgreichem Löschen neu laden
        add(LoadFoodsEvent());
      },
    );
  }

  Future<void> _onUpdateFood(
    UpdateFoodEvent event,
    Emitter<FoodDataState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodDataLoaded) return;

    final result = await updateFood(event.food);

    result.fold(
      (failure) {
        emit(FoodDataError(failure.message));
        emit(currentState);
      },
      (updatedFood) {
        // Update local state
        final updatedFoods = currentState.foods.map((food) {
          return food.id == event.food.id ? updatedFood : food;
        }).toList();

        emit(FoodDataLoaded(updatedFoods));
      },
    );
  }

  Future<void> _onToggleConsumed(
    ToggleConsumedEvent event,
    Emitter<FoodDataState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodDataLoaded) return;

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
      try {
        await updateRecipesAfterFoodDeletion(
          UpdateRecipesParams(foodName: foodToToggle.name),
        );
      } catch (e) {
        // Recipe update error ignored
      }

      // Record in statistics as consumed
      try {
        await statisticsRepository.recordConsumedFood(
          foodToToggle.id,
          foodToToggle.name,
          foodToToggle.category,
        );
      } catch (e) {
        // Statistics error ignored
      }
    }

    // Update the food in the database
    final result = await updateFood(updatedFood);

    result.fold(
      (failure) {
        emit(FoodDataError(failure.message));
        emit(currentState);
      },
      (savedFood) {
        // Update local state and maintain filters
        final updatedFoods = currentState.foods.map((food) {
          return food.id == event.id ? savedFood : food;
        }).toList();

        emit(FoodDataLoaded(updatedFoods));
      },
    );
  }

  Future<void> _onClearConsumedFoods(
    ClearConsumedFoodsEvent event,
    Emitter<FoodDataState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodDataLoaded) return;

    // Find all consumed foods
    final consumedFoods = currentState.foods
        .where((food) => food.isConsumed)
        .toList();

    if (consumedFoods.isEmpty) return;

    // Show loading state
    emit(FoodDataOperationInProgress(currentState.foods));

    try {
      // Delete all consumed foods
      for (final food in consumedFoods) {
        await deleteFood(DeleteFoodParams(id: food.id));
      }

      // Reload the foods list
      add(LoadFoodsEvent());
    } catch (e) {
      emit(FoodDataError('Fehler beim Löschen verbrauchter Lebensmittel: $e'));
      emit(currentState);
    }
  }
}
