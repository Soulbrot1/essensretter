import 'package:equatable/equatable.dart';
import '../../domain/entities/food.dart';
import 'food_event.dart';

abstract class FoodState extends Equatable {
  const FoodState();

  @override
  List<Object?> get props => [];
}

class FoodInitial extends FoodState {}

class FoodLoading extends FoodState {}

class FoodLoaded extends FoodState {
  final List<Food> foods;
  final List<Food> filteredFoods;
  final int? activeFilter;
  final SortOption sortOption;

  const FoodLoaded({
    required this.foods,
    required this.filteredFoods,
    this.activeFilter,
    this.sortOption = SortOption.date,
  });

  @override
  List<Object?> get props => [foods, filteredFoods, activeFilter, sortOption];

  FoodLoaded copyWith({
    List<Food>? foods,
    List<Food>? filteredFoods,
    int? activeFilter,
    bool clearActiveFilter = false,
    SortOption? sortOption,
  }) {
    return FoodLoaded(
      foods: foods ?? this.foods,
      filteredFoods: filteredFoods ?? this.filteredFoods,
      activeFilter: clearActiveFilter ? null : (activeFilter ?? this.activeFilter),
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class FoodError extends FoodState {
  final String message;

  const FoodError(this.message);

  @override
  List<Object> get props => [message];
}

class FoodOperationInProgress extends FoodState {
  final List<Food> foods;
  final List<Food> filteredFoods;
  final int? activeFilter;
  final SortOption sortOption;

  const FoodOperationInProgress({
    required this.foods,
    required this.filteredFoods,
    this.activeFilter,
    this.sortOption = SortOption.date,
  });

  @override
  List<Object?> get props => [foods, filteredFoods, activeFilter, sortOption];
}

class FoodPreviewReady extends FoodState {
  final List<Food> previewFoods;
  final List<Food> foods;
  final List<Food> filteredFoods;
  final int? activeFilter;
  final SortOption sortOption;

  const FoodPreviewReady({
    required this.previewFoods,
    required this.foods,
    required this.filteredFoods,
    this.activeFilter,
    this.sortOption = SortOption.date,
  });

  @override
  List<Object?> get props => [previewFoods, foods, filteredFoods, activeFilter, sortOption];
}