import 'package:equatable/equatable.dart';
import '../../domain/entities/food.dart';

abstract class FoodDataEvent extends Equatable {
  const FoodDataEvent();

  @override
  List<Object?> get props => [];
}

class LoadFoodsEvent extends FoodDataEvent {}

class ConfirmFoodsEvent extends FoodDataEvent {
  final List<Food> foods;

  const ConfirmFoodsEvent(this.foods);

  @override
  List<Object> get props => [foods];
}

class DeleteFoodEvent extends FoodDataEvent {
  final String id;
  final bool
  wasDisposed; // true = weggeworfen, false = verbraucht/andere Gründe

  const DeleteFoodEvent(this.id, {this.wasDisposed = false});

  @override
  List<Object> get props => [id, wasDisposed];
}

class UpdateFoodEvent extends FoodDataEvent {
  final Food food;

  const UpdateFoodEvent(this.food);

  @override
  List<Object> get props => [food];
}

class ToggleConsumedEvent extends FoodDataEvent {
  final String id;

  const ToggleConsumedEvent(this.id);

  @override
  List<Object> get props => [id];
}

class ClearConsumedFoodsEvent extends FoodDataEvent {
  const ClearConsumedFoodsEvent();
}
