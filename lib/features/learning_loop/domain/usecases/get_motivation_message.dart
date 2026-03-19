// lib/features/learning_loop/domain/usecases/get_motivation_message.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/learning_loop/domain/repositories/learning_loop_repository.dart';

class GetMotivationMessageParams extends Equatable {
  final String userId;
  final int currentStreak;
  final double averageScore;
  final String language;

  const GetMotivationMessageParams({
    required this.userId,
    required this.currentStreak,
    required this.averageScore,
    required this.language,
  });

  @override
  List<Object?> get props => [userId, currentStreak, averageScore, language];
}

class GetMotivationMessage
    implements UseCase<String, GetMotivationMessageParams> {
  final LearningLoopRepository _repo;
  GetMotivationMessage(this._repo);

  @override
  Future<Either<Failure, String>> call(GetMotivationMessageParams p) =>
      _repo.getMotivationMessage(
        userId: p.userId,
        currentStreak: p.currentStreak,
        averageScore: p.averageScore,
        language: p.language,
      );
}
