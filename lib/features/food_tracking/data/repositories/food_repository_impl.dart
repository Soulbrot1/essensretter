import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';
import '../datasources/food_local_data_source.dart';
import '../datasources/supabase_data_source.dart';
import '../models/food_model.dart';

class FoodRepositoryImpl implements FoodRepository {
  final FoodLocalDataSource localDataSource;
  final SupabaseDataSource supabaseDataSource;

  FoodRepositoryImpl({
    required this.localDataSource,
    required this.supabaseDataSource,
  });

  @override
  Future<Either<Failure, List<Food>>> getAllFoods() async {
    try {
      // Versuche erst Supabase, dann lokale Datenbank als Fallback
      try {
        final supabaseFoods = await supabaseDataSource.getAllFoods();
        return Right(supabaseFoods);
      } catch (e) {
        // Fallback zu lokaler Datenbank wenn Supabase nicht verfügbar
        final localFoods = await localDataSource.getAllFoods();
        return Right(localFoods);
      }
    } on CacheException {
      return const Left(CacheFailure('Fehler beim Laden der Lebensmittel'));
    } catch (e) {
      return Left(CacheFailure('Netzwerkfehler: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Food>>> getFoodsByExpiryDays(int days) async {
    try {
      final localFoods = await localDataSource.getFoodsByExpiryDays(days);
      return Right(localFoods);
    } on CacheException {
      return const Left(CacheFailure('Fehler beim Filtern der Lebensmittel'));
    }
  }

  @override
  Future<Either<Failure, Food>> getFoodById(String id) async {
    try {
      final foods = await localDataSource.getAllFoods();
      final food = foods.firstWhere((f) => f.id == id);
      return Right(food);
    } on CacheException {
      return const Left(CacheFailure('Fehler beim Laden des Lebensmittels'));
    } catch (e) {
      return const Left(CacheFailure('Lebensmittel nicht gefunden'));
    }
  }

  @override
  Future<Either<Failure, Food>> addFood(Food food) async {
    try {
      final foodModel = FoodModel.fromEntity(food);

      // Versuche zuerst in Supabase zu speichern
      try {
        final result = await supabaseDataSource.addFood(foodModel);

        // Speichere auch lokal als Cache/Backup
        try {
          await localDataSource.addFood(foodModel);
        } catch (e) {
          // Lokales Speichern ist optional - ignoriere Fehler
        }

        return Right(result);
      } catch (e) {
        // Fallback: Nur lokal speichern wenn Supabase fehlschlägt
        final result = await localDataSource.addFood(foodModel);
        return Right(result);
      }
    } on CacheException {
      return const Left(
        CacheFailure('Fehler beim Speichern des Lebensmittels'),
      );
    } catch (e) {
      return Left(CacheFailure('Netzwerkfehler: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFood(String id) async {
    try {
      // Lösche aus Supabase und lokal
      try {
        await supabaseDataSource.deleteFood(id);
      } catch (e) {
        // Wenn Supabase fehlschlägt, trotzdem lokal löschen
      }

      await localDataSource.deleteFood(id);
      return const Right(null);
    } on CacheException {
      return const Left(CacheFailure('Fehler beim Löschen des Lebensmittels'));
    } catch (e) {
      return Left(CacheFailure('Netzwerkfehler: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Food>> updateFood(Food food) async {
    try {
      final foodModel = FoodModel.fromEntity(food);

      // Aktualisiere in Supabase und lokal
      try {
        final result = await supabaseDataSource.updateFood(foodModel);

        // Aktualisiere auch lokal
        try {
          await localDataSource.updateFood(foodModel);
        } catch (e) {
          // Lokales Update ist optional
        }

        return Right(result);
      } catch (e) {
        // Fallback: Nur lokal aktualisieren
        final result = await localDataSource.updateFood(foodModel);
        return Right(result);
      }
    } on CacheException {
      return const Left(
        CacheFailure('Fehler beim Aktualisieren des Lebensmittels'),
      );
    } catch (e) {
      return Left(CacheFailure('Netzwerkfehler: ${e.toString()}'));
    }
  }
}
