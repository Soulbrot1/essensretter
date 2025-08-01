import 'package:uuid/uuid.dart';
import '../models/food_model.dart';

abstract class TextParserService {
  List<FoodModel> parseTextToFoods(String text);
}

class TextParserServiceImpl implements TextParserService {
  final Uuid uuid = const Uuid();

  @override
  List<FoodModel> parseTextToFoods(String text) {
    final List<FoodModel> foods = [];
    
    // Regex für Zeitangaben
    final timePatterns = {
      r'(\d+)\s*tag(?:e|en)?': (int days) => days,
      r'(\d+)\s*woche(?:n)?': (int weeks) => weeks * 7,
      r'morgen': (_) => 1,
      r'übermorgen': (_) => 2,
      r'heute': (_) => 0,
    };
    
    // Finde Zeitangabe am Anfang des Textes
    int defaultDays = 7; // Standard: 7 Tage
    String remainingText = text.toLowerCase().trim();
    
    for (final pattern in timePatterns.entries) {
      final regex = RegExp(pattern.key, caseSensitive: false);
      final match = regex.firstMatch(remainingText);
      
      if (match != null && remainingText.indexOf(match.group(0)!) < 20) {
        if (pattern.key.contains(r'(\d+)')) {
          final number = int.tryParse(match.group(1)!) ?? 7;
          defaultDays = pattern.value(number);
        } else {
          defaultDays = pattern.value(0);
        }
        remainingText = remainingText.replaceFirst(match.group(0)!, '').trim();
        break;
      }
    }
    
    // Einfache Lebensmittel-Extraktion
    // Später durch KI ersetzen
    final foodItems = _extractFoodItems(remainingText);
    
    final now = DateTime.now();
    for (final foodName in foodItems) {
      if (foodName.trim().isNotEmpty) {
        foods.add(FoodModel(
          id: uuid.v4(),
          name: _capitalizeFirst(foodName.trim()),
          expiryDate: now.add(Duration(days: defaultDays)),
          addedDate: now,
          category: _guessCategory(foodName),
        ));
      }
    }
    
    return foods;
  }
  
  List<String> _extractFoodItems(String text) {
    // Entferne häufige Füllwörter
    final cleanText = text
        .replaceAll(RegExp(r'\b(und|oder|mit|ohne|für|in|auf|zu|von|bis)\b'), ',')
        .replaceAll(RegExp(r'[^\w\s,äöüÄÖÜß-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
    
    // Teile bei Kommas und mehreren Leerzeichen
    final items = cleanText.split(RegExp(r'[,\s]{2,}|,'));
    
    // Filtere leere und zu kurze Einträge
    return items
        .map((item) => item.trim())
        .where((item) => item.length > 1)
        .toList();
  }
  
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  String? _guessCategory(String foodName) {
    final categories = {
      'Obst': ['apfel', 'birne', 'banane', 'orange', 'kiwi', 'traube', 'beere', 'kirsche', 'pflaume', 'pfirsich'],
      'Gemüse': ['tomate', 'gurke', 'salat', 'karotte', 'zwiebel', 'paprika', 'brokkoli', 'spinat', 'kohl'],
      'Milchprodukte': ['milch', 'käse', 'joghurt', 'quark', 'butter', 'sahne', 'schmand'],
      'Fleisch': ['fleisch', 'wurst', 'schinken', 'hähnchen', 'rind', 'schwein', 'hack', 'steak'],
      'Brot & Backwaren': ['brot', 'brötchen', 'toast', 'kuchen', 'gebäck', 'keks'],
      'Getränke': ['saft', 'wasser', 'cola', 'limo', 'tee', 'kaffee', 'bier', 'wein'],
    };
    
    final lowerFood = foodName.toLowerCase();
    for (final entry in categories.entries) {
      if (entry.value.any((keyword) => lowerFood.contains(keyword))) {
        return entry.key;
      }
    }
    
    return null;
  }
}