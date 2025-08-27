import 'package:equatable/equatable.dart';
import '../../domain/entities/food.dart';

abstract class FoodDataState extends Equatable {
  const FoodDataState();

  @override
  List<Object?> get props => [];
}

class FoodDataInitial extends FoodDataState {}

class FoodDataLoading extends FoodDataState {}

class FoodDataLoaded extends FoodDataState {
  final List<Food> foods;

  const FoodDataLoaded(this.foods);

  @override
  List<Object> get props => [foods];

  FoodDataLoaded copyWith({List<Food>? foods}) {
    return FoodDataLoaded(foods ?? this.foods);
  }
}

class FoodDataError extends FoodDataState {
  final String message;

  const FoodDataError(this.message);

  @override
  List<Object> get props => [message];
}

class FoodDataOperationInProgress extends FoodDataState {
  final List<Food> foods;

  const FoodDataOperationInProgress(this.foods);

  @override
  List<Object> get props => [foods];
}
