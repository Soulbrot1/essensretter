import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';
import 'recipe_service.dart';

class OpenAIRecipeService implements RecipeService {
  final String _apiKey;
  
  OpenAIRecipeService() : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  @override
  Future<List<RecipeModel>> generateRecipes(List<String> availableIngredients) async {
    debugPrint('OpenAI Recipe Service aufgerufen mit Zutaten: $availableIngredients');
    debugPrint('API Key vorhanden: ${_apiKey.isNotEmpty}');
    
    if (_apiKey.isEmpty) {
      debugPrint('OpenAI API Key nicht gefunden');
      throw Exception('OpenAI API Key nicht konfiguriert');
    }

    if (availableIngredients.isEmpty) {
      debugPrint('Keine Zutaten verfügbar');
      return [];
    }

    try {
      final ingredientsText = availableIngredients.join(', ');
      final prompt = '''
Du bist ein kreativer Koch-Assistent. Erstelle 1 einfaches, sinnvolles Rezept basierend auf einigen der verfügbaren Zutaten.

VERFÜGBARE ZUTATEN: $ingredientsText

Für das Rezept erstelle:
- title: Kreativer Name des Gerichts
- cookingTime: Geschätzte Zubereitungszeit (z.B. "30 Minuten")
- vorhanden: Array mit Zutaten die bereits vorhanden sind (wähle sinnvoll aus der verfügbaren Liste)
- ueberpruefen: Array mit zusätzlichen Zutaten die eventuell gekauft werden müssen
- instructions: Schritt-für-Schritt Anleitung zur Zubereitung

WICHTIG: 
- Du musst NICHT alle verfügbaren Zutaten verwenden
- Wähle nur die Zutaten aus, die zu einem sinnvollen Gericht zusammenpassen
- Erstelle ein einfaches, praktisches Gericht
- Maximal 2-3 zusätzliche Zutaten in "ueberpruefen"
- Fokus auf Geschmack und Einfachheit, nicht auf Zutatenverbrauch
- Das Rezept soll alltagstauglich und lecker sein
- Sei kreativ und variiere die Gerichte bei wiederholten Anfragen

Antworte mit einem JSON-Objekt mit einem "recipes" Array:

{
  "recipes": [
    {
      "title": "Rezeptname",
      "cookingTime": "Zeit",
      "vorhanden": ["zutat1", "zutat2"],
      "ueberpruefen": ["zusatz1", "zusatz2"],
      "instructions": "Schritt-für-Schritt Anleitung..."
    }
  ]
}
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
          'temperature': 0.7,
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('OpenAI API Fehler: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        throw Exception('Fehler bei der Rezeptgenerierung: ${response.statusCode}');
      }

      final responseBody = json.decode(response.body);
      final content = responseBody['choices'][0]['message']['content'];
      
      // Extrahiere JSON aus der Antwort
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        debugPrint('Kein JSON in OpenAI Antwort gefunden');
        throw Exception('Ungültige Antwort von der KI');
      }
      
      final parsedData = json.decode(jsonMatch.group(0)!);
      debugPrint('OpenAI Recipe Response parsed: $parsedData');
      
      final recipes = _createRecipeModels(parsedData);
      debugPrint('Erstellte ${recipes.length} Rezepte');
      return recipes;
    } catch (e) {
      debugPrint('OpenAI Recipe Generation Fehler: $e');
      rethrow;
    }
  }

  List<RecipeModel> _createRecipeModels(Map<String, dynamic> parsedData) {
    try {
      final recipesData = parsedData['recipes'] as List<dynamic>? ?? [];
      final List<RecipeModel> recipes = [];

      for (final recipeData in recipesData) {
        final recipeMap = recipeData as Map<String, dynamic>;
        
        final recipe = RecipeModel.fromJson(recipeMap);
        recipes.add(recipe);
      }

      return recipes;
    } catch (e) {
      debugPrint('Fehler beim Erstellen der RecipeModels: $e');
      throw Exception('Fehler beim Verarbeiten der Rezepte');
    }
  }
}