import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz_attempt.dart';
import 'package:my_first_app/features/student/quiz/domain/repositories/quiz_repository.dart';

class CompleteQuiz implements UseCase<QuizAttempt, CompleteQuizParams> {
  final QuizRepository repository;
  CompleteQuiz(this.repository);

  @override
  Future<Either<Failure, QuizAttempt>> call(CompleteQuizParams params) async {
    return await repository.submitQuiz(
      userId: params.studentId,
      quizId: params.quizId,
      quizTitle: params.quizTitle,
      classId: params.classId,
      answers: params.answers,
      timeSpentSeconds: params.timeSpent,
      maxScore: params.maxScore,
    );
  }
}

class CompleteQuizParams extends Equatable {
  final String quizId;
  final String quizTitle;
  final String studentId;
  final String? classId;
  final List<QuizAnswer> answers;
  final int timeSpent;
  final int maxScore;

  const CompleteQuizParams({
    required this.quizId,
    required this.quizTitle,
    required this.studentId,
    this.classId,
    required this.answers,
    required this.timeSpent,
    required this.maxScore,
  });

  @override
  List<Object?> get props => [quizId, studentId];
}
