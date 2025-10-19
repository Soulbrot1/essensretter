import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/share_code_repository.dart';
import '../datasources/share_code_remote_data_source.dart';

class ShareCodeRepositoryImpl implements ShareCodeRepository {
  final ShareCodeRemoteDataSource remoteDataSource;

  ShareCodeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> getShareCode(String retterId) async {
    try {
      final shareCode = await remoteDataSource.getShareCode(retterId);
      return Right(shareCode);
    } catch (e) {
      return Left(ServerFailure('Fehler beim Abrufen des Share-Codes: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getRetterIdByShareCode(
    String shareCode,
  ) async {
    try {
      final retterId = await remoteDataSource.getRetterIdByShareCode(shareCode);
      return Right(retterId);
    } catch (e) {
      return Left(ServerFailure('Fehler beim Auflösen des Share-Codes: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> regenerateShareCode(String retterId) async {
    try {
      final newShareCode = await remoteDataSource.regenerateShareCode(retterId);
      return Right(newShareCode);
    } catch (e) {
      return Left(
        ServerFailure('Fehler beim Regenerieren des Share-Codes: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> createShareCode(String retterId) async {
    try {
      final shareCode = await remoteDataSource.createShareCode(retterId);
      return Right(shareCode);
    } catch (e) {
      return Left(ServerFailure('Fehler beim Erstellen des Share-Codes: $e'));
    }
  }
}
