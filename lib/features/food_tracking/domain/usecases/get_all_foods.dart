import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/food.dart';
import '../repositories/food_repository.dart';

class GetAllFoods implements UseCase<List<Food>, NoParams> {
  final FoodRepository repository;

  GetAllFoods(this.repository);

  @override
  Future<Either<Failure, List<Food>>> call(NoParams params) async {
    return await repository.getAllFoods();
  }
}
