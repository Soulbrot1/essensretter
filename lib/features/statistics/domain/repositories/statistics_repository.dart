import '../entities/waste_entry.dart';

abstract class StatisticsRepository {
  Future<List<WasteEntry>> getWasteEntries(DateTime startDate, DateTime endDate);
  Future<void> recordWastedFood(String foodId, String name, String? category);
}