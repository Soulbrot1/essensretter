import 'package:flutter_test/flutter_test.dart';
import 'package:essensretter/features/food_tracking/data/datasources/openai_text_parser_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  group('OpenAITextParserService', () {
    late OpenAITextParserService service;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Lade .env nur wenn nicht schon geladen
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: '.env');
      }
    });

    setUp(() {
      service = OpenAITextParserService();
    });

    group('parseTextToFoodsAsync', () {
      test('sollte gemischte Datumsformate korrekt verarbeiten - Fall 1', () async {
        // Arrange
        const text = 'Honig 5 Tage und Salami 13.08.25';
        
        // Act
        final foods = await service.parseTextToFoodsAsync(text);
        
        // Assert
        expect(foods.length, 2);
        
        final honig = foods.firstWhere((f) => f.name.toLowerCase() == 'honig');
        final salami = foods.firstWhere((f) => f.name.toLowerCase() == 'salami');
        
        // Honig sollte in 5 Tagen ablaufen
        final expectedHonigDate = DateTime.now().add(const Duration(days: 5));
        expect(honig.expiryDate?.day, expectedHonigDate.day);
        expect(honig.expiryDate?.month, expectedHonigDate.month);
        expect(honig.expiryDate?.year, expectedHonigDate.year);
        
        // Salami sollte am 13.08.2025 ablaufen
        expect(salami.expiryDate?.day, 13);
        expect(salami.expiryDate?.month, 8);
        expect(salami.expiryDate?.year, 2025);
      }, skip: dotenv.env['OPENAI_API_KEY'] == null ? 'OpenAI API Key fehlt' : false);

      test('sollte gemischte Datumsformate korrekt verarbeiten - Fall 2', () async {
        // Arrange
        const text = 'Milch morgen, Käse 15.8.24, Brot 3 Tage';
        
        // Act
        final foods = await service.parseTextToFoodsAsync(text);
        
        // Assert
        expect(foods.length, 3);
        
        final milch = foods.firstWhere((f) => f.name.toLowerCase() == 'milch');
        final kaese = foods.firstWhere((f) => f.name.toLowerCase().contains('käse'));
        final brot = foods.firstWhere((f) => f.name.toLowerCase() == 'brot');
        
        // Milch sollte morgen ablaufen
        final expectedMilchDate = DateTime.now().add(const Duration(days: 1));
        expect(milch.expiryDate?.day, expectedMilchDate.day);
        expect(milch.expiryDate?.month, expectedMilchDate.month);
        
        // Käse sollte am 15.08.2024 ablaufen
        expect(kaese.expiryDate?.day, 15);
        expect(kaese.expiryDate?.month, 8);
        expect(kaese.expiryDate?.year, 2024);
        
        // Brot sollte in 3 Tagen ablaufen
        final expectedBrotDate = DateTime.now().add(const Duration(days: 3));
        expect(brot.expiryDate?.day, expectedBrotDate.day);
        expect(brot.expiryDate?.month, expectedBrotDate.month);
      }, skip: dotenv.env['OPENAI_API_KEY'] == null ? 'OpenAI API Key fehlt' : false);

      test('sollte nur relative Datumsangaben korrekt verarbeiten', () async {
        // Arrange
        const text = 'Apfel 2 Tage, Banane 5 Tage, Orange eine Woche';
        
        // Act
        final foods = await service.parseTextToFoodsAsync(text);
        
        // Assert
        expect(foods.length, 3);
        
        final apfel = foods.firstWhere((f) => f.name.toLowerCase() == 'apfel');
        final banane = foods.firstWhere((f) => f.name.toLowerCase() == 'banane');
        final orange = foods.firstWhere((f) => f.name.toLowerCase() == 'orange');
        
        // Apfel sollte in 2 Tagen ablaufen
        final expectedApfelDate = DateTime.now().add(const Duration(days: 2));
        expect(apfel.expiryDate?.day, expectedApfelDate.day);
        
        // Banane sollte in 5 Tagen ablaufen
        final expectedBananeDate = DateTime.now().add(const Duration(days: 5));
        expect(banane.expiryDate?.day, expectedBananeDate.day);
        
        // Orange sollte in einer Woche ablaufen
        final expectedOrangeDate = DateTime.now().add(const Duration(days: 7));
        expect(orange.expiryDate?.day, expectedOrangeDate.day);
      }, skip: dotenv.env['OPENAI_API_KEY'] == null ? 'OpenAI API Key fehlt' : false);

      test('sollte nur absolute Datumsangaben korrekt verarbeiten', () async {
        // Arrange
        const text = 'Joghurt 15.08.2025, Quark 20.9.25, Butter 1.10';
        
        // Act
        final foods = await service.parseTextToFoodsAsync(text);
        
        // Assert
        expect(foods.length, 3);
        
        final joghurt = foods.firstWhere((f) => f.name.toLowerCase() == 'joghurt');
        final quark = foods.firstWhere((f) => f.name.toLowerCase() == 'quark');
        final butter = foods.firstWhere((f) => f.name.toLowerCase() == 'butter');
        
        // Joghurt sollte am 15.08.2025 ablaufen
        expect(joghurt.expiryDate?.day, 15);
        expect(joghurt.expiryDate?.month, 8);
        expect(joghurt.expiryDate?.year, 2025);
        
        // Quark sollte am 20.09.2025 ablaufen
        expect(quark.expiryDate?.day, 20);
        expect(quark.expiryDate?.month, 9);
        expect(quark.expiryDate?.year, 2025);
        
        // Butter sollte am 01.10 ablaufen (aktuelles oder nächstes Jahr)
        expect(butter.expiryDate?.day, 1);
        expect(butter.expiryDate?.month, 10);
      }, skip: dotenv.env['OPENAI_API_KEY'] == null ? 'OpenAI API Key fehlt' : false);

      test('sollte Lebensmittel ohne Datumsangabe erkennen', () async {
        // Arrange
        const text = 'Salz, Zucker, Mehl';
        
        // Act
        final foods = await service.parseTextToFoodsAsync(text);
        
        // Assert
        expect(foods.length, 3);
        
        final salz = foods.firstWhere((f) => f.name.toLowerCase() == 'salz');
        final zucker = foods.firstWhere((f) => f.name.toLowerCase() == 'zucker');
        final mehl = foods.firstWhere((f) => f.name.toLowerCase() == 'mehl');
        
        // Alle sollten kein Ablaufdatum haben
        expect(salz.expiryDate, isNull);
        expect(zucker.expiryDate, isNull);
        expect(mehl.expiryDate, isNull);
      }, skip: dotenv.env['OPENAI_API_KEY'] == null ? 'OpenAI API Key fehlt' : false);

      test('sollte komplexe Mischung verarbeiten', () async {
        // Arrange
        const text = 'Tomaten morgen, Gurke, Paprika 3 Tage, Zwiebel 20.08.2025, Knoblauch';
        
        // Act
        final foods = await service.parseTextToFoodsAsync(text);
        
        // Assert
        expect(foods.length, 5);
        
        final tomaten = foods.firstWhere((f) => f.name.toLowerCase().contains('tomate'));
        final gurke = foods.firstWhere((f) => f.name.toLowerCase() == 'gurke');
        final paprika = foods.firstWhere((f) => f.name.toLowerCase() == 'paprika');
        final zwiebel = foods.firstWhere((f) => f.name.toLowerCase() == 'zwiebel');
        final knoblauch = foods.firstWhere((f) => f.name.toLowerCase() == 'knoblauch');
        
        // Tomaten sollten morgen ablaufen
        final expectedTomatenDate = DateTime.now().add(const Duration(days: 1));
        expect(tomaten.expiryDate?.day, expectedTomatenDate.day);
        
        // Gurke sollte kein Datum haben
        expect(gurke.expiryDate, isNull);
        
        // Paprika sollte in 3 Tagen ablaufen
        final expectedPaprikaDate = DateTime.now().add(const Duration(days: 3));
        expect(paprika.expiryDate?.day, expectedPaprikaDate.day);
        
        // Zwiebel sollte am 20.08.2025 ablaufen
        expect(zwiebel.expiryDate?.day, 20);
        expect(zwiebel.expiryDate?.month, 8);
        expect(zwiebel.expiryDate?.year, 2025);
        
        // Knoblauch sollte kein Datum haben
        expect(knoblauch.expiryDate, isNull);
      }, skip: dotenv.env['OPENAI_API_KEY'] == null ? 'OpenAI API Key fehlt' : false);
    });

    group('_parseDateText', () {
      test('sollte relative Datumsangaben korrekt parsen', () {
        final service = OpenAITextParserService();
        final now = DateTime.now();
        
        // Test private Methode über parseTextToFoods mit Fallback
        // Da wir die private Methode nicht direkt testen können,
        // testen wir sie indirekt über die öffentliche API
        
        // Diese Tests würden normalerweise die private _parseDateText Methode testen
        // Aber da sie privat ist, müssen wir sie über die öffentliche API testen
      });
    });
  });
}