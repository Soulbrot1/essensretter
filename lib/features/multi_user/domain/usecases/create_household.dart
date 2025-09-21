import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/household.dart';
import '../repositories/household_repository.dart';

class CreateHousehold implements UseCase<Household, NoParams> {
  final HouseholdRepository repository;

  CreateHousehold({required this.repository});

  @override
  Future<Either<Failure, Household>> call(NoParams params) async {
    return await repository.createHousehold();
  }
}
