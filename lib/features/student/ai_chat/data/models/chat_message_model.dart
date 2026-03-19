// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Chat Message Model
// QO'YISH: lib/features/student/ai_chat/data/models/chat_message_model.dart
// ═══════════════════════════════════════════════════════════════

import 'package:my_first_app/features/student/ai_chat/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.text,
    required super.role,
    required super.timestamp,
    super.isLoading,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      text: entity.text,
      role: entity.role,
      timestamp: entity.timestamp,
    );
  }
}
