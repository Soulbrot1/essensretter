import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/food.dart';
import '../repositories/food_repository.dart';

class GetExpiringFoods implements UseCase<List<Food>, GetExpiringFoodsParams> {
  final FoodRepository repository;

  GetExpiringFoods(this.repository);

  @override
  Future<Either<Failure, List<Food>>> call(
    GetExpiringFoodsParams params,
  ) async {
    final result = await repository.getAllFoods();

    return result.map((foods) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfPeriod = startOfToday.add(
        Duration(days: params.daysAhead + 1),
      );

      return foods.where((food) {
        if (food.expiryDate == null) return false;

        final expiryStart = DateTime(
          food.expiryDate!.year,
          food.expiryDate!.month,
          food.expiryDate!.day,
        );

        // Inklusive abgelaufene Lebensmittel (vor heute) und die nächsten X Tage
        return expiryStart.isBefore(endOfPeriod);
      }).toList()..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    });
  }
}

class GetExpiringFoodsParams extends Equatable {
  final int daysAhead;

  const GetExpiringFoodsParams({required this.daysAhead});

  @override
  List<Object> get props => [daysAhead];
}
