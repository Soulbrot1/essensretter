import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/food_repository.dart';
import '../../../statistics/domain/repositories/statistics_repository.dart';

class DeleteFood implements UseCase<void, DeleteFoodParams> {
  final FoodRepository foodRepository;
  final StatisticsRepository statisticsRepository;

  DeleteFood({
    required this.foodRepository,
    required this.statisticsRepository,
  });

  @override
  Future<Either<Failure, void>> call(DeleteFoodParams params) async {
    print('DeleteFood: Starting deletion process for food ID: ${params.id}');
    
    // Erst das Lebensmittel für die Statistik holen
    final foodResult = await foodRepository.getFoodById(params.id);
    
    return foodResult.fold(
      (failure) {
        print('DeleteFood: Failed to get food: ${failure.message}');
        return Left(failure);
      },
      (food) async {
        print('DeleteFood: Found food: ${food.name}, category: ${food.category}');
        
        // In Statistik als weggeworfen eintragen
        try {
          print('DeleteFood: Recording wasted food in statistics...');
          await statisticsRepository.recordWastedFood(
            food.id,
            food.name,
            food.category,
          );
          print('DeleteFood: Successfully recorded in statistics');
        } catch (e) {
          print('DeleteFood: Error recording statistics: $e');
          // Statistik-Fehler ignorieren, Löschung trotzdem durchführen
        }
        
        // Lebensmittel löschen
        print('DeleteFood: Deleting food from main storage...');
        final deleteResult = await foodRepository.deleteFood(params.id);
        print('DeleteFood: Deletion completed');
        return deleteResult;
      },
    );
  }
}

class DeleteFoodParams extends Equatable {
  final String id;

  const DeleteFoodParams({required this.id});

  @override
  List<Object> get props => [id];
}