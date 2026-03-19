// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Send Speaking Message UseCase
// QO'YISH: lib/features/student/speaking/domain/usecases/send_speaking_message.dart
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/speaking/domain/repositories/speaking_repository.dart';

class SendSpeakingMessage
    implements UseCase<Map<String, dynamic>, SendMessageParams> {
  final SpeakingRepository repository;

  SendSpeakingMessage(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    SendMessageParams params,
  ) async {
    return await repository.sendMessage(
      exerciseId: params.exerciseId,
      userMessage: params.userMessage,
      turnIndex: params.turnIndex,
    );
  }
}

class SendMessageParams extends Equatable {
  final String exerciseId;
  final String userMessage;
  final int turnIndex;

  const SendMessageParams({
    required this.exerciseId,
    required this.userMessage,
    required this.turnIndex,
  });

  @override
  List<Object> get props => [exerciseId, userMessage, turnIndex];
}
