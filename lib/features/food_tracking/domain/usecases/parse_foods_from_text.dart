import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/food.dart';
import '../repositories/text_parser_repository.dart';

class ParseFoodsFromText implements UseCase<List<Food>, ParseFoodsFromTextParams> {
  final TextParserRepository repository;

  ParseFoodsFromText(this.repository);

  @override
  Future<Either<Failure, List<Food>>> call(ParseFoodsFromTextParams params) async {
    return await repository.parseFoodsFromText(params.text);
  }
}

class ParseFoodsFromTextParams {
  final String text;

  ParseFoodsFromTextParams({required this.text});
}