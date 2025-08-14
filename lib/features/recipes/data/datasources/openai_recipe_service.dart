import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/recipe.dart';
import '../models/recipe_model.dart';
import 'recipe_service.dart';

class OpenAIRecipeService implements RecipeService {
  final String _apiKey;

  OpenAIRecipeService() : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  @override
  Future<List<RecipeModel>> generateRecipes(
    List<String> availableIngredients, {
    List<Recipe> previousRecipes = const [],
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('OpenAI API Key nicht konfiguriert');
    }

    if (availableIngredients.isEmpty) {
      return [];
    }

    try {
      final ingredientsText = availableIngredients.join(', ');

      // Erstelle Liste der vorherigen Rezepte mit Details zur Vermeidung von Duplikaten
      final previousRecipeNames = previousRecipes
          .map((recipe) => recipe.title)
          .toList();
      final previousRecipeTypes = previousRecipes
          .map(
            (recipe) =>
                '${recipe.title} (${recipe.vorhandenAsStrings.join(", ")})',
          )
          .toList();

      final previousRecipesText = previousRecipeNames.isNotEmpty
          ? '\n\nBEREITS VORGESCHLAGENE REZEPTE UND ZUTATEN (KOMPLETT VERMEIDEN):\n${previousRecipeTypes.join('\n')}\n\nVERMEIDE ÄHNLICHE GERICHTE WIE: ${previousRecipeNames.join(', ')}'
          : '';

      final prompt =
          '''
Du bist ein kreativer Koch-Assistent. Erstelle 1 einfaches, sinnvolles Rezept FÜR 2 PERSONEN basierend auf einigen der verfügbaren Zutaten.

VERFÜGBARE ZUTATEN: $ingredientsText$previousRecipesText

Für das Rezept erstelle:
- title: Kreativer Name des Gerichts
- cookingTime: Geschätzte Zubereitungszeit (z.B. "30 Minuten")
- vorhanden: Array mit Zutaten die bereits vorhanden sind MIT GENAUEN MENGENANGABEN für 2 Personen (z.B. "200g Mehl", "2 EL Öl", "1 große Zwiebel")
- ueberpruefen: Array mit zusätzlichen Zutaten die eventuell gekauft werden müssen MIT GENAUEN MENGENANGABEN für 2 Personen
- instructions: Detaillierte Schritt-für-Schritt Anleitung die ALLE verwendeten Zutaten mit Mengen erwähnt
- servings: IMMER 2 (für 2 Personen)

WICHTIG für die instructions: 
- Schreibe KURZE, PRÄGNANTE Sätze
- Verwende Stichpunkte und Bulletpoints wo möglich
- Nummeriere die Hauptschritte (1., 2., 3., etc.)
- Erwähne ALLE Zutaten aus "vorhanden" und "ueberpruefen" 
- Vermeide Füllwörter und lange Erklärungen
- Nutze einfache, klare Sprache
- Achte auf korrekte Rechtschreibung

WICHTIG für die Rezepterstellung:
- Du musst NICHT alle verfügbaren Zutaten verwenden
- WICHTIG: Wähle nur Zutaten die GESCHMACKLICH und KULINARISCH zusammenpassen
- Erstelle nur REALISTISCHE und LECKERE Gerichte die Menschen wirklich essen würden
- Vermeide seltsame oder unappetitliche Kombinationen
- Achte auf Harmonie von süß/herzhaft - keine chaotischen Mischungen
- Erstelle ein einfaches, praktisches Gericht
- Maximal 2-3 zusätzliche Zutaten in "ueberpruefen"
- Fokus auf Geschmack und Einfachheit
- KRITISCH: ALLE Zutaten müssen EXAKTE MENGENANGABEN haben (z.B. "300g", "2 EL", "1 Stück")
- Verwende realistische Portionsgrößen für 2 Personen
- Gib NIEMALS Zutaten ohne Menge an
- STRENG VERBOTEN: KEINE Salate wenn bereits Salat vorgeschlagen wurde
- STRENG VERBOTEN: KEINE ähnlichen Gerichte oder Variationen bereits vorgeschlagener Rezepte
- STRENG VERBOTEN: KEINE Wiederverwendung derselben Hauptzutat-Kombinationen
- Denke an KOMPLETT ANDERE Gerichte: Suppen, Pfannengerichte, Aufläufe, Wraps, Smoothies, Pasta, etc.
- Sei RADIKAL ANDERS - völlig neue Richtung!

BEISPIELE für GUTE Kombinationen:
- Süße Gerichte: Apfel + Honig + Zimt (z.B. Apfel-Smoothie)
- Herzhafte Gerichte: Salat + Karotte + Nüsse (z.B. Gemüsesuppe)
- Wraps: Salat + Gemüse + Käse/Fleisch (NIEMALS süße Zutaten in Wraps!)

Antworte mit einem JSON-Objekt mit einem "recipes" Array:

{
  "recipes": [
    {
      "title": "Rezeptname",
      "cookingTime": "Zeit",
      "vorhanden": ["200g Mehl", "2 EL Öl"],
      "ueberpruefen": ["1 große Zwiebel", "300ml Gemüsebrühe"],
      "instructions": "1. Vorbereitung:\\n• Zutat vorbereiten\\n• Weitere Vorbereitung\\n\\n2. Zubereitung:\\n• Hauptschritt\\n• Nächster Schritt\\n\\n3. Servieren:\\n• Anrichten\\n• Genießen",
      "servings": 2
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
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.9,
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Fehler bei der Rezeptgenerierung: ${response.statusCode}',
        );
      }

      final responseBody = json.decode(response.body);
      final content = responseBody['choices'][0]['message']['content'];

      // Extrahiere JSON aus der Antwort
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        throw Exception('Ungültige Antwort von der KI');
      }

      final parsedData = json.decode(jsonMatch.group(0)!);

      final recipes = _createRecipeModels(parsedData);

      // Zusätzliche lokale Duplikatsprüfung
      final filteredRecipes = _filterDuplicateRecipes(recipes, previousRecipes);

      return filteredRecipes;
    } catch (e) {
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
      throw Exception('Fehler beim Verarbeiten der Rezepte');
    }
  }

  List<RecipeModel> _filterDuplicateRecipes(
    List<RecipeModel> newRecipes,
    List<Recipe> previousRecipes,
  ) {
    if (previousRecipes.isEmpty) return newRecipes;

    final previousTitles = previousRecipes
        .map((r) => r.title.toLowerCase())
        .toSet();
    final previousIngredientCombos = previousRecipes
        .map((r) => r.vorhandenAsStrings.map((i) => i.toLowerCase()).toSet())
        .toList();

    return newRecipes.where((recipe) {
      final recipeTitle = recipe.title.toLowerCase();
      final recipeIngredients = recipe.vorhandenAsStrings
          .map((i) => i.toLowerCase())
          .toSet();

      // Prüfe auf exakte Titel-Übereinstimmung
      if (previousTitles.contains(recipeTitle)) {
        return false;
      }

      // Prüfe auf ähnliche Titel (Salat-Variationen)
      if (recipeTitle.contains('salat') &&
          previousTitles.any((title) => title.contains('salat'))) {
        return false;
      }

      // Prüfe auf ähnliche Zutatenkombinationen (>70% Übereinstimmung)
      for (final prevCombo in previousIngredientCombos) {
        final intersection = recipeIngredients.intersection(prevCombo);
        final union = recipeIngredients.union(prevCombo);
        final similarity = intersection.length / union.length;

        if (similarity > 0.7) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
