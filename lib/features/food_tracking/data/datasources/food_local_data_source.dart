import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_model.dart';
import '../../../../core/error/exceptions.dart';

abstract class FoodLocalDataSource {
  Future<List<FoodModel>> getAllFoods();
  Future<List<FoodModel>> getFoodsByExpiryDays(int days);
  Future<FoodModel> addFood(FoodModel food);
  Future<void> deleteFood(String id);
  Future<FoodModel> updateFood(FoodModel food);
}

class FoodLocalDataSourceImpl implements FoodLocalDataSource {
  static const String _databaseName = 'essensretter.db';
  static const String _tableName = 'foods';
  static const int _databaseVersion = 6;

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
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        expiryDate TEXT,
        addedDate TEXT NOT NULL,
        category TEXT,
        notes TEXT,
        isConsumed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration von Version 1 zu 2: isConsumed Spalte hinzufügen
      await db.execute('ALTER TABLE $_tableName ADD COLUMN isConsumed INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      // Migration von Version 2 zu 3: expiryDate nullable machen
      // SQLite unterstützt ALTER COLUMN nicht, daher müssen wir die Tabelle neu erstellen
      await db.execute('ALTER TABLE $_tableName RENAME TO ${_tableName}_old');
      await db.execute('''
        CREATE TABLE $_tableName(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          expiryDate TEXT,
          addedDate TEXT NOT NULL,
          category TEXT,
          notes TEXT,
          isConsumed INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('INSERT INTO $_tableName SELECT * FROM ${_tableName}_old');
      await db.execute('DROP TABLE ${_tableName}_old');
    }
    if (oldVersion < 4) {
      // Migration von Version 3 zu 4: waste_entries Tabelle hinzufügen
      await db.execute('''
        CREATE TABLE IF NOT EXISTS waste_entries(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT,
          deleted_date INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      // Migration von Version 4 zu 5: Sicherstellen, dass waste_entries existiert
      await db.execute('''
        CREATE TABLE IF NOT EXISTS waste_entries(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT,
          deleted_date INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      // Migration von Version 5 zu 6: waste_entries Tabelle neu erstellen ohne is_wasted
      await db.execute('DROP TABLE IF EXISTS waste_entries');
      await db.execute('''
        CREATE TABLE waste_entries(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT,
          deleted_date INTEGER NOT NULL
        )
      ''');
    }
  }

  @override
  Future<List<FoodModel>> getAllFoods() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'expiryDate ASC',
      );
      return List.generate(maps.length, (i) => FoodModel.fromJson(maps[i]));
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<List<FoodModel>> getFoodsByExpiryDays(int days) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final targetDate = now.add(Duration(days: days));
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'date(expiryDate) <= date(?)',
        whereArgs: [targetDate.toIso8601String()],
        orderBy: 'expiryDate ASC',
      );
      
      return List.generate(maps.length, (i) => FoodModel.fromJson(maps[i]));
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<FoodModel> addFood(FoodModel food) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        food.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return food;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> deleteFood(String id) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<FoodModel> updateFood(FoodModel food) async {
    try {
      final db = await database;
      await db.update(
        _tableName,
        food.toJson(),
        where: 'id = ?',
        whereArgs: [food.id],
      );
      return food;
    } catch (e) {
      throw CacheException();
    }
  }
}