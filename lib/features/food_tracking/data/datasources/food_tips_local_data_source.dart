import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

abstract class FoodTipsLocalDataSource {
  Future<Map<String, String>?> getFoodTips(String foodName);
  Future<void> cacheFoodTips(
    String foodName,
    String storageTips,
    String spoilageTips,
  );
}

class FoodTipsLocalDataSourceImpl implements FoodTipsLocalDataSource {
  static const String _databaseName = 'food_tips.db';
  static const String _tableName = 'food_tips';
  static const int _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_name TEXT NOT NULL UNIQUE,
        storage_tips TEXT NOT NULL,
        spoilage_indicators TEXT NOT NULL,
        category TEXT,
        created_at TEXT NOT NULL,
        is_predefined INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Vordefinierte Lebensmittel einfügen
    await _insertPredefinedFoods(db);
  }

  Future<void> _insertPredefinedFoods(Database db) async {
    final now = DateTime.now().toIso8601String();

    final predefinedFoods = [
      // Obst
      {
        'food_name': 'Apfel',
        'category': 'Obst',
        'storage_tips':
            '• Im Kühlschrank lagern\n• Getrennt von anderen Früchten\n• In perforiertem Beutel\n• Druckstellen vermeiden',
        'spoilage_indicators':
            '• Braune, weiche Stellen\n• Fauliger Geruch\n• Runzelige Haut\n• Schimmelbildung am Stiel',
      },
      {
        'food_name': 'Banane',
        'category': 'Obst',
        'storage_tips':
            '• Bei Raumtemperatur lagern\n• Nicht im Kühlschrank\n• Getrennt von anderen Früchten\n• Von Wärmequellen fernhalten',
        'spoilage_indicators':
            '• Schwarze, matschige Stellen\n• Alkoholischer Geruch\n• Flüssigkeit tritt aus\n• Schimmel am Stielansatz',
      },
      {
        'food_name': 'Orange',
        'category': 'Obst',
        'storage_tips':
            '• Bei Raumtemperatur lagern\n• Luftig aufbewahren\n• Nicht in Plastikbeuteln\n• Von anderen Früchten trennen',
        'spoilage_indicators':
            '• Weiche, eingedrückte Stellen\n• Schimmelbildung sichtbar\n• Säuerlicher Geruch\n• Verfärbung der Schale',
      },
      {
        'food_name': 'Erdbeeren',
        'category': 'Obst',
        'storage_tips':
            '• Im Kühlschrank lagern\n• Nicht waschen vor Lagerung\n• In original Verpackung\n• Schnell verbrauchen',
        'spoilage_indicators':
            '• Graue Schimmelflecken\n• Matschige Konsistenz\n• Säuerlicher Geruch\n• Dunkle Verfärbungen',
      },
      {
        'food_name': 'Trauben',
        'category': 'Obst',
        'storage_tips':
            '• Im Kühlschrank lagern\n• In perforiertem Beutel\n• Nicht vom Stiel entfernen\n• Vor Verzehr waschen',
        'spoilage_indicators':
            '• Runzelige, schrumplige Beeren\n• Schimmelbildung am Stiel\n• Säuerlicher Geruch\n• Braune Verfärbungen',
      },

      // Gemüse
      {
        'food_name': 'Tomaten',
        'category': 'Gemüse',
        'storage_tips':
            '• Bei Raumtemperatur lagern\n• Nicht im Kühlschrank\n• Stielansatz nach unten\n• Getrennt von anderem Gemüse',
        'spoilage_indicators':
            '• Weiche, matschige Stellen\n• Schimmelbildung\n• Säuerlicher Geruch\n• Runzelige Haut',
      },
      {
        'food_name': 'Gurken',
        'category': 'Gemüse',
        'storage_tips':
            '• Im Kühlschrank lagern\n• In Gemüsefach aufbewahren\n• Nicht in Plastik einwickeln\n• Von Tomaten fernhalten',
        'spoilage_indicators':
            '• Gelbe Verfärbungen\n• Weiche, matschige Stellen\n• Schleimige Oberfläche\n• Säuerlicher Geruch',
      },
      {
        'food_name': 'Karotten',
        'category': 'Gemüse',
        'storage_tips':
            '• Im Kühlschrank lagern\n• Grün entfernen\n• In feuchtem Tuch wickeln\n• Getrennt von Äpfeln',
        'spoilage_indicators':
            '• Weiche, biegsame Konsistenz\n• Weiße Flecken auf Oberfläche\n• Schimmelbildung\n• Süßlicher Geruch',
      },
      {
        'food_name': 'Salat',
        'category': 'Gemüse',
        'storage_tips':
            '• Im Kühlschrank lagern\n• In feuchtes Tuch wickeln\n• Nicht vor Lagerung waschen\n• Welke Blätter entfernen',
        'spoilage_indicators':
            '• Braune, schleimige Blätter\n• Fauliger Geruch\n• Welke Konsistenz\n• Dunkle Verfärbungen',
      },
      {
        'food_name': 'Zwiebeln',
        'category': 'Gemüse',
        'storage_tips':
            '• Kühl und trocken lagern\n• Luftig aufbewahren\n• Nicht im Kühlschrank\n• Getrennt von Kartoffeln',
        'spoilage_indicators':
            '• Weiche, matschige Stellen\n• Grüne Triebe\n• Schimmelbildung\n• Fauliger Geruch',
      },
      {
        'food_name': 'Paprika',
        'category': 'Gemüse',
        'storage_tips':
            '• Im Kühlschrank lagern\n• In Gemüsefach aufbewahren\n• Trocken halten\n• Nicht waschen vor Lagerung',
        'spoilage_indicators':
            '• Weiche, eingedrückte Stellen\n• Schimmelbildung\n• Runzelige Haut\n• Dunkle Verfärbungen',
      },

      // Milchprodukte
      {
        'food_name': 'Milch',
        'category': 'Milchprodukte',
        'storage_tips':
            '• Im Kühlschrank lagern\n• Original-Verpackung nutzen\n• Nicht in Kühlschranktür\n• Schnell verbrauchen',
        'spoilage_indicators':
            '• Säuerlicher Geruch\n• Klumpige Konsistenz\n• Gelbliche Verfärbung\n• Säuerlicher Geschmack',
      },
      {
        'food_name': 'Joghurt',
        'category': 'Milchprodukte',
        'storage_tips':
            '• Im Kühlschrank lagern\n• Original-Verpackung nutzen\n• Bei 4°C aufbewahren\n• Deckel geschlossen halten',
        'spoilage_indicators':
            '• Schimmelbildung an Oberfläche\n• Säuerlicher Geruch\n• Wässrige Konsistenz\n• Gelbliche Verfärbung',
      },
      {
        'food_name': 'Käse',
        'category': 'Milchprodukte',
        'storage_tips':
            '• Im Kühlschrank lagern\n• In Käsepapier wickeln\n• Nicht in Plastik\n• Hart- und Weichkäse trennen',
        'spoilage_indicators':
            '• Ungewöhnlicher Schimmel\n• Ammoniakgeruch\n• Schmierige Konsistenz\n• Bitterer Geschmack',
      },
      {
        'food_name': 'Butter',
        'category': 'Milchprodukte',
        'storage_tips':
            '• Im Kühlschrank lagern\n• Original-Verpackung nutzen\n• Vor Licht schützen\n• Butterdose verwenden',
        'spoilage_indicators':
            '• Ranziger Geruch\n• Gelbliche Verfärbung\n• Schimmelbildung\n• Bitterer Geschmack',
      },

      // Fleisch & Fisch
      {
        'food_name': 'Hähnchen',
        'category': 'Fleisch',
        'storage_tips':
            '• Im Kühlschrank lagern\n• Bei 0-4°C aufbewahren\n• Original-Verpackung nutzen\n• Getrennt von anderen Lebensmitteln',
        'spoilage_indicators':
            '• Grau-grüne Verfärbung\n• Säuerlicher Geruch\n• Schmierige Oberfläche\n• Unangenehmer Geschmack',
      },
      {
        'food_name': 'Rind',
        'category': 'Fleisch',
        'storage_tips':
            '• Im Kühlschrank lagern\n• Kälteste Stelle wählen\n• Vakuumverpackung nutzen\n• Nicht länger als 3-4 Tage',
        'spoilage_indicators':
            '• Braun-graue Verfärbung\n• Säuerlich-süßlicher Geruch\n• Schleimige Oberfläche\n• Metallischer Geschmack',
      },

      // Brot & Getreide
      {
        'food_name': 'Brot',
        'category': 'Backwaren',
        'storage_tips':
            '• In Brotkasten aufbewahren\n• Nicht im Kühlschrank\n• In Papiertüte lagern\n• Angeschnittene Seite nach unten',
        'spoilage_indicators':
            '• Grüner oder weißer Schimmel\n• Säuerlicher Geruch\n• Harte, trockene Konsistenz\n• Verfärbungen sichtbar',
      },
      {
        'food_name': 'Nudeln',
        'category': 'Getreide',
        'storage_tips':
            '• Trocken und kühl lagern\n• In luftdichtem Behälter\n• Vor Insekten schützen\n• Original-Verpackung nutzen',
        'spoilage_indicators':
            '• Insektenbefall sichtbar\n• Muffiger Geruch\n• Verfärbungen\n• Schimmelbildung',
      },
      {
        'food_name': 'Reis',
        'category': 'Getreide',
        'storage_tips':
            '• Trocken und kühl lagern\n• In luftdichtem Behälter\n• Vor Feuchtigkeit schützen\n• Regelmäßig kontrollieren',
        'spoilage_indicators':
            '• Insektenbefall\n• Muffiger Geruch\n• Verfärbungen\n• Schimmelbildung',
      },

      // Kartoffeln & Knollen
      {
        'food_name': 'Kartoffeln',
        'category': 'Gemüse',
        'storage_tips':
            '• Kühl und dunkel lagern\n• Nicht im Kühlschrank\n• Getrennt von Zwiebeln\n• Grüne Stellen entfernen',
        'spoilage_indicators':
            '• Grüne Verfärbung\n• Weiche, faulige Stellen\n• Süßlicher Geruch\n• Austriebe vorhanden',
      },

      // Eier
      {
        'food_name': 'Eier',
        'category': 'Eier',
        'storage_tips':
            '• Im Kühlschrank lagern\n• In original Verpackung\n• Spitze Seite nach unten\n• Nicht waschen vor Lagerung',
        'spoilage_indicators':
            '• Schwefelgeruch beim Aufschlagen\n• Wässriges Eiweiß\n• Verfärbtes Eigelb\n• Schwimmt im Wasser',
      },

      // Getränke
      {
        'food_name': 'Saft',
        'category': 'Getränke',
        'storage_tips':
            '• Im Kühlschrank lagern\n• Nach Öffnen schnell verbrauchen\n• Original-Verpackung nutzen\n• Verschluss fest schließen',
        'spoilage_indicators':
            '• Säuerlicher Geruch\n• Schaumbildung\n• Verfärbung\n• Alkoholgeschmack',
      },

      // Gewürze & Basics
      {
        'food_name': 'Mehl',
        'category': 'Basics',
        'storage_tips':
            '• Trocken und kühl lagern\n• In luftdichtem Behälter\n• Vor Insekten schützen\n• Regelmäßig kontrollieren',
        'spoilage_indicators':
            '• Insektenbefall\n• Muffiger Geruch\n• Klumpenbildung\n• Verfärbungen',
      },
      {
        'food_name': 'Zucker',
        'category': 'Basics',
        'storage_tips':
            '• Trocken lagern\n• In luftdichtem Behälter\n• Vor Feuchtigkeit schützen\n• Bei Raumtemperatur',
        'spoilage_indicators':
            '• Klumpenbildung\n• Verfärbungen\n• Fremdgeruch\n• Insektenbefall',
      },
      {
        'food_name': 'Öl',
        'category': 'Basics',
        'storage_tips':
            '• Kühl und dunkel lagern\n• Original-Flasche nutzen\n• Vor Licht schützen\n• Verschluss fest schließen',
        'spoilage_indicators':
            '• Ranziger Geruch\n• Trübe Verfärbung\n• Bitterer Geschmack\n• Schaumbildung',
      },
    ];

    for (final food in predefinedFoods) {
      final Map<String, dynamic> foodData = Map<String, dynamic>.from(food);
      foodData['created_at'] = now;
      foodData['is_predefined'] = 1;

      await db.insert(_tableName, foodData);
    }
  }

  @override
  Future<Map<String, String>?> getFoodTips(String foodName) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableName,
        where: 'LOWER(food_name) = LOWER(?)',
        whereArgs: [foodName.trim()],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'storage_tips': row['storage_tips'] as String,
          'spoilage_indicators': row['spoilage_indicators'] as String,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheFoodTips(
    String foodName,
    String storageTips,
    String spoilageTips,
  ) async {
    try {
      final db = await database;
      await db.insert(_tableName, {
        'food_name': foodName.trim(),
        'storage_tips': storageTips,
        'spoilage_indicators': spoilageTips,
        'created_at': DateTime.now().toIso8601String(),
        'is_predefined': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Cache-Fehler ignorieren
    }
  }
}
