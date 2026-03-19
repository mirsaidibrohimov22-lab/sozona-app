// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Send Message UseCase
// QO'YISH: lib/features/student/ai_chat/domain/usecases/send_message.dart
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/ai_chat/domain/entities/chat_message.dart';
import 'package:my_first_app/features/student/ai_chat/domain/repositories/chat_repository.dart';

class SendMessage implements UseCase<ChatMessage, SendMessageChatParams> {
  final ChatRepository repository;
  SendMessage(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(
    SendMessageChatParams params,
  ) async {
    return await repository.sendMessage(
      userId: params.userId,
      message: params.message,
      language: params.language,
      level: params.level,
      history: params.history,
    );
  }
}

class SendMessageChatParams extends Equatable {
  final String userId;
  final String message;
  final String language;
  final String level;
  final List<ChatMessage> history;

  const SendMessageChatParams({
    required this.userId,
    required this.message,
    required this.language,
    required this.level,
    required this.history,
  });

  @override
  List<Object> get props => [userId, message, language, level];
}
