import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/household.dart';
import '../../domain/repositories/household_repository.dart';
import '../datasources/household_remote_data_source.dart';

class HouseholdRepositoryImpl implements HouseholdRepository {
  final HouseholdRemoteDataSource remoteDataSource;

  HouseholdRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Household>> createHousehold() async {
    try {
      final household = await remoteDataSource.createHousehold();
      return Right(household);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Household?>> getCurrentHousehold() async {
    // TODO: Implement when we have master key storage
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteHousehold(String householdId) async {
    try {
      await remoteDataSource.deleteHousehold(householdId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
