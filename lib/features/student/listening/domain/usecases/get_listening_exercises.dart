// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Get Listening Exercises UseCase
// QO'YISH: lib/features/student/listening/domain/usecases/get_listening_exercises.dart
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/listening/domain/entities/listening_exercise.dart';
import 'package:my_first_app/features/student/listening/domain/repositories/listening_repository.dart';

/// Get Listening Exercises UseCase
class GetListeningExercises
    implements UseCase<List<ListeningExercise>, GetListeningParams> {
  final ListeningRepository repository;

  GetListeningExercises(this.repository);

  @override
  Future<Either<Failure, List<ListeningExercise>>> call(
    GetListeningParams params,
  ) async {
    return await repository.getListeningExercises(
      language: params.language,
      level: params.level,
      topic: params.topic,
    );
  }
}

/// Get Listening parametrlari
class GetListeningParams extends Equatable {
  final String? language;
  final String? level;
  final String? topic;

  const GetListeningParams({
    this.language,
    this.level,
    this.topic,
  });

  @override
  List<Object?> get props => [language, level, topic];
}
