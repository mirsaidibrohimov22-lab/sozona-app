// QO'YISH: lib/features/student/ai_chat/domain/entities/chat_message.dart
// So'zona — Chat Message Entity (YANGILANGAN + ESKI KOD BILAN MOS)
// ✅ isUser va isLoading eski kod uchun saqlanadi
// ✅ YANGI: suggestions, grammarTip, detectedTopic, relatedExercise

import 'package:equatable/equatable.dart';

/// Xabar roli
enum MessageRole {
  user,
  assistant,
  system;
}

/// Chat xabari
class ChatMessage extends Equatable {
  /// Xabar ID
  final String id;

  /// Xabar matni
  final String text;

  /// Kim yozgan
  final MessageRole role;

  /// Vaqt
  final DateTime timestamp;

  /// Loading holat — AI yozmoqda
  /// ✅ Eski nom saqlanadi (ai_chat_provider, ai_chat_screen, chat_message_model ishlatadi)
  final bool isLoading;

  /// Xato bo'ldimi
  final bool isError;

  /// ✅ YANGI: AI tavsiya qilgan keyingi savollar
  final List<String> suggestions;

  /// ✅ YANGI: Grammatik maslahat (ixtiyoriy)
  final String? grammarTip;

  /// ✅ YANGI: AI aniqlagan mavzu
  final String? detectedTopic;

  /// ✅ YANGI: Tegishli mashq tavsiyasi
  final ChatRelatedExercise? relatedExercise;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
    this.isError = false,
    this.suggestions = const [],
    this.grammarTip,
    this.detectedTopic,
    this.relatedExercise,
  });

  /// ✅ Eski kod uchun — chat_bubble.dart, chat_remote_datasource.dart
  bool get isUser => role == MessageRole.user;

  /// ✅ Eski kod uchun
  bool get isAssistant => role == MessageRole.assistant;

  /// Loading xabar yaratish
  factory ChatMessage.sending(String text) {
    return ChatMessage(
      id: 'sending_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  /// AI yozmoqda xabar
  factory ChatMessage.typing() {
    return ChatMessage(
      id: 'typing',
      text: '',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  /// Xato xabar
  factory ChatMessage.error(String errorText) {
    return ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      text: errorText,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isError: true,
    );
  }

  /// Suggestions bormi?
  bool get hasSuggestions => suggestions.isNotEmpty;

  /// Grammar tip bormi?
  bool get hasGrammarTip => grammarTip != null && grammarTip!.isNotEmpty;

  /// Related exercise bormi?
  bool get hasRelatedExercise => relatedExercise != null;

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageRole? role,
    DateTime? timestamp,
    bool? isLoading,
    bool? isError,
    List<String>? suggestions,
    String? grammarTip,
    String? detectedTopic,
    ChatRelatedExercise? relatedExercise,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      suggestions: suggestions ?? this.suggestions,
      grammarTip: grammarTip ?? this.grammarTip,
      detectedTopic: detectedTopic ?? this.detectedTopic,
      relatedExercise: relatedExercise ?? this.relatedExercise,
    );
  }

  @override
  List<Object?> get props => [id, text, role, timestamp, isLoading];
}

/// Tegishli mashq tavsiyasi (chatdan keladi)
class ChatRelatedExercise extends Equatable {
  final String type; // quiz, flashcard, listening, speaking
  final String topic;
  final String reason;

  const ChatRelatedExercise({
    required this.type,
    required this.topic,
    required this.reason,
  });

  @override
  List<Object?> get props => [type, topic, reason];
}
