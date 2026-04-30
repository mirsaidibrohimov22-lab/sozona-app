// lib/features/student/speaking/data/models/speaking_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/student/speaking/domain/entities/speaking_exercise.dart';

/// createdAt maydonini xavfsiz o'qish — Timestamp, int, null hammasini qabul qiladi
DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.now();
}

class SpeakingModel extends SpeakingExercise {
  const SpeakingModel({
    required super.id,
    required super.topic,
    required super.language,
    required super.level,
    required super.turns,
    required super.vocabulary,
    super.culturalNotes,
    required super.createdAt,
  });

  factory SpeakingModel.fromJson(Map<String, dynamic> json, String id) {
    // ✅ FIX: null-safe castlar — 'as String' o'rniga '?? fallback'
    return SpeakingModel(
      id: id,
      topic: json['topic'] as String? ?? 'Speaking Practice',
      language: json['language'] as String? ?? 'en',
      level: json['level'] as String? ?? 'A1',
      turns: ((json['turns'] as List<dynamic>?) ?? [])
          .map((t) => DialogTurnModel.fromJson(t as Map<String, dynamic>))
          .toList(),
      vocabulary: ((json['vocabulary'] as List<dynamic>?) ?? [])
          .map((v) => VocabularyItemModel.fromJson(v as Map<String, dynamic>))
          .toList(),
      culturalNotes: json['culturalNotes'] as String?,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'language': language,
      'level': level,
      'turns':
          turns.map((t) => DialogTurnModel.fromEntity(t).toJson()).toList(),
      'vocabulary': vocabulary
          .map((v) => VocabularyItemModel.fromEntity(v).toJson())
          .toList(),
      'culturalNotes': culturalNotes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SpeakingModel.fromEntity(SpeakingExercise entity) {
    return SpeakingModel(
      id: entity.id,
      topic: entity.topic,
      language: entity.language,
      level: entity.level,
      turns: entity.turns,
      vocabulary: entity.vocabulary,
      culturalNotes: entity.culturalNotes,
      createdAt: entity.createdAt,
    );
  }
}

class DialogTurnModel extends DialogTurn {
  const DialogTurnModel({
    required super.speaker,
    super.text,
    super.translation,
    super.tips,
    super.suggestion,
    super.alternatives,
  });

  factory DialogTurnModel.fromJson(Map<String, dynamic> json) {
    // ✅ FIX: 'role' yoki 'speaker' — ikkalasini ham qabul qiladi
    final speaker = (json['speaker'] ?? json['role'] ?? 'ai') as String;
    return DialogTurnModel(
      speaker: speaker,
      text: json['text'] as String?,
      translation: json['translation'] as String?,
      tips: json['tips'] as String? ?? json['hint'] as String?,
      suggestion: json['suggestion'] as String?,
      alternatives: (json['alternatives'] as List<dynamic>?)
          ?.map((a) => a as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speaker': speaker,
      if (text != null) 'text': text,
      if (translation != null) 'translation': translation,
      if (tips != null) 'tips': tips,
      if (suggestion != null) 'suggestion': suggestion,
      if (alternatives != null) 'alternatives': alternatives,
    };
  }

  factory DialogTurnModel.fromEntity(DialogTurn entity) {
    return DialogTurnModel(
      speaker: entity.speaker,
      text: entity.text,
      translation: entity.translation,
      tips: entity.tips,
      suggestion: entity.suggestion,
      alternatives: entity.alternatives,
    );
  }
}

class VocabularyItemModel extends VocabularyItem {
  const VocabularyItemModel({
    required super.word,
    required super.translation,
    super.example,
  });

  factory VocabularyItemModel.fromJson(Map<String, dynamic> json) {
    return VocabularyItemModel(
      word: json['word'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      example: json['example'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      if (example != null) 'example': example,
    };
  }

  factory VocabularyItemModel.fromEntity(VocabularyItem entity) {
    return VocabularyItemModel(
      word: entity.word,
      translation: entity.translation,
      example: entity.example,
    );
  }
}
