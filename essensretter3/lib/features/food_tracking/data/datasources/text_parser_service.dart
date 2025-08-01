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
    final now = DateTime.now();
    
    // Parse individuelle Lebensmittel mit Zeitangaben
    final items = _parseIndividualItems(text);
    
    for (final item in items) {
      if (item['name']?.trim().isNotEmpty == true) {
        foods.add(FoodModel(
          id: uuid.v4(),
          name: _capitalizeFirst(item['name']!.trim()),
          expiryDate: now.add(Duration(days: item['days'] ?? 7)),
          addedDate: now,
          category: _guessCategory(item['name']!),
        ));
      }
    }
    
    return foods;
  }
  
  List<Map<String, dynamic>> _parseIndividualItems(String text) {
    final List<Map<String, dynamic>> items = [];
    
    // Teile Text in Segmente (getrennt durch Komma, "und", etc.)
    final segments = text.split(RegExp(r'[,;]|(?:\s+und\s+)'));
    
    for (String segment in segments) {
      segment = segment.trim();
      if (segment.isEmpty) continue;
      
      final item = _parseSegment(segment);
      if (item != null) items.add(item);
    }
    
    return items;
  }
  
  Map<String, dynamic>? _parseSegment(String segment) {
    segment = segment.trim().toLowerCase();
    
    // Regex für verschiedene Zeitangaben
    final patterns = [
      // "Honig 5 Tage"
      RegExp(r'^(.+?)\s+(\d+)\s*tag(?:e|en)?$'),
      // "Salami morgen"  
      RegExp(r'^(.+?)\s+(morgen|übermorgen|heute)$'),
      // "Käse 2 Wochen"
      RegExp(r'^(.+?)\s+(\d+)\s*woche(?:n)?$'),
      // "Milch 4.08" (Datum)
      RegExp(r'^(.+?)\s+(\d{1,2})\.(\d{1,2})(?:\.(\d{4}))?$'),
    ];
    
    // Versuche Muster zu matchen
    for (final pattern in patterns) {
      final match = pattern.firstMatch(segment);
      if (match != null) {
        final foodName = match.group(1)?.trim();
        if (foodName == null || foodName.isEmpty) continue;
        
        int days = 7; // Standard
        
        if (pattern.pattern.contains('tag')) {
          // "5 Tage"
          days = int.tryParse(match.group(2)!) ?? 7;
        } else if (pattern.pattern.contains('morgen')) {
          // "morgen", "übermorgen", "heute"
          final timeWord = match.group(2)!;
          days = timeWord == 'heute' ? 0 : timeWord == 'morgen' ? 1 : 2;
        } else if (pattern.pattern.contains('woche')) {
          // "2 Wochen"
          final weeks = int.tryParse(match.group(2)!) ?? 1;
          days = weeks * 7;
        } else if (pattern.pattern.contains(r'\.')) {
          // Datum "4.08" oder "4.08.2025"
          final day = int.tryParse(match.group(2)!) ?? 1;
          final month = int.tryParse(match.group(3)!) ?? 1;
          final year = match.group(4) != null 
              ? int.tryParse(match.group(4)!) ?? DateTime.now().year
              : DateTime.now().year;
          
          try {
            final targetDate = DateTime(year, month, day);
            final now = DateTime.now();
            days = targetDate.difference(now).inDays;
            if (days < 0) days = 0; // Vergangene Daten = heute ablaufend
          } catch (e) {
            days = 7; // Fallback bei ungültigem Datum
          }
        }
        
        return {
          'name': foodName,
          'days': days,
        };
      }
    }
    
    // Kein Zeitmuster gefunden - nur Lebensmittelname
    final cleanName = segment.replaceAll(RegExp(r'[^\w\säöüÄÖÜß-]'), '').trim();
    if (cleanName.isNotEmpty) {
      return {
        'name': cleanName,
        'days': 7, // Standard: 7 Tage
      };
    }
    
    return null;
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