// lib/features/student/progress/data/repositories/progress_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/weak_item_pool.dart';
import 'package:my_first_app/features/student/progress/data/datasources/progress_remote_datasource.dart';
import 'package:my_first_app/features/student/progress/domain/entities/progress.dart';
import 'package:my_first_app/features/student/progress/domain/repositories/progress_repository.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressRemoteDataSource _remote;
  ProgressRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, UserProgress>> getProgressStats(String userId) async {
    try {
      return Right(await _remote.getProgressStats(userId));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<WeakItem>>> getWeakItems(String userId) async {
    try {
      return Right(await _remote.getWeakItems(userId));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateMasteryScore({
    required String userId,
    required String contentType,
    required String contentId,
    required double score,
  }) async {
    try {
      await _remote.updateMasteryScore(
        userId: userId,
        contentType: contentType,
        contentId: contentId,
        score: score,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
