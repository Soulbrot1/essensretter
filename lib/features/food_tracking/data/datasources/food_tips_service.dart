import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'food_tips_local_data_source.dart';

abstract class FoodTipsService {
  Future<String> getFoodStorageTips(String foodName);
  Future<String> getSpoilageIndicators(String foodName);
}

class OpenAIFoodTipsService implements FoodTipsService {
  final String _apiKey;
  final FoodTipsLocalDataSource _localDataSource;

  OpenAIFoodTipsService({FoodTipsLocalDataSource? localDataSource})
    : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '',
      _localDataSource = localDataSource ?? FoodTipsLocalDataSourceImpl();

  @override
  Future<String> getFoodStorageTips(String foodName) async {
    // 1. Zuerst in lokaler Datenbank suchen
    final localTips = await _localDataSource.getFoodTips(foodName);
    if (localTips != null) {
      return localTips['storage_tips']!;
    }

    // 2. Falls nicht gefunden und API Key vorhanden, OpenAI verwenden
    if (_apiKey.isEmpty) {
      return _getDefaultTips(foodName);
    }

    try {
      final prompt =
          '''
Gib 4 kurze, präzise Lagerungstipps für "$foodName" auf Deutsch.

Format: Nur • + kurzer Stichpunkt (max. 6 Wörter)

Beispiele:
• In feuchtes Tuch wickeln
• Von Wärmequellen fernhalten
• Im Kühlschrank lagern
• Luftdicht verschließen

Antworte NUR mit 4 Bullet Points für "$foodName":
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
          'max_tokens': 150,
        }),
      );

      if (response.statusCode != 200) {
        return _getDefaultTips(foodName);
      }

      final responseBody = json.decode(response.body);
      final content =
          responseBody['choices'][0]['message']['content'] as String;

      // Bereinige die Antwort von eventuellen zusätzlichen Texten
      final cleanedContent = content.trim();

      // Validiere dass es Bullet Points sind
      String finalResult;
      if (cleanedContent.contains('•')) {
        finalResult = cleanedContent;
      } else {
        // Falls keine Bullet Points, füge sie hinzu
        final lines = cleanedContent
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .take(4);
        finalResult = lines.map((line) => '• ${line.trim()}').join('\n');
      }

      // Hole auch die Spoilage-Tipps und speichere beide in der Datenbank
      try {
        final spoilageTips = await getSpoilageIndicators(foodName);
        await _localDataSource.cacheFoodTips(
          foodName,
          finalResult,
          spoilageTips,
        );
      } catch (e) {
        // Fehler beim Cachen ignorieren - gib trotzdem das Ergebnis zurück
      }

      return finalResult;
    } catch (e) {
      return _getDefaultTips(foodName);
    }
  }

  String _getDefaultTips(String foodName) {
    final name = foodName.toLowerCase();

    if (name.contains('apfel') || name.contains('äpfel')) {
      return '• Im Kühlschrank lagern\n• Getrennt von anderen Früchten\n• Druckstellen vermeiden\n• In Plastikbeutel aufbewahren';
    } else if (name.contains('brot')) {
      return '• In Brotkasten aufbewahren\n• Nicht im Kühlschrank\n• In Papiertüte lagern\n• Angeschnittene Seite nach unten';
    } else if (name.contains('milch')) {
      return '• Im Kühlschrank lagern\n• Original-Verpackung nutzen\n• Nicht in Kühlschranktür\n• Schnell verbrauchen';
    } else if (name.contains('banane')) {
      return '• Bei Raumtemperatur lagern\n• Nicht im Kühlschrank\n• Getrennt von anderen Früchten\n• Von Wärmequellen fernhalten';
    } else if (name.contains('tomate')) {
      return '• Bei Raumtemperatur lagern\n• Nicht im Kühlschrank\n• Stielansatz nach unten\n• Getrennt von anderem Gemüse';
    } else if (name.contains('salat') || name.contains('kopfsalat')) {
      return '• Im Kühlschrank lagern\n• In feuchtes Tuch wickeln\n• Nicht vor Lagerung waschen\n• Welke Blätter entfernen';
    } else if (name.contains('kartoffel')) {
      return '• Kühl und dunkel lagern\n• Nicht im Kühlschrank\n• Getrennt von Zwiebeln\n• Grüne Stellen entfernen';
    } else if (name.contains('fleisch') || name.contains('wurst')) {
      return '• Im Kühlschrank lagern\n• Original-Verpackung nutzen\n• Bei 0-4°C aufbewahren\n• Getrennt von anderen Lebensmitteln';
    } else if (name.contains('käse')) {
      return '• Im Kühlschrank lagern\n• In Käsepapier wickeln\n• Nicht in Plastik\n• Hart- und Weichkäse trennen';
    } else {
      return '• Kühl und trocken lagern\n• Original-Verpackung beachten\n• Haltbarkeitsdatum prüfen\n• An Geruch orientieren';
    }
  }

  @override
  Future<String> getSpoilageIndicators(String foodName) async {
    // 1. Zuerst in lokaler Datenbank suchen
    final localTips = await _localDataSource.getFoodTips(foodName);
    if (localTips != null) {
      return localTips['spoilage_indicators']!;
    }

    // 2. Falls nicht gefunden und API Key vorhanden, OpenAI verwenden
    if (_apiKey.isEmpty) {
      return _getDefaultSpoilageIndicators(foodName);
    }

    try {
      final prompt =
          '''
Gib 4 kurze, präzise Hinweise zur Erkennung von verdorbenem "$foodName" auf Deutsch.

Format: Nur • + kurzer Stichpunkt (max. 6 Wörter)
Fokus: Geruch, Aussehen, Konsistenz, Geschmack

Beispiele:
• Säuerlicher oder fauliger Geruch
• Schimmelbildung sichtbar
• Verfärbung der Oberfläche
• Schmierige Konsistenz

Antworte NUR mit 4 Bullet Points für verdorbenes "$foodName":
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
          'max_tokens': 150,
        }),
      );

      if (response.statusCode != 200) {
        return _getDefaultSpoilageIndicators(foodName);
      }

      final responseBody = json.decode(response.body);
      final content =
          responseBody['choices'][0]['message']['content'] as String;

      // Bereinige die Antwort
      final cleanedContent = content.trim();

      String finalResult;
      if (cleanedContent.contains('•')) {
        finalResult = cleanedContent;
      } else {
        final lines = cleanedContent
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .take(4);
        finalResult = lines.map((line) => '• ${line.trim()}').join('\n');
      }

      // Nur Spoilage-Hinweise einzeln cachen, da Storage-Tipps separat gecacht werden
      try {
        final storageTips = _getDefaultTips(
          foodName,
        ); // Verwende Default-Tipps um Loop zu vermeiden
        await _localDataSource.cacheFoodTips(
          foodName,
          storageTips,
          finalResult,
        );
      } catch (e) {
        // Fehler beim Cachen ignorieren - gib trotzdem das Ergebnis zurück
      }

      return finalResult;
    } catch (e) {
      return _getDefaultSpoilageIndicators(foodName);
    }
  }

  String _getDefaultSpoilageIndicators(String foodName) {
    final name = foodName.toLowerCase();

    if (name.contains('apfel') || name.contains('äpfel')) {
      return '• Braune, weiche Stellen\n• Fauliger Geruch\n• Runzelige Haut\n• Schimmelbildung am Stiel';
    } else if (name.contains('brot')) {
      return '• Grüner oder weißer Schimmel\n• Säuerlicher Geruch\n• Harte, trockene Konsistenz\n• Verfärbungen sichtbar';
    } else if (name.contains('milch')) {
      return '• Säuerlicher Geruch\n• Klumpige Konsistenz\n• Gelbliche Verfärbung\n• Säuerlicher Geschmack';
    } else if (name.contains('banane')) {
      return '• Schwarze, matschige Stellen\n• Alkoholischer Geruch\n• Flüssigkeit tritt aus\n• Schimmel am Stielansatz';
    } else if (name.contains('tomate')) {
      return '• Weiche, matschige Stellen\n• Schimmelbildung\n• Säuerlicher Geruch\n• Runzelige Haut';
    } else if (name.contains('salat') || name.contains('kopfsalat')) {
      return '• Braune, schleimige Blätter\n• Fauliger Geruch\n• Welke Konsistenz\n• Dunkle Verfärbungen';
    } else if (name.contains('kartoffel')) {
      return '• Grüne Verfärbung\n• Weiche, faulige Stellen\n• Süßlicher Geruch\n• Austriebe vorhanden';
    } else if (name.contains('fleisch') || name.contains('wurst')) {
      return '• Grau-grüne Verfärbung\n• Säuerlicher Geruch\n• Schmierige Oberfläche\n• Unangenehmer Geschmack';
    } else if (name.contains('käse')) {
      return '• Ungewöhnlicher Schimmel\n• Ammoniakgeruch\n• Schmierige Konsistenz\n• Bitterer Geschmack';
    } else {
      return '• Ungewöhnlicher Geruch\n• Verfärbungen sichtbar\n• Schimmelbildung\n• Veränderte Konsistenz';
    }
  }
}
