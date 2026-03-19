// lib/features/student/home/data/repositories/home_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/student/home/data/datasources/home_remote_datasource.dart';
import 'package:my_first_app/features/student/home/domain/entities/daily_plan.dart';
import 'package:my_first_app/features/student/home/domain/entities/streak.dart';
import 'package:my_first_app/features/student/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remote;
  HomeRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, DailyPlan>> getDailyPlan(String userId) async {
    try {
      return Right(await _remote.getDailyPlan(userId));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Streak>> getStreak(String userId) async {
    try {
      return Right(await _remote.getStreak(userId));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> completeTask(
    String userId,
    String taskId,
  ) async {
    try {
      await _remote.completeTask(userId, taskId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, String>> joinClass(
    String userId,
    String joinCode,
  ) async {
    try {
      return Right(await _remote.joinClass(userId, joinCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
