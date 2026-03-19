// QO'YISH: lib/features/teacher/content_generator/domain/entities/generated_content.dart
// Generated Content Entity — AI tomonidan yaratilgan kontent

import 'package:equatable/equatable.dart';

/// AI tomonidan yaratilgan kontent
///
/// Bolaga: Bu — AI yaratgan mashqning "pasporti".
/// Qaysi turda (quiz/flashcard/listening), qaysi tilda, qanday holatda — hammasi shu yerda.
class GeneratedContent extends Equatable {
  final String id; // Vaqtinchalik ID (Firestore'ga saqlanguncha)
  final ContentType type; // quiz, speaking, listening
  final String language; // en, de
  final String level; // A1, A2, B1, B2, C1
  final String topic; // Mavzu
  final Map<String, dynamic>
      data; // Asosiy kontent (quiz questions, flashcard cards, etc.)
  final GenerationStatus status; // generating, completed, failed
  final String? errorMessage; // Agar xatolik bo'lsa
  final DateTime generatedAt;
  final String aiModel; // gpt-4o, gemini-pro, etc.

  const GeneratedContent({
    required this.id,
    required this.type,
    required this.language,
    required this.level,
    required this.topic,
    required this.data,
    required this.status,
    this.errorMessage,
    required this.generatedAt,
    required this.aiModel,
  });

  /// Kontent tayyor bo'ldimi?
  bool get isCompleted => status == GenerationStatus.completed;

  /// Kontent yaratilayotganmi?
  bool get isGenerating => status == GenerationStatus.generating;

  /// Xatolik bormi?
  bool get hasFailed => status == GenerationStatus.failed;

  // UI uchun qulay getter'lar
  String get title => topic;
  String get description => 'Level: $level | Language: $language';
  int get itemCount {
    final items = data['questions'] ?? data['cards'] ?? data['exercises'] ?? [];
    return (items as List).length;
  }

  /// Quiz uchun savol soni
  int? get questionCount {
    if (type != ContentType.quiz) return null;
    final questions = data['questions'] as List?;
    return questions?.length;
  }

  /// Speaking uchun mashq soni
  int? get speakingCount {
    if (type != ContentType.speaking) return null;
    final exercises = data['exercises'] as List?;
    return exercises?.length;
  }

  /// Listening uchun davomiylik
  int? get audioDuration {
    if (type != ContentType.listening) return null;
    return data['audioDuration'] as int?;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        language,
        level,
        topic,
        data,
        status,
        errorMessage,
        generatedAt,
        aiModel,
      ];

  /// Copy with
  GeneratedContent copyWith({
    String? id,
    ContentType? type,
    String? language,
    String? level,
    String? topic,
    Map<String, dynamic>? data,
    GenerationStatus? status,
    String? errorMessage,
    DateTime? generatedAt,
    String? aiModel,
  }) {
    return GeneratedContent(
      id: id ?? this.id,
      type: type ?? this.type,
      language: language ?? this.language,
      level: level ?? this.level,
      topic: topic ?? this.topic,
      data: data ?? this.data,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      generatedAt: generatedAt ?? this.generatedAt,
      aiModel: aiModel ?? this.aiModel,
    );
  }
}

/// Kontent turi
enum ContentType {
  quiz,
  speaking,
  listening;

  /// String'dan enum yaratish
  static ContentType fromString(String value) {
    switch (value) {
      case 'quiz':
        return ContentType.quiz;
      case 'speaking':
        return ContentType.speaking;
      case 'listening':
        return ContentType.listening;
      default:
        throw ArgumentError('Noto\'g\'ri content type: $value');
    }
  }

  /// Enum'dan string yaratish
  String toFirestore() {
    switch (this) {
      case ContentType.quiz:
        return 'quiz';
      case ContentType.speaking:
        return 'speaking';
      case ContentType.listening:
        return 'listening';
    }
  }

  /// Display uchun nom
  String get displayName {
    switch (this) {
      case ContentType.quiz:
        return 'Quiz';
      case ContentType.speaking:
        return 'Speaking';
      case ContentType.listening:
        return 'Listening';
    }
  }

  /// Icon nomi (Material Icons)
  String get iconName {
    switch (this) {
      case ContentType.quiz:
        return 'quiz';
      case ContentType.speaking:
        return 'record_voice_over';
      case ContentType.listening:
        return 'headphones';
    }
  }
}

/// Kontent yaratish holati
enum GenerationStatus {
  generating, // AI hozir yaratyapti
  completed, // Tayyor
  failed; // Xatolik

  /// String'dan enum yaratish
  static GenerationStatus fromString(String value) {
    switch (value) {
      case 'generating':
        return GenerationStatus.generating;
      case 'completed':
        return GenerationStatus.completed;
      case 'failed':
        return GenerationStatus.failed;
      default:
        throw ArgumentError('Noto\'g\'ri generation status: $value');
    }
  }

  /// Enum'dan string yaratish
  String toFirestore() {
    switch (this) {
      case GenerationStatus.generating:
        return 'generating';
      case GenerationStatus.completed:
        return 'completed';
      case GenerationStatus.failed:
        return 'failed';
    }
  }

  /// Display uchun nom
  String get displayName {
    switch (this) {
      case GenerationStatus.generating:
        return 'Yaratilmoqda...';
      case GenerationStatus.completed:
        return 'Tayyor';
      case GenerationStatus.failed:
        return 'Xatolik';
    }
  }
}
