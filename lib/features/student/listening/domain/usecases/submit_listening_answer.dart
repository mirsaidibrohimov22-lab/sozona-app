// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Submit Listening Answers UseCase
// QO'YISH: lib/features/student/listening/domain/usecases/submit_listening_answers.dart
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/listening/domain/repositories/listening_repository.dart';

/// Submit Listening Answers UseCase
class SubmitListeningAnswers
    implements UseCase<Map<String, dynamic>, SubmitListeningParams> {
  final ListeningRepository repository;

  SubmitListeningAnswers(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    SubmitListeningParams params,
  ) async {
    return await repository.submitListeningAnswers(
      exerciseId: params.exerciseId,
      studentId: params.studentId,
      answers: params.answers,
      timeSpent: params.timeSpent,
    );
  }
}

/// Submit Listening parametrlari
class SubmitListeningParams extends Equatable {
  final String exerciseId;
  final String studentId;
  final Map<String, String> answers;
  final int timeSpent;

  const SubmitListeningParams({
    required this.exerciseId,
    required this.studentId,
    required this.answers,
    required this.timeSpent,
  });

  @override
  List<Object> get props => [exerciseId, studentId, answers, timeSpent];
}
