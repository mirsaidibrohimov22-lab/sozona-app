// lib/features/student/listening/data/repositories/listening_repository_impl.dart
// So'zona — Listening Repository implementatsiyasi

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/network/network_info.dart';
import 'package:my_first_app/features/student/listening/data/datasources/listening_local_datasource.dart';
import 'package:my_first_app/features/student/listening/data/datasources/listening_remote_datasource.dart';
import 'package:my_first_app/features/student/listening/data/models/listening_model.dart';
import 'package:my_first_app/features/student/listening/domain/entities/listening_exercise.dart';
import 'package:my_first_app/features/student/listening/domain/repositories/listening_repository.dart';

class ListeningRepositoryImpl implements ListeningRepository {
  final ListeningRemoteDataSource remote;
  final ListeningLocalDataSource local;
  final NetworkInfo networkInfo;

  const ListeningRepositoryImpl({
    required this.remote,
    required this.local,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ListeningExercise>>> getListeningExercises({
    String? language,
    String? level,
    String? topic,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final exercises = await remote.getListeningExercises(
          language: language,
          level: level,
          topic: topic,
        );
        return Right(exercises);
      } else {
        final cached = await local.getCachedExercises();
        return Right(cached);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Mashqlar yuklanmadi: $e'));
    }
  }

  @override
  Future<Either<Failure, ListeningExercise>> getListeningDetail(
    String exerciseId,
  ) async {
    try {
      final exercise = await remote.getListeningDetail(exerciseId);
      await local.cacheExercise(exercise);
      return Right(exercise);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Mashq yuklanmadi: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> submitListeningAnswers({
    required String exerciseId,
    required String studentId,
    required Map<String, String> answers,
    required int timeSpent,
  }) async {
    try {
      final result = await remote.submitListeningAnswers(
        exerciseId: exerciseId,
        studentId: studentId,
        answers: answers,
        timeSpent: timeSpent,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Javoblar yuborilmadi: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> cacheExercise(ListeningExercise exercise) async {
    try {
      if (exercise is ListeningModel) {
        await local.cacheExercise(exercise);
      }
      return const Right(true);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Cache xatosi: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ListeningExercise>>> getCachedExercises() async {
    try {
      final cached = await local.getCachedExercises();
      return Right(cached);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Cache xatosi: $e'));
    }
  }
}
