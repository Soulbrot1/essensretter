import 'package:equatable/equatable.dart';

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