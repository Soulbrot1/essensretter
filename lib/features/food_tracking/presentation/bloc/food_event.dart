import 'package:equatable/equatable.dart';
import '../../domain/entities/food.dart';

abstract class FoodEvent extends Equatable {
  const FoodEvent();

  @override
  List<Object?> get props => [];
}

class LoadFoodsEvent extends FoodEvent {}

class AddFoodFromTextEvent extends FoodEvent {
  final String text;

  const AddFoodFromTextEvent(this.text);

  @override
  List<Object> get props => [text];
}

class FilterFoodsByExpiryEvent extends FoodEvent {
  final int? daysUntilExpiry;

  const FilterFoodsByExpiryEvent(this.daysUntilExpiry);

  @override
  List<Object?> get props => [daysUntilExpiry];
}

class DeleteFoodEvent extends FoodEvent {
  final String id;

  const DeleteFoodEvent(this.id);

  @override
  List<Object> get props => [id];
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

enum SortOption { alphabetical, date, category }

class SortFoodsEvent extends FoodEvent {
  final SortOption sortOption;

  const SortFoodsEvent(this.sortOption);

  @override
  List<Object> get props => [sortOption];
}

class ClearConsumedFoodsEvent extends FoodEvent {
  const ClearConsumedFoodsEvent();
}

class LoadDemoFoodsEvent extends FoodEvent {
  const LoadDemoFoodsEvent();
}