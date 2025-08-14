import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/food.dart';
import '../repositories/food_repository.dart';
import '../repositories/text_parser_repository.dart';

class AddFoodFromText implements UseCase<List<Food>, AddFoodFromTextParams> {
  final TextParserRepository textParserRepository;
  final FoodRepository foodRepository;

  AddFoodFromText({
    required this.textParserRepository,
    required this.foodRepository,
  });

  @override
  Future<Either<Failure, List<Food>>> call(AddFoodFromTextParams params) async {
    final parseResult = await textParserRepository.parseTextToFoods(
      params.text,
    );

    return parseResult.fold((failure) => Left(failure), (foods) async {
      final List<Food> addedFoods = [];

      for (final food in foods) {
        final result = await foodRepository.addFood(food);
        result.fold(
          (failure) => null,
          (addedFood) => addedFoods.add(addedFood),
        );
      }

      if (addedFoods.isEmpty) {
        return const Left(
          InputFailure('Keine Lebensmittel konnten hinzugefügt werden'),
        );
      }

      return Right(addedFoods);
    });
  }
}

class AddFoodFromTextParams extends Equatable {
  final String text;

  const AddFoodFromTextParams({required this.text});

  @override
  List<Object> get props => [text];
}
