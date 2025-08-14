import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/food.dart';

abstract class TextParserRepository {
  Future<Either<Failure, List<Food>>> parseTextToFoods(String text);
  Future<Either<Failure, List<Food>>> parseFoodsFromText(String text);
}
