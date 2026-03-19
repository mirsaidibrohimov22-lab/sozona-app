// QO'YISH: lib/features/learning_loop/domain/entities/activity_record.dart
// So'zona — Mashq natijasi entity
// ✅ Prompt talabi: userId, skillType, topic, difficulty,
//    correctAnswers, wrongAnswers, responseTime, vocabularyUsed, grammarErrors

import 'package:equatable/equatable.dart';

/// Mashq turi
enum SkillType {
  speaking,
  listening,
  quiz,
  flashcard;

  String get label {
    switch (this) {
      case SkillType.speaking:
        return 'Speaking';
      case SkillType.listening:
        return 'Listening';
      case SkillType.quiz:
        return 'Quiz';
      case SkillType.flashcard:
        return 'Flashcard';
    }
  }

  String get icon {
    switch (this) {
      case SkillType.speaking:
        return '🎤';
      case SkillType.listening:
        return '🎧';
      case SkillType.quiz:
        return '📝';
      case SkillType.flashcard:
        return '🃏';
    }
  }
}

/// Qiyinlik darajasi
enum DifficultyLevel {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Oson';
      case DifficultyLevel.medium:
        return "O'rtacha";
      case DifficultyLevel.hard:
        return 'Qiyin';
    }
  }
}

/// Mashq natijasi — Cloud Functions ga yuboriladi va Firestore da saqlanadi
class ActivityRecord extends Equatable {
  final String? id;
  final String userId;
  final SkillType skillType;
  final String topic;
  final DifficultyLevel difficulty;
  final int correctAnswers;
  final int wrongAnswers;
  final int responseTime; // soniyalarda
  final List<String> vocabularyUsed;
  final List<String> grammarErrors;
  final String language; // 'en' yoki 'de'
  final String level; // A1, A2, B1...
  final double scorePercent; // 0-100
  final List<String> weakItems;
  final List<String> strongItems;
  final String? sessionId;
  final String? contentId;
  final DateTime timestamp;

  const ActivityRecord({
    this.id,
    required this.userId,
    required this.skillType,
    required this.topic,
    required this.difficulty,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.responseTime,
    this.vocabularyUsed = const [],
    this.grammarErrors = const [],
    required this.language,
    required this.level,
    required this.scorePercent,
    this.weakItems = const [],
    this.strongItems = const [],
    this.sessionId,
    this.contentId,
    required this.timestamp,
  });

  /// Jami savollar
  int get totalQuestions => correctAnswers + wrongAnswers;

  /// To'g'ri javob foizi
  double get correctPercent {
    if (totalQuestions == 0) return 0;
    return (correctAnswers / totalQuestions) * 100;
  }

  /// Yaxshi natijami? (60% dan yuqori)
  bool get isPassing => scorePercent >= 60;

  /// Cloud Functions ga yuborish uchun Map
  Map<String, dynamic> toCallData() {
    return {
      'skillType': skillType.name,
      'topic': topic,
      'difficulty': difficulty.name,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'responseTime': responseTime,
      'vocabularyUsed': vocabularyUsed,
      'grammarErrors': grammarErrors,
      'language': language,
      'level': level,
      'scorePercent': scorePercent,
      'weakItems': weakItems,
      'strongItems': strongItems,
      if (sessionId != null) 'sessionId': sessionId,
      if (contentId != null) 'contentId': contentId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        skillType,
        topic,
        scorePercent,
        timestamp,
      ];
}
