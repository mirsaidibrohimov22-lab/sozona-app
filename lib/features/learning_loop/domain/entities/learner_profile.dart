// QO'YISH: lib/features/learning_loop/domain/entities/learner_profile.dart
// So'zona — O'quvchi AI profili entity
// AI ning "daftari" — student haqida hamma narsa shu yerda

import 'package:equatable/equatable.dart';

/// Ko'nikma ballari (0-100)
class SkillScores extends Equatable {
  final int vocabulary; // Lug'at
  final int grammar; // Grammatika
  final int listening; // Eshitish
  final int speaking; // Gapirish
  final int reading; // O'qish
  final int artikel; // Nemis artikeli (faqat DE uchun)

  const SkillScores({
    this.vocabulary = 0,
    this.grammar = 0,
    this.listening = 0,
    this.speaking = 0,
    this.reading = 0,
    this.artikel = 0,
  });

  /// Umumiy o'rtacha ball
  double get average {
    final scores = [vocabulary, grammar, listening, speaking, reading];
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Eng kuchli ko'nikma nomi
  String get strongestSkill {
    final map = {
      'vocabulary': vocabulary,
      'grammar': grammar,
      'listening': listening,
      'speaking': speaking,
      'reading': reading,
    };
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Eng zaif ko'nikma nomi
  String get weakestSkill {
    final map = {
      'vocabulary': vocabulary,
      'grammar': grammar,
      'listening': listening,
      'speaking': speaking,
      'reading': reading,
    };
    return map.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  SkillScores copyWith({
    int? vocabulary,
    int? grammar,
    int? listening,
    int? speaking,
    int? reading,
    int? artikel,
  }) {
    return SkillScores(
      vocabulary: vocabulary ?? this.vocabulary,
      grammar: grammar ?? this.grammar,
      listening: listening ?? this.listening,
      speaking: speaking ?? this.speaking,
      reading: reading ?? this.reading,
      artikel: artikel ?? this.artikel,
    );
  }

  @override
  List<Object?> get props =>
      [vocabulary, grammar, listening, speaking, reading, artikel];
}

/// O'quvchi AI profili
class LearnerProfile extends Equatable {
  final String userId;

  /// Umumiy ball (0-100)
  final int overallScore;

  /// Ko'nikmalar bo'yicha ball
  final SkillScores skillScores;

  /// Kuchli tomonlar
  final List<String> strongAreas;

  /// Zaif tomonlar
  final List<String> weakAreas;

  /// AI tavsiya qilgan daraja (null = hali tavsiya yo'q)
  final String? suggestedLevel;

  /// Nima uchun bu darajani tavsiya qildi
  final String? suggestedLevelReason;

  /// Jami urinishlar soni
  final int totalAttempts;

  /// Jami to'g'ri javoblar
  final int totalCorrect;

  /// O'rtacha sessiya balli
  final double averageSessionScore;

  /// Oxirgi tahlil vaqti
  final DateTime? lastAnalyzedAt;

  final DateTime updatedAt;

  const LearnerProfile({
    required this.userId,
    this.overallScore = 0,
    this.skillScores = const SkillScores(),
    this.strongAreas = const [],
    this.weakAreas = const [],
    this.suggestedLevel,
    this.suggestedLevelReason,
    this.totalAttempts = 0,
    this.totalCorrect = 0,
    this.averageSessionScore = 0.0,
    this.lastAnalyzedAt,
    required this.updatedAt,
  });

  /// To'g'ri javob foizi
  double get correctPercentage {
    if (totalAttempts == 0) return 0.0;
    return (totalCorrect / totalAttempts) * 100;
  }

  /// Profil to'liqmi (kamida 10 ta urinish bo'lganmi)
  bool get isProfileReady => totalAttempts >= 10;

  /// Yangi urinish natijasini profiga qo'shish
  LearnerProfile updateWithAttempt({
    required bool isCorrect,
    required String contentType,
    required int score,
  }) {
    final newTotal = totalAttempts + 1;
    final newCorrect = totalCorrect + (isCorrect ? 1 : 0);
    final newAverage =
        ((averageSessionScore * totalAttempts) + score) / newTotal;

    return copyWith(
      totalAttempts: newTotal,
      totalCorrect: newCorrect,
      averageSessionScore: newAverage,
      updatedAt: DateTime.now(),
    );
  }

  LearnerProfile copyWith({
    String? userId,
    int? overallScore,
    SkillScores? skillScores,
    List<String>? strongAreas,
    List<String>? weakAreas,
    String? suggestedLevel,
    String? suggestedLevelReason,
    int? totalAttempts,
    int? totalCorrect,
    double? averageSessionScore,
    DateTime? lastAnalyzedAt,
    DateTime? updatedAt,
  }) {
    return LearnerProfile(
      userId: userId ?? this.userId,
      overallScore: overallScore ?? this.overallScore,
      skillScores: skillScores ?? this.skillScores,
      strongAreas: strongAreas ?? this.strongAreas,
      weakAreas: weakAreas ?? this.weakAreas,
      suggestedLevel: suggestedLevel ?? this.suggestedLevel,
      suggestedLevelReason: suggestedLevelReason ?? this.suggestedLevelReason,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      averageSessionScore: averageSessionScore ?? this.averageSessionScore,
      lastAnalyzedAt: lastAnalyzedAt ?? this.lastAnalyzedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [userId, overallScore, skillScores, totalAttempts];
}
