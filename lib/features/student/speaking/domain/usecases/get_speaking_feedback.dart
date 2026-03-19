// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Get Speaking Feedback UseCase
// QO'YISH: lib/features/student/speaking/domain/usecases/get_speaking_feedback.dart
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/speaking/domain/repositories/speaking_repository.dart';

class GetSpeakingFeedback
    implements UseCase<Map<String, dynamic>, GetFeedbackParams> {
  final SpeakingRepository repository;

  GetSpeakingFeedback(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    GetFeedbackParams params,
  ) async {
    return await repository.getFeedback(
      exerciseId: params.exerciseId,
      userMessages: params.userMessages,
    );
  }
}

class GetFeedbackParams extends Equatable {
  final String exerciseId;
  final List<String> userMessages;

  const GetFeedbackParams({
    required this.exerciseId,
    required this.userMessages,
  });

  @override
  List<Object> get props => [exerciseId, userMessages];
}
