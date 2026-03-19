// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Chat Repository Interface
// QO'YISH: lib/features/student/ai_chat/domain/repositories/chat_repository.dart
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/student/ai_chat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String userId,
    required String message,
    required String language,
    required String level,
    required List<ChatMessage> history,
  });

  Future<Either<Failure, List<ChatMessage>>> getChatHistory(String userId);

  Future<Either<Failure, void>> clearHistory(String userId);
}
