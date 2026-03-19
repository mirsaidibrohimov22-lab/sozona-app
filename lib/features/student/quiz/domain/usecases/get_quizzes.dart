import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/domain/repositories/quiz_repository.dart';

class GetQuizzes implements UseCase<List<Quiz>, GetQuizzesParams> {
  final QuizRepository repository;
  GetQuizzes(this.repository);

  @override
  Future<Either<Failure, List<Quiz>>> call(GetQuizzesParams params) async {
    return await repository.getQuizzes(
      userId: params.userId,
      language: params.language ?? '',
      level: params.level ?? '',
      classId: params.classId,
    );
  }
}

class GetQuizzesParams extends Equatable {
  final String userId;
  final String? language;
  final String? level;
  final String? classId;

  const GetQuizzesParams({
    required this.userId,
    this.language,
    this.level,
    this.classId,
  });

  @override
  List<Object?> get props => [userId, language, level, classId];
}
