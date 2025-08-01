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
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        expiryDate TEXT NOT NULL,
        addedDate TEXT NOT NULL,
        category TEXT,
        notes TEXT
      )
    ''');
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