import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/household.dart';

abstract class HouseholdRepository {
  Future<Either<Failure, Household>> createHousehold();
  Future<Either<Failure, Household?>> getCurrentHousehold();
  Future<Either<Failure, void>> deleteHousehold(String householdId);
}
