import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz_attempt.dart';
import 'package:my_first_app/features/student/quiz/domain/repositories/quiz_repository.dart';

class SubmitAnswer implements UseCase<QuizAttempt, SubmitAnswerParams> {
  final QuizRepository repository;
  SubmitAnswer(this.repository);

  @override
  Future<Either<Failure, QuizAttempt>> call(SubmitAnswerParams params) async {
    return await repository.submitQuiz(
      userId: params.userId,
      quizId: params.quizId,
      quizTitle: params.quizTitle,
      classId: params.classId,
      answers: params.answers,
      timeSpentSeconds: params.timeSpentSeconds,
      maxScore: params.maxScore,
    );
  }
}

class SubmitAnswerParams extends Equatable {
  final String userId;
  final String quizId;
  final String quizTitle;
  final String? classId;
  final List<QuizAnswer> answers;
  final int timeSpentSeconds;
  final int maxScore;

  const SubmitAnswerParams({
    required this.userId,
    required this.quizId,
    required this.quizTitle,
    this.classId,
    required this.answers,
    required this.timeSpentSeconds,
    required this.maxScore,
  });

  @override
  List<Object?> get props => [userId, quizId];
}
