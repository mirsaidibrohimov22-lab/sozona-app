// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Speaking Exercise Entity
// QO'YISH: lib/features/student/speaking/domain/entities/speaking_exercise.dart
// ═══════════════════════════════════════════════════════════════

import 'package:equatable/equatable.dart';

/// Speaking Exercise Entity
class SpeakingExercise extends Equatable {
  final String id;
  final String topic;
  final String language;
  final String level;
  final List<DialogTurn> turns;
  final List<VocabularyItem> vocabulary;
  final String? culturalNotes;
  final DateTime createdAt;

  const SpeakingExercise({
    required this.id,
    required this.topic,
    required this.language,
    required this.level,
    required this.turns,
    required this.vocabulary,
    this.culturalNotes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        topic,
        language,
        level,
        turns,
        vocabulary,
        culturalNotes,
        createdAt,
      ];
}

/// Dialog Turn - har bir suhbat qadami
class DialogTurn extends Equatable {
  final String speaker; // 'student' yoki 'partner'
  final String? text; // Partner matni
  final String? translation;
  final String? tips;
  final String? suggestion; // Student uchun tavsiya
  final List<String>? alternatives; // Boshqa variant javoblar

  const DialogTurn({
    required this.speaker,
    this.text,
    this.translation,
    this.tips,
    this.suggestion,
    this.alternatives,
  });

  bool get isStudentTurn => speaker == 'student';
  bool get isPartnerTurn => speaker == 'partner';

  @override
  List<Object?> get props => [
        speaker,
        text,
        translation,
        tips,
        suggestion,
        alternatives,
      ];
}

/// Vocabulary Item
class VocabularyItem extends Equatable {
  final String word;
  final String translation;
  final String? example;

  const VocabularyItem({
    required this.word,
    required this.translation,
    this.example,
  });

  @override
  List<Object?> get props => [word, translation, example];
}
