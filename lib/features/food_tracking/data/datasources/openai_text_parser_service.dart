import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/food_model.dart';

class OpenAITextParserService {
  final String _apiKey;
  final Uuid uuid = const Uuid();
  
  OpenAITextParserService() : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  // Whisper AI Transkription für präzise deutsche Spracheingabe
  Future<String> transcribeAudio(File audioFile) async {
    debugPrint('Whisper Transkription gestartet für Datei: ${audioFile.path}');
    
    if (_apiKey.isEmpty) {
      debugPrint('OpenAI API Key nicht gefunden');
      throw Exception('OpenAI API Key nicht konfiguriert');
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
      );
      
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.fields['model'] = 'whisper-1';
      request.fields['language'] = 'de';
      request.fields['response_format'] = 'json';
      
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        audioFile.path,
        filename: 'audio.m4a',
      ));
      
      debugPrint('Sende Audio an Whisper API...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode != 200) {
        debugPrint('Whisper API Fehler: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        throw Exception('Whisper API Fehler: ${response.statusCode}');
      }
      
      final responseData = json.decode(response.body);
      final transcript = responseData['text'] as String;
      
      debugPrint('Whisper Transkription erfolgreich: "$transcript"');
      return transcript;
      
    } catch (e) {
      debugPrint('Fehler bei Whisper Transkription: $e');
      rethrow;
    }
  }

  // Erweiterte Methode: Audio direkt zu Lebensmitteln parsen
  Future<List<FoodModel>> parseAudioToFoods(File audioFile) async {
    try {
      // 1. Audio mit Whisper transkribieren
      final transcript = await transcribeAudio(audioFile);
      
      // 2. Text mit GPT-4o parsen
      return await parseTextToFoodsAsync(transcript);
      
    } catch (e) {
      debugPrint('Fehler beim Audio-Parsing: $e');
      return [];
    }
  }

  Future<List<FoodModel>> parseTextToFoodsAsync(String text) async {
    debugPrint('OpenAI Parser aufgerufen mit Text: "$text"');
    debugPrint('API Key vorhanden: ${_apiKey.isNotEmpty}');
    
    if (_apiKey.isEmpty) {
      debugPrint('OpenAI API Key nicht gefunden - Fehler');
      return [];
    }

    // Vollständig API-basierter Ansatz für Multiplatform-Konsistenz
    debugPrint('Verwende OpenAI für plattform-einheitliches Parsing');
    
    try {
      final now = DateTime.now();
      final prompt = '''
Extrahiere Lebensmittel mit Datumsangaben aus diesem deutschen Text. Achte besonders auf deutsche Datumsformate!

Text: "$text"
Heutiges Datum: ${now.day}.${now.month}.${now.year}

KRITISCH: 
1. Erkenne ALLE Lebensmittel - mit oder ohne Datum (ohne Datum = "days": null)
2. KEINE Kommas oder Wörter hinzufügen - nur exakte Namen aus dem Text
3. Negative Tage für vergangene Daten (z.B. "days": -5 für 5 Tage abgelaufen)

Antworte NUR mit JSON:
{
  "foods": [
    {"name": "<exakter_name>", "days": <tage_oder_null>, "category": "<kategorie_oder_null>"}
  ]
}

DEUTSCHE ZEITANGABEN - erkenne ALLE Varianten:

RELATIVE ZEITANGABEN:
- "heute" = 0 Tage
- "morgen" = 1 Tag  
- "übermorgen" = 2 Tage
- "gestern" = -1 Tag (abgelaufen!)
- "vorgestern" = -2 Tage (abgelaufen!)

WOCHENTAGE:
- "nächsten/kommenden Montag/Dienstag/..." = Tage bis nächster Wochentag
- "diesen Freitag" = Tage bis Freitag dieser Woche
- "übernächsten Samstag" = Tage bis Samstag übernächster Woche

WOCHEN/MONATE:
- "nächste Woche" = 7 Tage
- "übernächste Woche" = 14 Tage  
- "in 2/zwei Wochen" = 14 Tage
- "Ende der Woche" = Tage bis Sonntag
- "Anfang/Mitte/Ende [Monat]" = 1./15./letzter Tag des Monats

DATUMSFORMATE (Tag.Monat oder Tag/Monat oder Tag-Monat):
- "8.3", "08.03", "8/3", "8-3" = 8. März
- "am 8." = 8. des aktuellen Monats (oder nächsten, wenn bereits vorbei)
- "8.3.25", "8.3.2025" = 8. März 2025
- Jahreszahlen: 00-30 = 2000-2030, 31-99 = 1931-1999

MONATSNAMEN (alle Varianten):
- Januar: jan, jän, jänner
- Februar: feb, febr
- März: mär, märz, mrz, mar
- April: apr
- Mai: mai
- Juni: jun
- Juli: jul
- August: aug, augus
- September: sep, sept
- Oktober: okt
- November: nov
- Dezember: dez

WICHTIGE REGELN:
1. Bei "am 8." ohne Monat: Wenn 8. dieses Monats vorbei → nächster Monat
2. Deutsche Datumslogik: Tag.Monat.Jahr (NICHT Monat/Tag!)
3. Sprachvarianten beachten: "zwo" = "zwei", "nen" = "einen"
4. Umgangssprache: "paar Tage" = 3-4 Tage, "einige Tage" = 4-5 Tage

BEISPIELE:
- "Milch morgen" → {"name": "Milch", "days": 1}
- "Käse nächsten Dienstag" → {"name": "Käse", "days": <tage_bis_dienstag>}
- "Brot am 8." → {"name": "Brot", "days": <tage_bis_8_des_monats>}
- "Joghurt 15/3" → {"name": "Joghurt", "days": <tage_bis_15_märz>}
- "Wurst Ende März" → {"name": "Wurst", "days": <tage_bis_31_märz>}
- "Äpfel gestern" → {"name": "Äpfel", "days": -1}
- "Butter und Eier" → {"name": "Butter", "days": null}, {"name": "Eier", "days": null}

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
        debugPrint('OpenAI API Fehler: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        return [];
      }

      final responseBody = json.decode(response.body);
      final content = responseBody['choices'][0]['message']['content'];
      
      // Extrahiere JSON aus der Antwort (falls zusätzlicher Text vorhanden)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        debugPrint('Kein JSON in OpenAI Antwort gefunden');
        return [];
      }
      
      final parsedData = json.decode(jsonMatch.group(0)!);
      debugPrint('OpenAI Response parsed: $parsedData');
      
      final models = _createFoodModels(parsedData);
      debugPrint('Erstellte ${models.length} FoodModels');
      return models;
    } catch (e) {
      debugPrint('OpenAI Parsing Fehler: $e');
      return [];
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
        final days = foodMap['days'] as int?;
        final category = foodMap['category'] as String?;
        
        if (name != null && name.trim().isNotEmpty) {
          final DateTime? expiryDate = days != null ? now.add(Duration(days: days)) : null;
          debugPrint('Creating food: $name, days: $days, expiryDate: $expiryDate');
          
          foods.add(FoodModel(
            id: uuid.v4(),
            name: _capitalizeFirst(name.trim()),
            expiryDate: expiryDate,
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

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}