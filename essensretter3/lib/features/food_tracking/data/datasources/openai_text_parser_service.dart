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
Extrahiere Lebensmittel aus folgendem deutschen Text und gib eine JSON-Antwort zurück:

Text: "$text"

Antworte NUR mit diesem JSON-Format:
{
  "defaultDays": <erkannte_haltbarkeitstage_als_zahl>,
  "foods": [
    {
      "name": "<lebensmittel_name>",
      "category": "<kategorie_oder_null>"
    }
  ]
}

Regeln:
- Erkenne Zeitangaben: "3 Tage"=3, "morgen"=1, "übermorgen"=2, "heute"=0, "1 Woche"=7
- Ignoriere Zeitangaben, Mengen und Zahlen bei der Lebensmittel-Extraktion
- Nur echte Lebensmittel extrahieren, keine Zeitangaben oder Mengen
- Kategorien: "Obst", "Gemüse", "Milchprodukte", "Fleisch", "Brot & Backwaren", "Getränke", null
- Standard: 7 Tage wenn keine Zeitangabe gefunden
- Beispiel: "3 Tage Milch und 2 Äpfel" → defaultDays: 3, foods: [{"name": "Milch", "category": "Milchprodukte"}, {"name": "Äpfel", "category": "Obst"}]
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
      final defaultDays = parsedData['defaultDays'] as int? ?? 7;
      final foodsData = parsedData['foods'] as List<dynamic>? ?? [];
      
      final now = DateTime.now();
      final List<FoodModel> foods = [];

      for (final foodData in foodsData) {
        final foodMap = foodData as Map<String, dynamic>;
        final name = foodMap['name'] as String?;
        final category = foodMap['category'] as String?;
        
        if (name != null && name.trim().isNotEmpty) {
          foods.add(FoodModel(
            id: uuid.v4(),
            name: _capitalizeFirst(name.trim()),
            expiryDate: now.add(Duration(days: defaultDays)),
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