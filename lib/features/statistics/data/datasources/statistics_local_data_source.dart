import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/waste_entry.dart';

abstract class StatisticsLocalDataSource {
  Future<List<WasteEntry>> getWasteEntries(DateTime startDate, DateTime endDate);
  Future<void> recordWastedFood(String foodId, String name, String? category);
  Future<void> addSampleData();
}

class StatisticsLocalDataSourceImpl implements StatisticsLocalDataSource {
  static const String _tableName = 'waste_entries';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'essensretter.db');
    print('Opening database at: $path');
    
    return await openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        print('Creating database tables...');
        
        // Create foods table
        await db.execute('''
          CREATE TABLE foods(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            expiryDate TEXT,
            addedDate TEXT NOT NULL,
            category TEXT,
            notes TEXT,
            isConsumed INTEGER NOT NULL DEFAULT 0
          )
        ''');
        
        // Create waste_entries table
        await db.execute('''
          CREATE TABLE $_tableName(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT,
            deleted_date INTEGER NOT NULL
          )
        ''');
        print('Database tables created successfully');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('Upgrading database from version $oldVersion to $newVersion');
        
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_tableName(
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              category TEXT,
              deleted_date INTEGER NOT NULL
            )
          ''');
          print('waste_entries table created during upgrade');
        }
        if (oldVersion < 5) {
          // Sicherstellen, dass waste_entries existiert
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_tableName(
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              category TEXT,
              deleted_date INTEGER NOT NULL
            )
          ''');
          print('waste_entries table ensured in version 5');
        }
        if (oldVersion < 6) {
          // Migration von Version 5 zu 6: waste_entries neu erstellen ohne is_wasted
          await db.execute('DROP TABLE IF EXISTS $_tableName');
          await db.execute('''
            CREATE TABLE $_tableName(
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              category TEXT,
              deleted_date INTEGER NOT NULL
            )
          ''');
          print('waste_entries table recreated in version 6');
        }
      },
    );
  }

  @override
  Future<List<WasteEntry>> getWasteEntries(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final results = await db.query(
      _tableName,
      where: 'deleted_date BETWEEN ? AND ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      orderBy: 'deleted_date DESC',
    );

    return results.map((row) => WasteEntry(
      id: row['id'] as String,
      name: row['name'] as String,
      category: row['category'] as String?,
      deletedDate: DateTime.fromMillisecondsSinceEpoch(row['deleted_date'] as int),
    )).toList();
  }

  @override
  Future<void> recordWastedFood(String foodId, String name, String? category) async {
    final db = await database;
    await db.insert(
      _tableName,
      {
        'id': foodId,
        'name': name,
        'category': category,
        'deleted_date': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> addSampleData() async {
    try {
      final db = await database;
      final now = DateTime.now();
      
      print('Adding sample data to waste_entries table...');
      
      final sampleData = [
        {'id': 'sample1', 'name': 'Alte Bananen', 'category': 'Obst', 'deleted_date': now.subtract(const Duration(days: 2)).millisecondsSinceEpoch},
        {'id': 'sample2', 'name': 'Verschimmeltes Brot', 'category': 'Backwaren', 'deleted_date': now.subtract(const Duration(days: 5)).millisecondsSinceEpoch},
        {'id': 'sample3', 'name': 'Welker Salat', 'category': 'Gemüse', 'deleted_date': now.subtract(const Duration(days: 7)).millisecondsSinceEpoch},
        {'id': 'sample4', 'name': 'Abgelaufene Milch', 'category': 'Milchprodukte', 'deleted_date': now.subtract(const Duration(days: 10)).millisecondsSinceEpoch},
        {'id': 'sample5', 'name': 'Matschige Tomaten', 'category': 'Gemüse', 'deleted_date': now.subtract(const Duration(days: 15)).millisecondsSinceEpoch},
        {'id': 'sample6', 'name': 'Alte Karotten', 'category': 'Gemüse', 'deleted_date': now.subtract(const Duration(days: 1)).millisecondsSinceEpoch},
      ];

      for (final data in sampleData) {
        final result = await db.insert(_tableName, data, conflictAlgorithm: ConflictAlgorithm.ignore);
        print('Inserted sample data: ${data['name']}, result: $result');
      }
      
      // Check if data was inserted
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_tableName'));
      print('Total entries in waste_entries table: $count');
      
    } catch (e) {
      print('Error adding sample data: $e');
    }
  }
}