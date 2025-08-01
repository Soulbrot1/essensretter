import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/food.dart';
import '../../domain/repositories/text_parser_repository.dart';
import '../datasources/text_parser_service.dart';

class TextParserRepositoryImpl implements TextParserRepository {
  final TextParserService textParserService;

  TextParserRepositoryImpl({required this.textParserService});

  @override
  Future<Either<Failure, List<Food>>> parseTextToFoods(String text) async {
    try {
      if (text.trim().isEmpty) {
        return const Left(InputFailure('Bitte geben Sie Text ein'));
      }
      
      final foods = textParserService.parseTextToFoods(text);
      
      if (foods.isEmpty) {
        return const Left(ParsingFailure('Keine Lebensmittel im Text gefunden'));
      }
      
      return Right(foods.cast<Food>());
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (e) {
      return const Left(ParsingFailure('Fehler beim Verarbeiten des Textes'));
    }
  }
}