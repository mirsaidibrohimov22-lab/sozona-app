import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/domain/repositories/quiz_repository.dart';

class GetAiRecommendedQuiz extends UseCase<Quiz, GetAiRecommendedQuizParams> {
  final QuizRepository repository;
  GetAiRecommendedQuiz(this.repository);

  @override
  Future<Either<Failure, Quiz>> call(GetAiRecommendedQuizParams params) {
    return repository.getAiRecommendedQuiz(
      userId: params.userId,
      language: params.language ?? '',
      level: params.level ?? '',
    );
  }
}

class GetAiRecommendedQuizParams extends Equatable {
  final String userId;
  final String? language;
  final String? level;

  const GetAiRecommendedQuizParams({
    required this.userId,
    this.language,
    this.level,
  });

  @override
  List<Object?> get props => [userId, language, level];
}
