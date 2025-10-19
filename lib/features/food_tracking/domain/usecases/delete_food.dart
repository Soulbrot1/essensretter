import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/food_repository.dart';
import '../../../statistics/domain/repositories/statistics_repository.dart';
import '../../../recipes/domain/usecases/update_recipes_after_food_deletion.dart';
import '../../../sharing/presentation/services/shared_foods_cleanup_service.dart';

class DeleteFood implements UseCase<void, DeleteFoodParams> {
  final FoodRepository foodRepository;
  final StatisticsRepository statisticsRepository;
  final UpdateRecipesAfterFoodDeletion updateRecipesAfterFoodDeletion;
  final SharedFoodsCleanupService? sharedFoodsCleanupService;

  DeleteFood({
    required this.foodRepository,
    required this.statisticsRepository,
    required this.updateRecipesAfterFoodDeletion,
    this.sharedFoodsCleanupService,
  });

  @override
  Future<Either<Failure, void>> call(DeleteFoodParams params) async {
    // Erst das Lebensmittel für die Statistik holen
    final foodResult = await foodRepository.getFoodById(params.id);

    return foodResult.fold(
      (failure) {
        return Left(failure);
      },
      (food) async {
        // In Statistik als weggeworfen eintragen
        try {
          await statisticsRepository.recordWastedFood(
            food.id,
            food.name,
            food.category,
          );
        } catch (e) {
          // Statistik-Fehler ignorieren, Löschung trotzdem durchführen
        }

        // Update recipes to move this food from vorhanden to ueberpruefen
        try {
          await updateRecipesAfterFoodDeletion(
            UpdateRecipesParams(foodName: food.name),
          );
        } catch (e) {
          // Recipe update error ignorieren, Löschung trotzdem durchführen
        }

        // Lebensmittel löschen
        final deleteResult = await foodRepository.deleteFood(params.id);

        // Cleanup shared_foods in Supabase (falls vorhanden)
        deleteResult.fold(
          (failure) {}, // Bei Fehler nichts tun
          (_) async {
            try {
              await sharedFoodsCleanupService?.cleanupSingleFood(params.id);
            } catch (e) {
              // Cleanup-Fehler ignorieren - Lebensmittel ist bereits gelöscht
            }
          },
        );

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
