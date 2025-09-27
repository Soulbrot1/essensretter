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
        final days = item['days'];
        foods.add(
          FoodModel(
            id: uuid.v4(),
            name: _capitalizeFirst(item['name']!.trim()),
            expiryDate: days != null ? now.add(Duration(days: days)) : null,
            addedDate: now,
            category: _guessCategory(item['name']!),
          ),
        );
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
      // "Milch 4.08" oder "Milch 4.8" oder "Milch 2.8." (Datum)
      RegExp(r'^(.+?)\s+(\d{1,2})\.(\d{1,2})\.?(?:\s*(\d{4}))?$'),
      // "Käse 4. August" oder "Käse 4 August" oder "Käse 4. aug"
      RegExp(
        r'^(.+?)\s+(\d{1,2})\.?\s*(januar|jan|februar|feb|märz|mär|april|apr|mai|juni|jun|juli|jul|august|aug|september|sep|oktober|okt|november|nov|dezember|dez)(?:uar|ruar|ust|tember|ober|ember)?$',
        caseSensitive: false,
      ),
      // "Brot 2 Monate"
      RegExp(r'^(.+?)\s+(\d+)\s*monat(?:e)?$'),
      // "Salami 1 Jahr" oder "Honig 2 Jahre"
      RegExp(r'^(.+?)\s+(\d+)\s*jahr(?:e)?$'),
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
          days = timeWord == 'heute'
              ? 0
              : timeWord == 'morgen'
              ? 1
              : 2;
        } else if (pattern.pattern.contains('woche')) {
          // "2 Wochen"
          final weeks = int.tryParse(match.group(2)!) ?? 1;
          days = weeks * 7;
        } else if (pattern.pattern.contains('monat')) {
          // "2 Monate"
          final months = int.tryParse(match.group(2)!) ?? 1;
          days = months * 30;
        } else if (pattern.pattern.contains('jahr')) {
          // "1 Jahr" oder "2 Jahre"
          final years = int.tryParse(match.group(2)!) ?? 1;
          days = years * 365;
        } else if (pattern.pattern.contains('januar|jan|februar')) {
          // Datum mit Monatsnamen "4. August"
          final day = int.tryParse(match.group(2)!) ?? 1;
          final monthName = match.group(3)!.toLowerCase();
          final month = _getMonthFromName(monthName);
          final now = DateTime.now();
          final year = now.year;

          try {
            var targetDate = DateTime(year, month, day);
            // Wenn das Datum in der Vergangenheit liegt, nimm nächstes Jahr
            if (targetDate.isBefore(now)) {
              targetDate = DateTime(year + 1, month, day);
            }
            days = targetDate.difference(now).inDays;
          } catch (e) {
            days = 7; // Fallback bei ungültigem Datum
          }
        } else if (pattern.pattern.contains(r'\d{1,2}\.\d{1,2}')) {
          // Datum "4.08" oder "4.8" oder "4.08.2025"
          final day = int.tryParse(match.group(2)!) ?? 1;
          final month = int.tryParse(match.group(3)!) ?? 1;
          var year = DateTime.now().year;

          // Behandle Jahresangabe
          if (match.group(4) != null) {
            final yearInput =
                int.tryParse(match.group(4)!) ?? DateTime.now().year;
            // 2-stellige Jahre: 00-30 = 2000-2030, 31-99 = 1931-1999
            if (yearInput < 100) {
              year = yearInput <= 30 ? 2000 + yearInput : 1900 + yearInput;
            } else {
              year = yearInput;
            }
          }

          try {
            final now = DateTime.now();
            var targetDate = DateTime(year, month, day);
            // Nur bei fehlender Jahresangabe: Wenn das Datum in der Vergangenheit liegt, nimm nächstes Jahr
            if (targetDate.isBefore(now) && match.group(4) == null) {
              targetDate = DateTime(year + 1, month, day);
            }
            days = targetDate.difference(now).inDays;
          } catch (e) {
            days = 7; // Fallback bei ungültigem Datum
          }
        }

        return {'name': foodName, 'days': days};
      }
    }

    // Kein Zeitmuster gefunden - nur Lebensmittelname (ohne Datum)
    final cleanName = segment.replaceAll(RegExp(r'[^\w\säöüÄÖÜß-]'), '').trim();
    if (cleanName.isNotEmpty) {
      return {
        'name': cleanName,
        'days': null, // Kein Datum
      };
    }

    return null;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  int _getMonthFromName(String monthName) {
    final months = {
      'januar': 1,
      'jan': 1,
      'februar': 2,
      'feb': 2,
      'märz': 3,
      'mär': 3,
      'april': 4,
      'apr': 4,
      'mai': 5,
      'juni': 6,
      'jun': 6,
      'juli': 7,
      'jul': 7,
      'august': 8,
      'aug': 8,
      'september': 9,
      'sep': 9,
      'oktober': 10,
      'okt': 10,
      'november': 11,
      'nov': 11,
      'dezember': 12,
      'dez': 12,
    };

    return months[monthName] ?? 1;
  }

  String? _guessCategory(String foodName) {
    final categories = {
      'Obst': [
        'apfel',
        'birne',
        'banane',
        'orange',
        'kiwi',
        'traube',
        'beere',
        'kirsche',
        'pflaume',
        'pfirsich',
      ],
      'Gemüse': [
        'tomate',
        'gurke',
        'salat',
        'karotte',
        'zwiebel',
        'paprika',
        'brokkoli',
        'spinat',
        'kohl',
      ],
      'Milchprodukte': [
        'milch',
        'käse',
        'joghurt',
        'quark',
        'butter',
        'sahne',
        'schmand',
        // Milchersatzprodukte
        'mandelmilch',
        'sojamilch',
        'hafermilch',
        'kokosmilch',
        'reismilch',
        'mandeljogurt',
        'mandel-jogurt',
        'sojajoghurt',
        'soja-joghurt',
        'haferjoghurt',
        'hafer-joghurt',
        'kokosjoghurt',
        'kokos-joghurt',
        'pflanzenmilch',
        'pflanzenjoghurt',
      ],
      'Fleisch': [
        'fleisch',
        'wurst',
        'schinken',
        'hähnchen',
        'rind',
        'schwein',
        'hack',
        'steak',
      ],
      'Brot & Backwaren': [
        'brot',
        'brötchen',
        'toast',
        'kuchen',
        'gebäck',
        'keks',
      ],
      'Getränke': [
        'saft',
        'wasser',
        'cola',
        'limo',
        'tee',
        'kaffee',
        'bier',
        'wein',
      ],
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
