import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/food.dart';
import '../repositories/food_repository.dart';

class AddFoods implements UseCase<void, AddFoodsParams> {
  final FoodRepository repository;

  AddFoods(this.repository);

  @override
  Future<Either<Failure, void>> call(AddFoodsParams params) async {
    try {
      for (final food in params.foods) {
        final result = await repository.addFood(food);
        if (result.isLeft()) {
          return result;
        }
      }
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Fehler beim Speichern der Lebensmittel'));
    }
  }
}

class AddFoodsParams {
  final List<Food> foods;

  AddFoodsParams({required this.foods});
}
