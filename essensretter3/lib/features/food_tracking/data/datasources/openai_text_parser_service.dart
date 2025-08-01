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
    if (_apiKey.isEmpty) {
      debugPrint('OpenAI API Key nicht gefunden, verwende einfachen Parser');
      return TextParserServiceImpl().parseTextToFoods(text);
    }

    try {
      final prompt = '''
Extrahiere Lebensmittel-Datum-Paare aus diesem deutschen Text:

Text: "$text"

WICHTIG: Erkenne direkte Paare von Lebensmittel + Zeitangabe nebeneinander im Text.
Jedes Lebensmittel braucht eine eigene Zeitangabe direkt daneben.
KEINE automatischen Kommas hinzufügen - nutze nur die vorhandenen Wörter.

Antworte NUR mit diesem JSON-Format:
{
  "foods": [
    {
      "name": "<exakter_lebensmittel_name_ohne_kommas>",
      "days": <haltbarkeit_in_tagen>,
      "category": "<kategorie_oder_null>"
    }
  ]
}

Paarungs-Regeln:
1. Suche nach direkten Nachbarschaften: "Lebensmittel + Zeitangabe"
2. Zeitangaben: "X Tage", "morgen" (1), "übermorgen" (2), "heute" (0), "X Wochen" = X*7, Datum wie "4.08"
3. Nur echte Paare extrahieren - wenn kein Datum bei einem Lebensmittel steht, ignoriere es
4. Namen exakt übernehmen ohne zusätzliche Kommas oder Wörter

Beispiele korrekter Paarung:
- "Salami übermorgen" → {"name": "Salami", "days": 2}
- "Honig in einem monat" → {"name": "Honig", "days": 30}
- "Milch 4.08" → {"name": "Milch", "days": <tage_bis_4_august>}
- "Bier 3 Tage" → {"name": "Bier", "days": 3}

FALSCH: "Salami 308 honig 3 monate" - das sind keine klaren Paare
RICHTIG: Nur wenn klar erkennbar ist welches Lebensmittel zu welchem Datum gehört

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
        debugPrint('OpenAI API Fehler: ${response.statusCode} - ${response.body}');
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
      
      return _createFoodModels(parsedData);
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
        final days = foodMap['days'] as int? ?? 7;
        final category = foodMap['category'] as String?;
        
        if (name != null && name.trim().isNotEmpty) {
          foods.add(FoodModel(
            id: uuid.v4(),
            name: _capitalizeFirst(name.trim()),
            expiryDate: now.add(Duration(days: days)),
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