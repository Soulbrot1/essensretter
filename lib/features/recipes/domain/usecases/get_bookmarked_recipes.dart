import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recipe.dart';
import '../repositories/recipe_repository.dart';

class GetBookmarkedRecipes implements UseCase<List<Recipe>, NoParams> {
  final RecipeRepository repository;

  GetBookmarkedRecipes(this.repository);

  @override
  Future<Either<Failure, List<Recipe>>> call(NoParams params) async {
    return await repository.getBookmarkedRecipes();
  }
}