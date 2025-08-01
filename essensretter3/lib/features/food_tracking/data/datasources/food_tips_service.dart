import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

abstract class FoodTipsService {
  Future<String> getFoodStorageTips(String foodName);
}

class OpenAIFoodTipsService implements FoodTipsService {
  final String _apiKey;
  
  OpenAIFoodTipsService() : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  @override
  Future<String> getFoodStorageTips(String foodName) async {
    if (_apiKey.isEmpty) {
      debugPrint('OpenAI API Key nicht gefunden, verwende Standard-Tipps');
      return _getDefaultTips(foodName);
    }

    try {
      final prompt = '''
Du bist ein Experte für Lebensmittellagerung. Gib spezifische, praktische Tipps zur optimalen Lagerung von "$foodName" auf Deutsch.

Antworte NUR mit praktischen Tipps im folgenden Format (ohne zusätzliche Erklärungen):
• [Tipp 1]
• [Tipp 2] 
• [Tipp 3]
• [Tipp 4]

Die Tipps sollen spezifisch für "$foodName" sein und folgende Aspekte abdecken:
- Optimale Lagertemperatur und -ort
- Verpackung/Behältnis
- Besondere Hinweise für längere Haltbarkeit
- Was zu vermeiden ist

Beispiel für Äpfel:
• Im Kühlschrank im Gemüsefach aufbewahren
• Getrennt von anderen Früchten lagern
• Druckstellen sofort entfernen
• Nicht bei Raumtemperatur lagern

Gib maximal 4 präzise, umsetzbare Tipps.
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
          'max_tokens': 300,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('OpenAI API Fehler: ${response.statusCode} - ${response.body}');
        return _getDefaultTips(foodName);
      }

      final responseBody = json.decode(response.body);
      final content = responseBody['choices'][0]['message']['content'] as String;
      
      // Bereinige die Antwort von eventuellen zusätzlichen Texten
      final cleanedContent = content.trim();
      
      // Validiere dass es Bullet Points sind
      if (cleanedContent.contains('•')) {
        return cleanedContent;
      } else {
        // Falls keine Bullet Points, füge sie hinzu
        final lines = cleanedContent.split('\n')
            .where((line) => line.trim().isNotEmpty)
            .take(4);
        return lines.map((line) => '• ${line.trim()}').join('\n');
      }
      
    } catch (e) {
      debugPrint('Fehler beim Abrufen der KI-Tipps: $e');
      return _getDefaultTips(foodName);
    }
  }

  String _getDefaultTips(String foodName) {
    final name = foodName.toLowerCase();
    
    if (name.contains('apfel') || name.contains('äpfel')) {
      return '• Im Kühlschrank aufbewahren\n• Getrennt von anderen Früchten lagern\n• Ethylen-Gas lässt andere Früchte schneller reifen\n• Druckstellen vermeiden';
    } else if (name.contains('brot')) {
      return '• Bei Raumtemperatur in Brotkasten aufbewahren\n• Nicht im Kühlschrank lagern\n• In Papiertüte oder Brotbeutel\n• Angeschnittene Seite nach unten legen';
    } else if (name.contains('milch')) {
      return '• Immer im Kühlschrank aufbewahren (4°C)\n• Original-Verpackung verwenden\n• Nicht in der Kühlschranktür lagern\n• Nach dem Öffnen schnell verbrauchen';
    } else if (name.contains('banane')) {
      return '• Bei Raumtemperatur lagern\n• Nicht im Kühlschrank aufbewahren\n• Getrennt von anderen Früchten\n• Grüne Bananen reifen bei Wärme schneller';
    } else if (name.contains('tomate')) {
      return '• Bei Raumtemperatur lagern\n• Nicht im Kühlschrank aufbewahren\n• Stielansatz nach unten\n• Getrennt von anderen Gemüsesorten';
    } else if (name.contains('salat') || name.contains('kopfsalat')) {
      return '• Im Kühlschrank im Gemüsefach\n• In perforierter Plastiktüte\n• Nicht waschen vor der Lagerung\n• Welke Blätter entfernen';
    } else if (name.contains('kartoffel')) {
      return '• Kühl, dunkel und trocken lagern\n• Nicht im Kühlschrank\n• Getrennt von Zwiebeln\n• Grüne Stellen entfernen';
    } else if (name.contains('fleisch') || name.contains('wurst')) {
      return '• Im kältesten Teil des Kühlschranks\n• Original-Verpackung verwenden\n• Bei 0-4°C lagern\n• Getrennt von anderen Lebensmitteln';
    } else if (name.contains('käse')) {
      return '• Im Kühlschrank aufbewahren\n• In Käsepapier oder Pergament\n• Nicht in Plastik einwickeln\n• Hart- und Weichkäse getrennt lagern';
    } else {
      return '• An einem kühlen, trockenen Ort lagern\n• Original-Verpackung beachten\n• Mindesthaltbarkeitsdatum prüfen\n• Bei Zweifeln an Geruch und Aussehen orientieren';
    }
  }
}