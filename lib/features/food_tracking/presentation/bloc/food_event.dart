import 'package:equatable/equatable.dart';
import '../../domain/entities/food.dart';

abstract class FoodEvent extends Equatable {
  const FoodEvent();

  @override
  List<Object?> get props => [];
}

class LoadFoodsEvent extends FoodEvent {
  const LoadFoodsEvent();
}

class AddFoodFromTextEvent extends FoodEvent {
  final String text;

  const AddFoodFromTextEvent(this.text);

  @override
  List<Object> get props => [text];
}

class FilterFoodsByExpiryEvent extends FoodEvent {
  final int? daysUntilExpiry;
  final bool? showOnlyShared;

  const FilterFoodsByExpiryEvent(this.daysUntilExpiry, {this.showOnlyShared});

  @override
  List<Object?> get props => [daysUntilExpiry, showOnlyShared];
}

class SearchFoodsByNameEvent extends FoodEvent {
  final String searchText;

  const SearchFoodsByNameEvent(this.searchText);

  @override
  List<Object> get props => [searchText];
}

class DeleteFoodEvent extends FoodEvent {
  final String id;
  final bool
  wasDisposed; // true = weggeworfen, false = verbraucht/andere Gründe

  const DeleteFoodEvent(this.id, {this.wasDisposed = false});

  @override
  List<Object> get props => [id, wasDisposed];
}

class ToggleConsumedEvent extends FoodEvent {
  final String id;

  const ToggleConsumedEvent(this.id);

  @override
  List<Object> get props => [id];
}

class ShowFoodPreviewEvent extends FoodEvent {
  final String text;

  const ShowFoodPreviewEvent(this.text);

  @override
  List<Object> get props => [text];
}

class ConfirmFoodsEvent extends FoodEvent {
  final List<Food> foods;

  const ConfirmFoodsEvent(this.foods);

  @override
  List<Object> get props => [foods];
}

class UpdateFoodEvent extends FoodEvent {
  final Food food;

  const UpdateFoodEvent(this.food);

  @override
  List<Object> get props => [food];
}

enum SortOption { alphabetical, date, category, shared }

class SortFoodsEvent extends FoodEvent {
  final SortOption sortOption;

  const SortFoodsEvent(this.sortOption);

  @override
  List<Object> get props => [sortOption];
}

class ClearConsumedFoodsEvent extends FoodEvent {
  const ClearConsumedFoodsEvent();
}

class FilterSharedFoodsEvent extends FoodEvent {
  final bool showOnlyShared;

  const FilterSharedFoodsEvent(this.showOnlyShared);

  @override
  List<Object> get props => [showOnlyShared];
}

class LoadFoodsWithSharedEvent extends FoodEvent {
  const LoadFoodsWithSharedEvent();
}
