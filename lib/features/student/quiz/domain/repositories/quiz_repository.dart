// lib/features/student/quiz/domain/repositories/quiz_repository.dart
// So'zona — Quiz repository interfeysi
// ✅ v3.0: deleteQuiz() qo'shildi
// ✅ v3.0: createStudentQuiz — grammar, questionCount parametrlari qo'shildi

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz_attempt.dart';

abstract class QuizRepository {
  Future<Either<Failure, List<Quiz>>> getQuizzes({
    required String userId,
    required String language,
    required String level,
    String? classId,
  });

  Future<Either<Failure, Quiz>> getQuizDetail(String quizId);

  Future<Either<Failure, Quiz>> getAiRecommendedQuiz({
    required String userId,
    required String language,
    required String level,
  });

  // ✅ v3.0: grammar va questionCount qo'shildi
  Future<Either<Failure, Quiz>> createStudentQuiz({
    required String userId,
    required String language,
    required String level,
    required String topic,
    String grammar,
    int questionCount,
  });

  // ✅ v3.0: Quiz o'chirish
  Future<Either<Failure, void>> deleteQuiz(String quizId);

  Future<Either<Failure, QuizAttempt>> submitQuiz({
    required String userId,
    required String quizId,
    required String quizTitle,
    required String? classId,
    required List<QuizAnswer> answers,
    required int timeSpentSeconds,
    required int maxScore,
  });

  Future<Either<Failure, List<QuizAttempt>>> getAttemptHistory(String userId);
  Future<Either<Failure, void>> cacheQuizzes(List<Quiz> quizzes);
  Future<Either<Failure, List<Quiz>>> getCachedQuizzes(String userId);
}
