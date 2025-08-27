import 'package:equatable/equatable.dart';
import '../../domain/entities/food.dart';
import 'food_ui_event.dart';

abstract class FoodUIState extends Equatable {
  const FoodUIState();

  @override
  List<Object?> get props => [];
}

class FoodUIInitial extends FoodUIState {}

class FoodUILoaded extends FoodUIState {
  final List<Food> allFoods;
  final List<Food> filteredFoods;
  final int? activeFilter;
  final SortOption sortOption;
  final String searchText;

  const FoodUILoaded({
    required this.allFoods,
    required this.filteredFoods,
    this.activeFilter,
    this.sortOption = SortOption.date,
    this.searchText = '',
  });

  @override
  List<Object?> get props => [
    allFoods,
    filteredFoods,
    activeFilter,
    sortOption,
    searchText,
  ];

  FoodUILoaded copyWith({
    List<Food>? allFoods,
    List<Food>? filteredFoods,
    int? activeFilter,
    bool clearActiveFilter = false,
    SortOption? sortOption,
    String? searchText,
  }) {
    return FoodUILoaded(
      allFoods: allFoods ?? this.allFoods,
      filteredFoods: filteredFoods ?? this.filteredFoods,
      activeFilter: clearActiveFilter
          ? null
          : (activeFilter ?? this.activeFilter),
      sortOption: sortOption ?? this.sortOption,
      searchText: searchText ?? this.searchText,
    );
  }
}

class FoodPreviewReady extends FoodUIState {
  final List<Food> previewFoods;
  final List<Food> allFoods;
  final List<Food> filteredFoods;
  final int? activeFilter;
  final SortOption sortOption;
  final String searchText;

  const FoodPreviewReady({
    required this.previewFoods,
    required this.allFoods,
    required this.filteredFoods,
    this.activeFilter,
    this.sortOption = SortOption.date,
    this.searchText = '',
  });

  @override
  List<Object?> get props => [
    previewFoods,
    allFoods,
    filteredFoods,
    activeFilter,
    sortOption,
    searchText,
  ];
}

class FoodUIError extends FoodUIState {
  final String message;

  const FoodUIError(this.message);

  @override
  List<Object> get props => [message];
}
