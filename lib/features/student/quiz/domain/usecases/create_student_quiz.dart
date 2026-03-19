import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/domain/repositories/quiz_repository.dart';

class CreateStudentQuiz extends UseCase<Quiz, CreateStudentQuizParams> {
  final QuizRepository repository;
  CreateStudentQuiz(this.repository);

  @override
  Future<Either<Failure, Quiz>> call(CreateStudentQuizParams params) {
    return repository.createStudentQuiz(
      userId: params.userId,
      language: params.language,
      level: params.level,
      topic: params.topic,
    );
  }
}

class CreateStudentQuizParams extends Equatable {
  final String userId;
  final String language;
  final String level;
  final String topic;

  const CreateStudentQuizParams({
    required this.userId,
    required this.language,
    required this.level,
    required this.topic,
  });

  @override
  List<Object?> get props => [userId, language, level, topic];
}
