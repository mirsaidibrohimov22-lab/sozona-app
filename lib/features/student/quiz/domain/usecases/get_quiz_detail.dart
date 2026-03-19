import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/domain/repositories/quiz_repository.dart';

class GetQuizDetail extends UseCase<Quiz, GetQuizDetailParams> {
  final QuizRepository repository;
  GetQuizDetail(this.repository);

  @override
  Future<Either<Failure, Quiz>> call(GetQuizDetailParams params) {
    return repository.getQuizDetail(params.quizId);
  }
}

class GetQuizDetailParams extends Equatable {
  final String quizId;
  const GetQuizDetailParams({required this.quizId});

  @override
  List<Object> get props => [quizId];
}
