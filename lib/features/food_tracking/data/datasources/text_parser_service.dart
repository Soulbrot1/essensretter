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
        foods.add(FoodModel(
          id: uuid.v4(),
          name: _capitalizeFirst(item['name']!.trim()),
          expiryDate: days != null ? now.add(Duration(days: days)) : null,
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
    
    // Regex für verschiedene Zeitangaben - REIHENFOLGE WICHTIG!
    final patterns = [
      // 0: "Honig 5 Tage" oder "Honig paar Tage" oder "Honig einige Tage"
      RegExp(r'^(.+?)\s+(\d+|paar|einige)\s*tag(?:e|en)?$'),
      // 1: "Salami morgen" oder "Salami gestern" oder "Salami vorgestern"  
      RegExp(r'^(.+?)\s+(morgen|übermorgen|heute|gestern|vorgestern)$'),
      // 2: "Käse 2 Wochen" oder "Käse nächste Woche" oder "Käse übernächste Woche"
      RegExp(r'^(.+?)\s+(\d+|nächste|übernächste)\s*woche(?:n)?$'),
      // 3: "Milch 4.08" oder "Milch 4/8" oder "Milch 4-8" oder "Milch 2.8."
      RegExp(r'^(.+?)\s+(\d{1,2})[\.\/\-](\d{1,2})\.?(?:\s*(\d{2,4}))?$'),
      // 4: "Brot am 8." (nur Tag ohne Monat)
      RegExp(r'^(.+?)\s+am\s+(\d{1,2})\.?$'),
      // 5: "Käse 4. August" oder "Käse 4 August" oder "Käse Ende März"
      RegExp(r'^(.+?)\s+(?:(\d{1,2})\.?\s*|(anfang|mitte|ende)\s+)(januar|jan|jän|jänner|februar|feb|febr|märz|mär|mrz|mar|april|apr|mai|juni|jun|juli|jul|august|aug|augus|september|sep|sept|oktober|okt|november|nov|dezember|dez)(?:uar|ruar|ust|tember|ober|ember)?$', caseSensitive: false),
      // 6: "Brot 2 Monate"
      RegExp(r'^(.+?)\s+(\d+)\s*monat(?:e)?$'),
      // 7: "Joghurt nächsten Dienstag" oder "Joghurt kommenden Freitag"
      RegExp(r'^(.+?)\s+(nächsten|kommenden|diesen|übernächsten)\s*(montag|dienstag|mittwoch|donnerstag|freitag|samstag|sonntag)$'),
      // 8: "Wurst Ende der Woche"
      RegExp(r'^(.+?)\s+(ende\s+der\s+woche|anfang\s+der\s+woche)$'),
    ];
    
    // Versuche Muster zu matchen
    for (int i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final match = pattern.firstMatch(segment);
      if (match != null) {
        final foodName = match.group(1)?.trim();
        if (foodName == null || foodName.isEmpty) continue;
        
        int days = 7; // Standard
        
        switch (i) {
          case 0: // "X Tage" Pattern
            final timeValue = match.group(2)!;
            if (timeValue == 'paar') {
              days = 3;
            } else if (timeValue == 'einige') {
              days = 5;
            } else {
              days = int.tryParse(timeValue) ?? 7;
            }
            break;
            
          case 1: // "morgen/gestern" Pattern
            final timeWord = match.group(2)!;
            switch (timeWord) {
              case 'heute': days = 0; break;
              case 'morgen': days = 1; break;
              case 'übermorgen': days = 2; break;
              case 'gestern': days = -1; break;
              case 'vorgestern': days = -2; break;
              default: days = 1;
            }
            break;
            
          case 2: // "X Wochen" Pattern
            final weekValue = match.group(2)!;
            if (weekValue == 'nächste') {
              days = 7;
            } else if (weekValue == 'übernächste') {
              days = 14;
            } else {
              final weeks = int.tryParse(weekValue) ?? 1;
              days = weeks * 7;
            }
            break;
            
          case 3: // Datum mit . / - Pattern
            final day = int.tryParse(match.group(2)!) ?? 1;
            final month = int.tryParse(match.group(3)!) ?? 1;
            var year = DateTime.now().year;
            
            // Behandle Jahresangabe
            if (match.group(4) != null) {
              final yearInput = int.tryParse(match.group(4)!) ?? DateTime.now().year;
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
            break;
            
          case 4: // "am X." Pattern
            final day = int.tryParse(match.group(2)!) ?? 1;
            final now = DateTime.now();
            final currentMonth = now.month;
            final currentYear = now.year;
            
            try {
              var targetDate = DateTime(currentYear, currentMonth, day);
              // Wenn der Tag dieses Monats schon vorbei ist, nimm nächsten Monat
              if (targetDate.isBefore(now) || targetDate.day == now.day) {
                if (currentMonth == 12) {
                  targetDate = DateTime(currentYear + 1, 1, day);
                } else {
                  targetDate = DateTime(currentYear, currentMonth + 1, day);
                }
              }
              days = targetDate.difference(now).inDays;
            } catch (e) {
              days = 7;
            }
            break;
            
          case 5: // Monatsnamen Pattern
            final now = DateTime.now();
            final year = now.year;
            int day;
            
            // Prüfe ob es "Anfang/Mitte/Ende Monat" ist
            if (match.group(3) != null) {
              final position = match.group(3)!.toLowerCase();
              final monthName = match.group(4)!.toLowerCase();
              final month = _getMonthFromName(monthName);
              
              if (position == 'anfang') {
                day = 1;
              } else if (position == 'mitte') {
                day = 15;
              } else { // ende
                // Letzter Tag des Monats
                day = DateTime(year, month + 1, 0).day;
              }
              
              try {
                var targetDate = DateTime(year, month, day);
                if (targetDate.isBefore(now)) {
                  targetDate = DateTime(year + 1, month, day);
                }
                days = targetDate.difference(now).inDays;
              } catch (e) {
                days = 7;
              }
            } else {
              // Normales Datum "4. August"
              day = int.tryParse(match.group(2)!) ?? 1;
              final monthName = match.group(4)!.toLowerCase();
              final month = _getMonthFromName(monthName);
              
              try {
                var targetDate = DateTime(year, month, day);
                if (targetDate.isBefore(now)) {
                  targetDate = DateTime(year + 1, month, day);
                }
                days = targetDate.difference(now).inDays;
              } catch (e) {
                days = 7;
              }
            }
            break;
            
          case 6: // "X Monate" Pattern
            final months = int.tryParse(match.group(2)!) ?? 1;
            days = months * 30;
            break;
            
          case 7: // Wochentage Pattern
            final modifier = match.group(2)!.toLowerCase();
            final weekdayName = match.group(3)!.toLowerCase();
            final targetWeekday = _getWeekdayFromName(weekdayName);
            final now = DateTime.now();
            final currentWeekday = now.weekday;
            
            int daysToAdd = targetWeekday - currentWeekday;
            
            if (modifier == 'diesen') {
              // Diese Woche
              if (daysToAdd <= 0) daysToAdd += 7;
            } else if (modifier == 'nächsten' || modifier == 'kommenden') {
              // Nächste Woche
              if (daysToAdd <= 0) {
                daysToAdd += 7;
              } else {
                daysToAdd += 7;
              }
            } else if (modifier == 'übernächsten') {
              // Übernächste Woche
              daysToAdd += 14;
              if (daysToAdd <= 14) daysToAdd += 7;
            }
            
            days = daysToAdd;
            break;
            
          case 8: // "Ende der Woche" Pattern
            final phrase = match.group(2)!.toLowerCase();
            final now = DateTime.now();
            
            if (phrase.contains('ende')) {
              // Bis Sonntag
              days = 7 - now.weekday;
            } else {
              // Anfang der Woche (Montag)
              days = 8 - now.weekday; // Nächster Montag
            }
            break;
        }
        
        return {
          'name': foodName,
          'days': days,
        };
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
      'januar': 1, 'jan': 1, 'jän': 1, 'jänner': 1,
      'februar': 2, 'feb': 2, 'febr': 2,
      'märz': 3, 'mär': 3, 'mrz': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'mai': 5,
      'juni': 6, 'jun': 6,
      'juli': 7, 'jul': 7,
      'august': 8, 'aug': 8, 'augus': 8,
      'september': 9, 'sep': 9, 'sept': 9,
      'oktober': 10, 'okt': 10,
      'november': 11, 'nov': 11,
      'dezember': 12, 'dez': 12,
    };
    
    return months[monthName] ?? 1;
  }
  
  int _getWeekdayFromName(String weekdayName) {
    final weekdays = {
      'montag': 1,
      'dienstag': 2,
      'mittwoch': 3,
      'donnerstag': 4,
      'freitag': 5,
      'samstag': 6,
      'sonntag': 7,
    };
    
    return weekdays[weekdayName] ?? 1;
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