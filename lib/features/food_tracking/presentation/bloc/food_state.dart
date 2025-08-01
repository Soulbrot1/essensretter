import 'package:equatable/equatable.dart';
import '../../domain/entities/food.dart';

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

  const FoodLoaded({
    required this.foods,
    required this.filteredFoods,
    this.activeFilter,
  });

  @override
  List<Object?> get props => [foods, filteredFoods, activeFilter];

  FoodLoaded copyWith({
    List<Food>? foods,
    List<Food>? filteredFoods,
    int? activeFilter,
  }) {
    return FoodLoaded(
      foods: foods ?? this.foods,
      filteredFoods: filteredFoods ?? this.filteredFoods,
      activeFilter: activeFilter,
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

  const FoodOperationInProgress({
    required this.foods,
    required this.filteredFoods,
    this.activeFilter,
  });

  @override
  List<Object?> get props => [foods, filteredFoods, activeFilter];
}

class FoodPreviewReady extends FoodState {
  final List<Food> previewFoods;
  final List<Food> foods;
  final List<Food> filteredFoods;
  final int? activeFilter;

  const FoodPreviewReady({
    required this.previewFoods,
    required this.foods,
    required this.filteredFoods,
    this.activeFilter,
  });

  @override
  List<Object?> get props => [previewFoods, foods, filteredFoods, activeFilter];
}