import 'package:equatable/equatable.dart';
import '../../domain/entities/food.dart';

enum SortOption { alphabetical, date, category }

abstract class FoodUIEvent extends Equatable {
  const FoodUIEvent();

  @override
  List<Object?> get props => [];
}

class UpdateFoodListEvent extends FoodUIEvent {
  final List<Food> foods;

  const UpdateFoodListEvent(this.foods);

  @override
  List<Object> get props => [foods];
}

class FilterFoodsByExpiryEvent extends FoodUIEvent {
  final int? daysUntilExpiry;

  const FilterFoodsByExpiryEvent(this.daysUntilExpiry);

  @override
  List<Object?> get props => [daysUntilExpiry];
}

class SearchFoodsByNameEvent extends FoodUIEvent {
  final String searchText;

  const SearchFoodsByNameEvent(this.searchText);

  @override
  List<Object> get props => [searchText];
}

class SortFoodsEvent extends FoodUIEvent {
  final SortOption sortOption;

  const SortFoodsEvent(this.sortOption);

  @override
  List<Object> get props => [sortOption];
}

class ShowFoodPreviewEvent extends FoodUIEvent {
  final String text;

  const ShowFoodPreviewEvent(this.text);

  @override
  List<Object> get props => [text];
}

class AddFoodFromTextEvent extends FoodUIEvent {
  final String text;

  const AddFoodFromTextEvent(this.text);

  @override
  List<Object> get props => [text];
}

class HideFoodPreviewEvent extends FoodUIEvent {}

class ResetFiltersEvent extends FoodUIEvent {}
