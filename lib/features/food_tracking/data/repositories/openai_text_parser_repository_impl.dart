import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/food.dart';
import '../../domain/repositories/text_parser_repository.dart';
import '../datasources/openai_text_parser_service.dart';

class OpenAITextParserRepositoryImpl implements TextParserRepository {
  final OpenAITextParserService openAITextParserService;

  OpenAITextParserRepositoryImpl({required this.openAITextParserService});

  @override
  Future<Either<Failure, List<Food>>> parseTextToFoods(String text) async {
    try {
      if (text.trim().isEmpty) {
        return const Left(InputFailure('Bitte geben Sie Text ein'));
      }
      
      final foods = await openAITextParserService.parseTextToFoodsAsync(text);
      
      if (foods.isEmpty) {
        return const Left(ParsingFailure('Keine Lebensmittel im Text gefunden'));
      }
      
      return Right(foods.cast<Food>());
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (e) {
      return Left(ParsingFailure('Fehler beim Verarbeiten des Textes: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Food>>> parseFoodsFromText(String text) async {
    // Für die Vorschau verwenden wir die gleiche Logik wie parseTextToFoods
    return parseTextToFoods(text);
  }
}