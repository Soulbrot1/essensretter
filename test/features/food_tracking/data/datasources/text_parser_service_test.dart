import 'package:flutter_test/flutter_test.dart';
import 'package:essensretter/features/food_tracking/data/datasources/text_parser_service.dart';

void main() {
  late TextParserServiceImpl parser;

  setUp(() {
    parser = TextParserServiceImpl();
  });

  group('TextParserServiceImpl - Deutsche Datumsformate', () {
    test('sollte "morgen", "übermorgen", "heute" erkennen', () {
      final result1 = parser.parseTextToFoods('Milch morgen');
      expect(result1.length, 1);
      expect(result1.first.name, 'Milch');
      expect(result1.first.expiryDate?.difference(DateTime.now()).inDays, 1);

      final result2 = parser.parseTextToFoods('Käse übermorgen');
      expect(result2.first.expiryDate?.difference(DateTime.now()).inDays, 2);

      final result3 = parser.parseTextToFoods('Brot heute');
      expect(result3.first.expiryDate?.difference(DateTime.now()).inDays, 0);
    });

    test('sollte "gestern" und "vorgestern" als abgelaufen erkennen', () {
      final result1 = parser.parseTextToFoods('Joghurt gestern');
      expect(result1.first.expiryDate?.difference(DateTime.now()).inDays, -1);

      final result2 = parser.parseTextToFoods('Wurst vorgestern');
      expect(result2.first.expiryDate?.difference(DateTime.now()).inDays, -2);
    });

    test('sollte verschiedene Datumsformate erkennen', () {
      final result1 = parser.parseTextToFoods('Milch 4.8');
      expect(result1.first.name, 'Milch');
      expect(result1.first.expiryDate?.month, 8);
      expect(result1.first.expiryDate?.day, 4);

      final result2 = parser.parseTextToFoods('Käse 15/3');
      expect(result2.first.expiryDate?.month, 3);
      expect(result2.first.expiryDate?.day, 15);

      final result3 = parser.parseTextToFoods('Brot 20-12');
      expect(result3.first.expiryDate?.month, 12);
      expect(result3.first.expiryDate?.day, 20);
    });

    test('sollte "am X." ohne Monat erkennen', () {
      final result = parser.parseTextToFoods('Butter am 15.');
      expect(result.first.name, 'Butter');
      expect(result.first.expiryDate?.day, 15);
      // Sollte aktuellen oder nächsten Monat nehmen
      final now = DateTime.now();
      if (now.day >= 15) {
        expect(result.first.expiryDate?.month, 
          now.month == 12 ? 1 : now.month + 1);
      } else {
        expect(result.first.expiryDate?.month, now.month);
      }
    });

    test('sollte Monatsnamen und Varianten erkennen', () {
      final result1 = parser.parseTextToFoods('Apfel 4. August');
      expect(result1.first.expiryDate?.month, 8);
      expect(result1.first.expiryDate?.day, 4);

      final result2 = parser.parseTextToFoods('Birne 15 März');
      expect(result2.first.expiryDate?.month, 3);

      final result3 = parser.parseTextToFoods('Orange Ende Februar');
      expect(result3.first.expiryDate?.month, 2);
      expect(result3.first.expiryDate?.day, greaterThan(25)); // Letzter Tag
    });

    test('sollte Wochentage erkennen', () {
      final result1 = parser.parseTextToFoods('Salat nächsten Dienstag');
      expect(result1.first.name, 'Salat');
      expect(result1.first.expiryDate, isNotNull);
      
      final result2 = parser.parseTextToFoods('Tomaten kommenden Freitag');
      expect(result2.first.name, 'Tomaten');
      
      final result3 = parser.parseTextToFoods('Gurke übernächsten Samstag');
      expect(result3.first.expiryDate?.difference(DateTime.now()).inDays, 
        greaterThan(7));
    });

    test('sollte "nächste Woche" und "übernächste Woche" erkennen', () {
      final result1 = parser.parseTextToFoods('Eier nächste Woche');
      expect(result1.first.expiryDate?.difference(DateTime.now()).inDays, 7);

      final result2 = parser.parseTextToFoods('Mehl übernächste Woche');
      expect(result2.first.expiryDate?.difference(DateTime.now()).inDays, 14);
    });

    test('sollte "paar Tage" und "einige Tage" erkennen', () {
      final result1 = parser.parseTextToFoods('Bananen paar Tage');
      expect(result1.first.expiryDate?.difference(DateTime.now()).inDays, 3);

      final result2 = parser.parseTextToFoods('Äpfel einige Tage');
      expect(result2.first.expiryDate?.difference(DateTime.now()).inDays, 5);
    });

    test('sollte 2-stellige Jahreszahlen korrekt interpretieren', () {
      final result1 = parser.parseTextToFoods('Konserve 31.12.25');
      expect(result1.first.expiryDate?.year, 2025);

      final result2 = parser.parseTextToFoods('Dose 1.1.35');
      expect(result2.first.expiryDate?.year, 1935);

      final result3 = parser.parseTextToFoods('Glas 15.6.2030');
      expect(result3.first.expiryDate?.year, 2030);
    });

    test('sollte mehrere Lebensmittel mit verschiedenen Daten erkennen', () {
      final result = parser.parseTextToFoods(
        'Milch morgen, Käse 15.8, Brot nächste Woche'
      );
      expect(result.length, 3);
      expect(result[0].name, 'Milch');
      expect(result[1].name, 'Käse');
      expect(result[2].name, 'Brot');
    });

    test('sollte Lebensmittel ohne Datum erkennen', () {
      final result = parser.parseTextToFoods('Apfel und Birne');
      expect(result.length, 2);
      expect(result[0].name, 'Apfel');
      expect(result[0].expiryDate, isNull);
      expect(result[1].name, 'Birne');
      expect(result[1].expiryDate, isNull);
    });

    test('sollte vergangene Daten als negativ erkennen', () {
      final result = parser.parseTextToFoods('Joghurt 1.1.2020');
      expect(result.first.expiryDate?.year, 2020);
      expect(result.first.expiryDate?.isBefore(DateTime.now()), isTrue);
    });
  });
}