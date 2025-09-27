import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/food_model.dart';
import 'text_parser_service.dart';

class OpenAITextParserService implements TextParserService {
  final String _apiKey;
  final Uuid uuid = const Uuid();

  OpenAITextParserService() : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  @override
  List<FoodModel> parseTextToFoods(String text) {
    // Fallback auf einfachen Parser wenn kein API Key
    if (_apiKey.isEmpty) {
      return TextParserServiceImpl().parseTextToFoods(text);
    }

    // Für OpenAI verwenden wir die async Methode
    throw UnimplementedError('Verwende parseTextToFoodsAsync für OpenAI');
  }

  Future<List<FoodModel>> parseTextToFoodsAsync(String text) async {
    if (_apiKey.isEmpty) {
      return TextParserServiceImpl().parseTextToFoods(text);
    }

    try {
      final now = DateTime.now();
      final prompt =
          '''
Analysiere diesen deutschen Text und extrahiere ALLE Lebensmittel mit ihren Datumsangaben.

Text: "$text"
Heutiges Datum: ${now.day}.${now.month}.${now.year}

SEHR WICHTIG: Jedes Lebensmittel muss mit seiner zugehörigen Datumsangabe erfasst werden!

Antworte NUR mit diesem JSON-Format:
{
  "foods": [
    {
      "name": "<exakter_lebensmittel_name>",
      "date_text": "<original_datum_text_oder_null>",
      "category": "<kategorie_oder_null>"
    }
  ]
}

KRITISCHE REGEL für die Zuordnung:
Analysiere den Text Wort für Wort und erkenne Muster wie:
- [Lebensmittel] [Zahl] [Zeiteinheit]: "Honig 5 Tage" → {"name": "Honig", "date_text": "5 Tage"}
- [Lebensmittel] [Datum]: "Salami 13.08.25" → {"name": "Salami", "date_text": "13.08.25"}
- [Zeitangabe] [Lebensmittel]: "morgen Milch" → {"name": "Milch", "date_text": "morgen"}
- [Lebensmittel] ohne Datum: "Butter" → {"name": "Butter", "date_text": null}

Datumsformate die erkannt werden müssen:
- Relative: "heute", "morgen", "übermorgen", "X Tage", "X Wochen", "einen Monat", "X Jahre"
- Absolute: "DD.MM.YYYY", "DD.MM.YY", "DD.MM", "D.M"
- Die Zahl und Zeiteinheit DIREKT nach/vor dem Lebensmittel gehören dazu!

BEISPIELE mit korrekter Zuordnung:
"Honig 5 Tage und Salami 13.08.25" muss ergeben:
[{"name": "Honig", "date_text": "5 Tage"}, {"name": "Salami", "date_text": "13.08.25"}]

"Milch morgen, Käse 15.8.24, Brot 3 Tage" muss ergeben:
[{"name": "Milch", "date_text": "morgen"}, {"name": "Käse", "date_text": "15.8.24"}, {"name": "Brot", "date_text": "3 Tage"}]

"Apfel 2 Tage Banane 4.9" muss ergeben:
[{"name": "Apfel", "date_text": "2 Tage"}, {"name": "Banane", "date_text": "4.9"}]

"Honig 5 Tage salami 13.08.25" muss ergeben:
[{"name": "Honig", "date_text": "5 Tage"}, {"name": "salami", "date_text": "13.08.25"}]

"Salami 1 Jahr" muss ergeben:
[{"name": "Salami", "date_text": "1 Jahr"}]

Kategorien: "Obst", "Gemüse", "Milchprodukte", "Fleisch", "Brot & Backwaren", "Getränke", null
''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.1,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode != 200) {
        return _fallbackParsing(text);
      }

      final responseBody = json.decode(response.body);
      final content = responseBody['choices'][0]['message']['content'];

      // Extrahiere JSON aus der Antwort (falls zusätzlicher Text vorhanden)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        return _fallbackParsing(text);
      }

      final parsedData = json.decode(jsonMatch.group(0)!);

      final models = _createFoodModels(parsedData);
      return models;
    } catch (e) {
      return _fallbackParsing(text);
    }
  }

  List<FoodModel> _createFoodModels(Map<String, dynamic> parsedData) {
    try {
      final foodsData = parsedData['foods'] as List<dynamic>? ?? [];

      final now = DateTime.now();
      final List<FoodModel> foods = [];

      for (final foodData in foodsData) {
        final foodMap = foodData as Map<String, dynamic>;
        final name = foodMap['name'] as String?;
        final dateText = foodMap['date_text'] as String?;
        final category = foodMap['category'] as String?;

        if (name != null && name.trim().isNotEmpty) {
          final DateTime? expiryDate = _parseDateText(dateText, now);

          foods.add(
            FoodModel(
              id: uuid.v4(),
              name: _capitalizeFirst(name.trim()),
              expiryDate: expiryDate,
              addedDate: now,
              category: category,
            ),
          );
        }
      }

      return foods;
    } catch (e) {
      return [];
    }
  }

  DateTime? _parseDateText(String? dateText, DateTime now) {
    if (dateText == null || dateText.trim().isEmpty) {
      return null;
    }

    final text = dateText.trim().toLowerCase();

    try {
      // Direkte Zeitangaben
      if (text == 'heute') return now;
      if (text == 'morgen') return now.add(const Duration(days: 1));
      if (text == 'übermorgen') return now.add(const Duration(days: 2));

      // Numerische und textuelle Zeitangaben
      int? days = _extractDays(text);
      if (days != null) {
        return now.add(Duration(days: days));
      }

      int? weeks = _extractWeeks(text);
      if (weeks != null) {
        return now.add(Duration(days: weeks * 7));
      }

      int? months = _extractMonths(text);
      if (months != null) {
        return now.add(Duration(days: months * 30));
      }

      int? years = _extractYears(text);
      if (years != null) {
        return now.add(Duration(days: years * 365));
      }

      // Vollständige Datumsangaben (dd.mm.yyyy, dd.mm.yy)
      final fullDateMatch = RegExp(
        r'(\d{1,2})\.(\d{1,2})\.(\d{2,4})',
      ).firstMatch(text);
      if (fullDateMatch != null) {
        final day = int.parse(fullDateMatch.group(1)!);
        final month = int.parse(fullDateMatch.group(2)!);
        var year = int.parse(fullDateMatch.group(3)!);

        // 2-stellige Jahre behandeln
        if (year < 100) {
          year += 2000;
        }

        final parsedDate = DateTime(year, month, day);
        return parsedDate;
      }

      // Datumsangaben ohne Jahr (dd.mm, dd.mm.)
      final dateMatch = RegExp(r'(\d{1,2})\.(\d{1,2})\.?').firstMatch(text);
      if (dateMatch != null) {
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);

        // Verwende aktuelles Jahr
        var parsedDate = DateTime(now.year, month, day);

        // Wenn das Datum in der Vergangenheit liegt, nimm nächstes Jahr
        if (parsedDate.isBefore(now)) {
          parsedDate = DateTime(now.year + 1, month, day);
        }

        return parsedDate;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  List<FoodModel> _fallbackParsing(String text) {
    return TextParserServiceImpl().parseTextToFoods(text);
  }

  int? _extractDays(String text) {
    // Numerische Tage: "3 Tage", "4 tag"
    final numericDayMatch = RegExp(r'(\d+)\s*tag[e]?').firstMatch(text);
    if (numericDayMatch != null) {
      return int.parse(numericDayMatch.group(1)!);
    }

    // Textuelle Tage
    if (text.contains('einen tag') || text.contains('ein tag')) return 1;
    if (text.contains('zwei tag')) return 2;
    if (text.contains('drei tag')) return 3;
    if (text.contains('vier tag')) return 4;
    if (text.contains('fünf tag')) return 5;
    if (text.contains('sechs tag')) return 6;
    if (text.contains('sieben tag')) return 7;
    if (text.contains('acht tag')) return 8;
    if (text.contains('neun tag')) return 9;
    if (text.contains('zehn tag')) return 10;

    return null;
  }

  int? _extractWeeks(String text) {
    // Numerische Wochen: "1 Woche", "2 wochen"
    final numericWeekMatch = RegExp(r'(\d+)\s*woche[n]?').firstMatch(text);
    if (numericWeekMatch != null) {
      return int.parse(numericWeekMatch.group(1)!);
    }

    // Textuelle Wochen
    if (text.contains('eine woche') || text.contains('ein woche')) return 1;
    if (text.contains('zwei woche')) return 2;
    if (text.contains('drei woche')) return 3;
    if (text.contains('vier woche')) return 4;

    return null;
  }

  int? _extractMonths(String text) {
    // Numerische Monate: "1 Monat", "2 monate"
    final numericMonthMatch = RegExp(r'(\d+)\s*monat[e]?').firstMatch(text);
    if (numericMonthMatch != null) {
      return int.parse(numericMonthMatch.group(1)!);
    }

    // Textuelle Monate
    if (text.contains('einen monat') || text.contains('ein monat')) return 1;
    if (text.contains('zwei monat')) return 2;
    if (text.contains('drei monat')) return 3;
    if (text.contains('in einem monat')) return 1;

    return null;
  }

  int? _extractYears(String text) {
    // Numerische Jahre: "1 Jahr", "2 jahre"
    final numericYearMatch = RegExp(r'(\d+)\s*jahr[e]?').firstMatch(text);
    if (numericYearMatch != null) {
      return int.parse(numericYearMatch.group(1)!);
    }

    // Textuelle Jahre
    if (text.contains('ein jahr') || text.contains('einem jahr')) return 1;
    if (text.contains('zwei jahr')) return 2;
    if (text.contains('drei jahr')) return 3;

    return null;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
