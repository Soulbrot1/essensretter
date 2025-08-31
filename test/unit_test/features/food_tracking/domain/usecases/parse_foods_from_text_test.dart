import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:essensretter/core/error/failures.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/domain/repositories/text_parser_repository.dart';
import 'package:essensretter/features/food_tracking/domain/usecases/parse_foods_from_text.dart';

class MockTextParserRepository extends Mock implements TextParserRepository {}

void main() {
  late ParseFoodsFromText parseFoodsFromText;
  late MockTextParserRepository mockRepository;

  setUp(() {
    mockRepository = MockTextParserRepository();
    parseFoodsFromText = ParseFoodsFromText(mockRepository);
  });

  group('ParseFoodsFromText', () {
    test('sollte "Milch morgen, Brot übermorgen" korrekt parsen', () async {
      // arrange
      const inputText = 'Milch morgen, Brot übermorgen';
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dayAfterTomorrow = DateTime.now().add(const Duration(days: 2));

      final expectedFoods = [
        Food(
          id: '1',
          name: 'Milch',
          expiryDate: tomorrow,
          addedDate: DateTime.now(),
          category: 'Milchprodukte',
        ),
        Food(
          id: '2',
          name: 'Brot',
          expiryDate: dayAfterTomorrow,
          addedDate: DateTime.now(),
          category: 'Backwaren',
        ),
      ];

      when(
        () => mockRepository.parseFoodsFromText(any()),
      ).thenAnswer((_) async => Right(expectedFoods));

      // act
      final result = await parseFoodsFromText(
        ParseFoodsFromTextParams(text: inputText),
      );

      // assert
      expect(result.isRight(), true);
      result.fold((_) => fail('Should have returned foods'), (foods) {
        expect(foods.length, 2);
        expect(foods[0].name, 'Milch');
        expect(foods[1].name, 'Brot');
      });
      verify(() => mockRepository.parseFoodsFromText(inputText)).called(1);
    });

    test('sollte verschiedene Datumsformate korrekt verarbeiten', () async {
      // arrange
      const inputText = 'Milch 25.12., Joghurt in 3 Tagen, Käse nächste Woche';
      final expectedFoods = [
        Food(
          id: '1',
          name: 'Milch',
          expiryDate: DateTime(DateTime.now().year, 12, 25),
          addedDate: DateTime.now(),
        ),
        Food(
          id: '2',
          name: 'Joghurt',
          expiryDate: DateTime.now().add(const Duration(days: 3)),
          addedDate: DateTime.now(),
        ),
        Food(
          id: '3',
          name: 'Käse',
          expiryDate: DateTime.now().add(const Duration(days: 7)),
          addedDate: DateTime.now(),
        ),
      ];

      when(
        () => mockRepository.parseFoodsFromText(any()),
      ).thenAnswer((_) async => Right(expectedFoods));

      // act
      final result = await parseFoodsFromText(
        ParseFoodsFromTextParams(text: inputText),
      );

      // assert
      expect(result.isRight(), true);
      result.fold((_) => fail('Should have returned foods'), (foods) {
        expect(foods.length, 3);
        expect(foods[0].name, 'Milch');
        expect(foods[1].name, 'Joghurt');
        expect(foods[2].name, 'Käse');
      });
    });

    test('sollte leere Liste zurückgeben bei leerem Text', () async {
      // arrange
      const inputText = '';
      when(
        () => mockRepository.parseFoodsFromText(any()),
      ).thenAnswer((_) async => const Right([]));

      // act
      final result = await parseFoodsFromText(
        ParseFoodsFromTextParams(text: inputText),
      );

      // assert
      expect(result, const Right<Failure, List<Food>>([]));
      verify(() => mockRepository.parseFoodsFromText(inputText)).called(1);
    });

    test('sollte ungültige Eingaben mit Failure behandeln', () async {
      // arrange
      const inputText = '123 456 789'; // Nur Zahlen, keine Foods
      when(() => mockRepository.parseFoodsFromText(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Keine Lebensmittel erkannt')),
      );

      // act
      final result = await parseFoodsFromText(
        ParseFoodsFromTextParams(text: inputText),
      );

      // assert
      expect(
        result,
        const Left<Failure, List<Food>>(
          ServerFailure('Keine Lebensmittel erkannt'),
        ),
      );
    });

    test('sollte mit Sonderzeichen und Umlauten umgehen', () async {
      // arrange
      const inputText = 'Müsli & Nüsse morgen, Öl übermorgen';
      final expectedFoods = [
        Food(
          id: '1',
          name: 'Müsli & Nüsse',
          expiryDate: DateTime.now().add(const Duration(days: 1)),
          addedDate: DateTime.now(),
        ),
        Food(
          id: '2',
          name: 'Öl',
          expiryDate: DateTime.now().add(const Duration(days: 2)),
          addedDate: DateTime.now(),
        ),
      ];

      when(
        () => mockRepository.parseFoodsFromText(any()),
      ).thenAnswer((_) async => Right(expectedFoods));

      // act
      final result = await parseFoodsFromText(
        ParseFoodsFromTextParams(text: inputText),
      );

      // assert
      expect(result.isRight(), true);
      result.fold((_) => fail('Should have returned foods'), (foods) {
        expect(foods[0].name, 'Müsli & Nüsse');
        expect(foods[1].name, 'Öl');
      });
    });

    test('sollte ServerFailure bei API-Fehler zurückgeben', () async {
      // arrange
      const inputText = 'Milch morgen';
      when(() => mockRepository.parseFoodsFromText(any())).thenAnswer(
        (_) async => const Left(ServerFailure('OpenAI API nicht verfügbar')),
      );

      // act
      final result = await parseFoodsFromText(
        ParseFoodsFromTextParams(text: inputText),
      );

      // assert
      expect(
        result,
        const Left<Failure, List<Food>>(
          ServerFailure('OpenAI API nicht verfügbar'),
        ),
      );
    });

    test('sollte Exception als ServerFailure behandeln', () async {
      // arrange
      const inputText = 'Milch morgen';
      when(
        () => mockRepository.parseFoodsFromText(any()),
      ).thenThrow(Exception('Network error'));

      // act
      final result = await parseFoodsFromText(
        ParseFoodsFromTextParams(text: inputText),
      );

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should have returned a failure'),
      );
    });
  });
}
