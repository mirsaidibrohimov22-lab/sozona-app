// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Get Chat History UseCase
// QO'YISH: lib/features/student/ai_chat/domain/usecases/get_chat_history.dart
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/ai_chat/domain/entities/chat_message.dart';
import 'package:my_first_app/features/student/ai_chat/domain/repositories/chat_repository.dart';

class GetChatHistory
    implements UseCase<List<ChatMessage>, GetChatHistoryParams> {
  final ChatRepository repository;
  GetChatHistory(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(
    GetChatHistoryParams params,
  ) async {
    return await repository.getChatHistory(params.userId);
  }
}

class GetChatHistoryParams extends Equatable {
  final String userId;
  const GetChatHistoryParams({required this.userId});

  @override
  List<Object> get props => [userId];
}
