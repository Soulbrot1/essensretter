import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';
import '../datasources/food_local_data_source.dart';
import '../models/food_model.dart';

class FoodRepositoryImpl implements FoodRepository {
  final FoodLocalDataSource localDataSource;

  FoodRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Food>>> getAllFoods() async {
    try {
      final localFoods = await localDataSource.getAllFoods();
      return Right(localFoods);
    } on CacheException {
      return const Left(CacheFailure('Fehler beim Laden der Lebensmittel'));
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
      final result = await localDataSource.addFood(foodModel);
      return Right(result);
    } on CacheException {
      return const Left(
        CacheFailure('Fehler beim Speichern des Lebensmittels'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteFood(String id) async {
    try {
      await localDataSource.deleteFood(id);
      return const Right(null);
    } on CacheException {
      return const Left(CacheFailure('Fehler beim Löschen des Lebensmittels'));
    }
  }

  @override
  Future<Either<Failure, Food>> updateFood(Food food) async {
    try {
      final foodModel = FoodModel.fromEntity(food);
      final result = await localDataSource.updateFood(foodModel);
      return Right(result);
    } on CacheException {
      return const Left(
        CacheFailure('Fehler beim Aktualisieren des Lebensmittels'),
      );
    }
  }
}
