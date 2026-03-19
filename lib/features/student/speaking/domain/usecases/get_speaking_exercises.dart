// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Get Speaking Exercises UseCase
// QO'YISH: lib/features/student/speaking/domain/usecases/get_speaking_exercises.dart
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/speaking/domain/entities/speaking_exercise.dart';
import 'package:my_first_app/features/student/speaking/domain/repositories/speaking_repository.dart';

class GetSpeakingExercises
    implements UseCase<List<SpeakingExercise>, GetSpeakingParams> {
  final SpeakingRepository repository;

  GetSpeakingExercises(this.repository);

  @override
  Future<Either<Failure, List<SpeakingExercise>>> call(
    GetSpeakingParams params,
  ) async {
    return await repository.getExercises(
      language: params.language,
      level: params.level,
    );
  }
}

class GetSpeakingParams extends Equatable {
  final String? language;
  final String? level;

  const GetSpeakingParams({
    this.language,
    this.level,
  });

  @override
  List<Object?> get props => [language, level];
}
