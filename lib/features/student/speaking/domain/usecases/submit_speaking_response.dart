import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/speaking/domain/repositories/speaking_repository.dart';

class SubmitSpeakingResponseParams extends Equatable {
  final String exerciseId;
  final List<String> userMessages;

  const SubmitSpeakingResponseParams({
    required this.exerciseId,
    required this.userMessages,
  });

  @override
  List<Object?> get props => [exerciseId, userMessages];
}

class SubmitSpeakingResponse
    implements UseCase<Map<String, dynamic>, SubmitSpeakingResponseParams> {
  final SpeakingRepository _repo;
  SubmitSpeakingResponse(this._repo);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    SubmitSpeakingResponseParams params,
  ) =>
      _repo.getFeedback(
        exerciseId: params.exerciseId,
        userMessages: params.userMessages,
      );
}
