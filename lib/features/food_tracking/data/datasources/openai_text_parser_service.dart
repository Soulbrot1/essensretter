import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      debugPrint('OpenAI API Key nicht gefunden, verwende einfachen Parser');
      return TextParserServiceImpl().parseTextToFoods(text);
    }
    
    // Für OpenAI verwenden wir die async Methode
    throw UnimplementedError('Verwende parseTextToFoodsAsync für OpenAI');
  }

  Future<List<FoodModel>> parseTextToFoodsAsync(String text) async {
    debugPrint('OpenAI Parser aufgerufen mit Text: "$text"');
    debugPrint('API Key vorhanden: ${_apiKey.isNotEmpty}');
    
    if (_apiKey.isEmpty) {
      debugPrint('OpenAI API Key nicht gefunden, verwende einfachen Parser');
      return TextParserServiceImpl().parseTextToFoods(text);
    }

    try {
      final now = DateTime.now();
      final prompt = '''
Extrahiere Lebensmittel-Datum-Paare aus diesem deutschen Text:

Text: "$text"
Heutiges Datum: ${now.day}.${now.month}.${now.year}

WICHTIG: Erkenne Lebensmittel im Text - sowohl mit als auch ohne Zeitangabe.
Wenn ein Lebensmittel keine Zeitangabe hat, setze "days" auf null.
KEINE automatischen Kommas hinzufügen - nutze nur die vorhandenen Wörter.

Berechne die Anzahl der Tage vom heutigen Datum bis zum Zieldatum korrekt!
WICHTIG: Bei Datumsangaben mit Jahreszahl (z.B. "7.7.25") das Datum exakt verwenden - auch wenn es in der Vergangenheit liegt!
Für vergangene Daten: negative Tageszahl verwenden!

Antworte NUR mit diesem JSON-Format:
{
  "foods": [
    {
      "name": "<exakter_lebensmittel_name_ohne_kommas>",
      "days": <anzahl_tage_bis_ablaufdatum_oder_null>,
      "category": "<kategorie_oder_null>"
    }
  ]
}

Paarungs-Regeln:
1. Suche nach direkten Nachbarschaften: "Lebensmittel + Zeitangabe"
2. Zeitangaben: 
   - "X Tage", "morgen" (1), "übermorgen" (2), "heute" (0)
   - "X Wochen" = X*7, "X Monate" = X*30
   - Datum wie "4.08", "4.8", "2.8.", "02.08"
   - Datum mit Monatsnamen: "4. August", "4 August", "4. aug"
   - Nutze das aktuelle Jahr für Datumsangaben
3. Wenn kein Datum bei einem Lebensmittel steht, setze "days": null
4. Namen exakt übernehmen ohne zusätzliche Kommas oder Wörter
5. ALLE erkannten Lebensmittel zurückgeben, auch ohne Datum

Beispiele korrekter Paarung:
- "Salami übermorgen" → {"name": "Salami", "days": 2}
- "Honig in einem monat" → {"name": "Honig", "days": 30}
- "Milch 4.08" → {"name": "Milch", "days": <tage_bis_4_august>}
- "Milch 2.8" → {"name": "Milch", "days": <tage_bis_2_august>}
- "Käse 4. August" → {"name": "Käse", "days": <tage_bis_4_august>}
- "Bier 3 Tage" → {"name": "Bier", "days": 3}
- "Gurken 7.7.25" → {"name": "Gurken", "days": -25} (wenn 7.7.25 25 Tage her ist)
- "Banane" → {"name": "Banane", "days": null}
- "Apfel und Birne" → {"name": "Apfel", "days": null}, {"name": "Birne", "days": null}

WICHTIG: Auch einzelne Lebensmittel ohne Datum extrahieren!

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
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.1,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('OpenAI API Fehler: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        return _fallbackParsing(text);
      }

      final responseBody = json.decode(response.body);
      final content = responseBody['choices'][0]['message']['content'];
      
      // Extrahiere JSON aus der Antwort (falls zusätzlicher Text vorhanden)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        debugPrint('Kein JSON in OpenAI Antwort gefunden');
        return _fallbackParsing(text);
      }
      
      final parsedData = json.decode(jsonMatch.group(0)!);
      debugPrint('OpenAI Response parsed: $parsedData');
      
      final models = _createFoodModels(parsedData);
      debugPrint('Erstellte ${models.length} FoodModels');
      return models;
    } catch (e) {
      debugPrint('OpenAI Parsing Fehler: $e');
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
        final days = foodMap['days'] as int?;
        final category = foodMap['category'] as String?;
        
        if (name != null && name.trim().isNotEmpty) {
          final DateTime? expiryDate = days != null ? now.add(Duration(days: days)) : null;
          debugPrint('Creating food: $name, days: $days, expiryDate: $expiryDate');
          
          foods.add(FoodModel(
            id: uuid.v4(),
            name: _capitalizeFirst(name.trim()),
            expiryDate: expiryDate,
            addedDate: now,
            category: category,
          ));
        }
      }

      return foods;
    } catch (e) {
      debugPrint('Fehler beim Erstellen der FoodModels: $e');
      return [];
    }
  }

  List<FoodModel> _fallbackParsing(String text) {
    debugPrint('Verwende Fallback-Parser');
    return TextParserServiceImpl().parseTextToFoods(text);
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}