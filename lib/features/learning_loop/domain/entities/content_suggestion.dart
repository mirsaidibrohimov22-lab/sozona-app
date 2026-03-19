// QO'YISH: lib/features/learning_loop/domain/entities/content_suggestion.dart
// So'zona — Adaptive Content Suggestion Entity
// ✅ Prompt talabi: tizim foydalanuvchiga mos mashqlar berishi kerak

import 'package:equatable/equatable.dart';

/// Mashq tavsiyasi turi
enum SuggestionType {
  quiz,
  flashcard,
  listening,
  speaking;

  String get label {
    switch (this) {
      case SuggestionType.quiz:
        return 'Quiz';
      case SuggestionType.flashcard:
        return 'Flashcard';
      case SuggestionType.listening:
        return 'Listening';
      case SuggestionType.speaking:
        return 'Speaking';
    }
  }

  String get icon {
    switch (this) {
      case SuggestionType.quiz:
        return '📝';
      case SuggestionType.flashcard:
        return '🃏';
      case SuggestionType.listening:
        return '🎧';
      case SuggestionType.speaking:
        return '🎤';
    }
  }

  String get color {
    switch (this) {
      case SuggestionType.quiz:
        return '#4CAF50';
      case SuggestionType.flashcard:
        return '#FF9800';
      case SuggestionType.listening:
        return '#2196F3';
      case SuggestionType.speaking:
        return '#9C27B0';
    }
  }
}

/// AI tavsiya qilgan mashq
class ContentSuggestion extends Equatable {
  /// Mashq turi
  final SuggestionType type;

  /// Mavzu
  final String topic;

  /// Qiyinlik
  final String difficulty;

  /// Nima uchun bu mashq tanlandi
  final String reason;

  /// Muhimlik (1 = eng muhim)
  final int priority;

  /// Taxminiy vaqt (daqiqalarda)
  final int estimatedTime;

  /// Cloud Function ga yuborish uchun parametrlar
  final Map<String, dynamic> params;

  const ContentSuggestion({
    required this.type,
    required this.topic,
    this.difficulty = 'medium',
    required this.reason,
    this.priority = 5,
    this.estimatedTime = 5,
    this.params = const {},
  });

  /// Eng muhim mashqmi?
  bool get isHighPriority => priority <= 2;

  /// Map dan yaratish
  factory ContentSuggestion.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'quiz';
    final type = SuggestionType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => SuggestionType.quiz,
    );

    return ContentSuggestion(
      type: type,
      topic: map['topic'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'medium',
      reason: map['reason'] as String? ?? '',
      priority: (map['priority'] as num?)?.toInt() ?? 5,
      estimatedTime: (map['estimatedTime'] as num?)?.toInt() ?? 5,
      params: Map<String, dynamic>.from(map['params'] as Map? ?? {}),
    );
  }

  @override
  List<Object?> get props => [type, topic, priority];
}

/// Sessiya rejasi — 10 daqiqalik mashq ketma-ketligi
class AdaptiveSessionPlan extends Equatable {
  /// Mashq tavsiyalari (prioritet bo'yicha tartiblangan)
  final List<ContentSuggestion> suggestions;

  /// Sessiya rejasi (vaqt bilan)
  final List<SessionStep> steps;

  /// Motivatsiya xabari
  final String motivationNote;

  /// Foydalanuvchi qisqacha profili
  final UserQuickSummary? summary;

  const AdaptiveSessionPlan({
    required this.suggestions,
    required this.steps,
    required this.motivationNote,
    this.summary,
  });

  /// Jami vaqt (daqiqalarda)
  int get totalDuration => steps.fold(0, (sum, step) => sum + step.duration);

  /// Mashqlar soni
  int get totalExercises => steps.length;

  @override
  List<Object?> get props => [suggestions, steps, motivationNote];
}

/// Sessiya qadami
class SessionStep extends Equatable {
  final int order;
  final String type;
  final String topic;
  final int duration; // daqiqalarda

  const SessionStep({
    required this.order,
    required this.type,
    required this.topic,
    required this.duration,
  });

  factory SessionStep.fromMap(Map<String, dynamic> map) {
    return SessionStep(
      order: (map['order'] as num?)?.toInt() ?? 1,
      type: map['type'] as String? ?? 'quiz',
      topic: map['topic'] as String? ?? '',
      duration: (map['duration'] as num?)?.toInt() ?? 5,
    );
  }

  @override
  List<Object?> get props => [order, type, topic];
}

/// Foydalanuvchi qisqacha profili
class UserQuickSummary extends Equatable {
  final String level;
  final String strongSkill;
  final String weakSkill;
  final List<String> weakTopics;
  final double averageScore;

  const UserQuickSummary({
    required this.level,
    required this.strongSkill,
    required this.weakSkill,
    required this.weakTopics,
    required this.averageScore,
  });

  factory UserQuickSummary.fromMap(Map<String, dynamic> map) {
    return UserQuickSummary(
      level: map['level'] as String? ?? 'A1',
      strongSkill: map['strongSkill'] as String? ?? '',
      weakSkill: map['weakSkill'] as String? ?? '',
      weakTopics: List<String>.from(map['weakTopics'] ?? []),
      averageScore: (map['averageScore'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [level, strongSkill, weakSkill, averageScore];
}
