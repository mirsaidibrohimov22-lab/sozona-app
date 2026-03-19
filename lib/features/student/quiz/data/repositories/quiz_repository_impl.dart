// lib/features/student/quiz/data/repositories/quiz_repository_impl.dart
// So'zona — Quiz Repository implementatsiya
// ✅ v3.0: deleteQuiz() qo'shildi
// ✅ v3.0: createStudentQuiz — grammar, questionCount parametrlari qo'shildi

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/network/network_info.dart';
import 'package:my_first_app/features/student/quiz/data/datasources/quiz_local_datasource.dart';
import 'package:my_first_app/features/student/quiz/data/datasources/quiz_remote_datasource.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz_attempt.dart';
import 'package:my_first_app/features/student/quiz/domain/repositories/quiz_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuizRemoteDataSource _remote;
  final QuizLocalDataSource _local;
  final NetworkInfo _net;

  QuizRepositoryImpl({
    required QuizRemoteDataSource remote,
    required QuizLocalDataSource local,
    required NetworkInfo net,
  })  : _remote = remote,
        _local = local,
        _net = net;

  @override
  Future<Either<Failure, List<Quiz>>> getQuizzes({
    required String userId,
    required String language,
    required String level,
    String? classId,
  }) async {
    if (await _net.isConnected) {
      try {
        final quizzes = await _remote.getQuizzes(
          userId: userId,
          language: language,
          level: level,
          classId: classId,
        );
        await _local.cacheQuizIds(userId, quizzes.map((q) => q.id).toList());
        return Right(quizzes);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, Quiz>> getQuizDetail(String quizId) async {
    try {
      final quiz = await _remote.getQuizDetail(quizId);
      return Right(quiz);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Quiz>> getAiRecommendedQuiz({
    required String userId,
    required String language,
    required String level,
  }) async {
    try {
      final quiz = await _remote.getAiRecommendedQuiz(
        userId: userId,
        language: language,
        level: level,
      );
      return Right(quiz);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // ✅ v3.0: grammar va questionCount qo'shildi
  @override
  Future<Either<Failure, Quiz>> createStudentQuiz({
    required String userId,
    required String language,
    required String level,
    required String topic,
    String grammar = '',
    int questionCount = 10,
  }) async {
    try {
      final quiz = await _remote.createStudentQuiz(
        userId: userId,
        language: language,
        level: level,
        topic: topic,
        grammar: grammar,
        questionCount: questionCount,
      );
      return Right(quiz);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // ✅ v3.0: Quiz o'chirish
  @override
  Future<Either<Failure, void>> deleteQuiz(String quizId) async {
    try {
      await _remote.deleteQuiz(quizId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, QuizAttempt>> submitQuiz({
    required String userId,
    required String quizId,
    required String quizTitle,
    required String? classId,
    required List<QuizAnswer> answers,
    required int timeSpentSeconds,
    required int maxScore,
  }) async {
    try {
      final attempt = await _remote.submitQuiz(
        userId: userId,
        quizId: quizId,
        quizTitle: quizTitle,
        classId: classId,
        answers: answers,
        timeSpentSeconds: timeSpentSeconds,
        maxScore: maxScore,
      );
      return Right(attempt);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<QuizAttempt>>> getAttemptHistory(
    String userId,
  ) async {
    try {
      final history = await _remote.getAttemptHistory(userId);
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> cacheQuizzes(List<Quiz> quizzes) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Quiz>>> getCachedQuizzes(String userId) async {
    return const Right([]);
  }
}
