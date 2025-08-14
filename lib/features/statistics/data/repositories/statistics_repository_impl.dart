import '../../domain/entities/waste_entry.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/statistics_local_data_source.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsLocalDataSource localDataSource;

  StatisticsRepositoryImpl({required this.localDataSource});

  @override
  Future<List<WasteEntry>> getWasteEntries(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await localDataSource.getWasteEntries(startDate, endDate);
  }

  @override
  Future<void> recordWastedFood(
    String foodId,
    String name,
    String? category,
  ) async {
    return await localDataSource.recordWastedFood(foodId, name, category);
  }

  @override
  Future<void> recordConsumedFood(
    String foodId,
    String name,
    String? category,
  ) async {
    return await localDataSource.recordConsumedFood(foodId, name, category);
  }
}
