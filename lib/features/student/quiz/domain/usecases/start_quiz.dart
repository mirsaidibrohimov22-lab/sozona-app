import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/domain/repositories/quiz_repository.dart';

class StartQuiz implements UseCase<Quiz, StartQuizParams> {
  final QuizRepository repository;
  StartQuiz(this.repository);

  @override
  Future<Either<Failure, Quiz>> call(StartQuizParams params) async {
    return await repository.getQuizDetail(params.quizId);
  }
}

class StartQuizParams extends Equatable {
  final String quizId;
  final String studentId;

  const StartQuizParams({required this.quizId, required this.studentId});

  @override
  List<Object> get props => [quizId, studentId];
}
