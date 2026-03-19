// QO'YISH: lib/features/learning_loop/domain/entities/user_ai_profile.dart
// So'zona — Foydalanuvchi AI profili entity
// ✅ Prompt talabi: vocabularyLevel, grammarLevel, listeningLevel,
//    speakingLevel, weakTopics, strongTopics

import 'package:equatable/equatable.dart';

/// Foydalanuvchi AI profili — adaptive learning uchun asos
/// Backend (Cloud Functions) tomonidan hisoblanadi
class UserAiProfile extends Equatable {
  final String userId;

  /// Ko'nikma ballari (0-100)
  final int vocabularyLevel;
  final int grammarLevel;
  final int listeningLevel;
  final int speakingLevel;

  /// Zaif mavzular (masalan: ['articles', 'past_tense'])
  final List<String> weakTopics;

  /// Kuchli mavzular
  final List<String> strongTopics;

  /// Umumiy daraja (A1, A2, B1, B2, C1)
  final String overallLevel;

  /// Jami mashqlar soni
  final int totalActivities;

  /// O'rtacha ball (0-100)
  final double averageScore;

  const UserAiProfile({
    required this.userId,
    this.vocabularyLevel = 50,
    this.grammarLevel = 50,
    this.listeningLevel = 50,
    this.speakingLevel = 50,
    this.weakTopics = const [],
    this.strongTopics = const [],
    this.overallLevel = 'A1',
    this.totalActivities = 0,
    this.averageScore = 0,
  });

  /// O'rtacha ko'nikma balli
  double get averageSkillScore =>
      (vocabularyLevel + grammarLevel + listeningLevel + speakingLevel) / 4;

  /// Eng kuchli ko'nikma
  String get strongestSkill {
    final skills = {
      'vocabulary': vocabularyLevel,
      'grammar': grammarLevel,
      'listening': listeningLevel,
      'speaking': speakingLevel,
    };
    return skills.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Eng zaif ko'nikma
  String get weakestSkill {
    final skills = {
      'vocabulary': vocabularyLevel,
      'grammar': grammarLevel,
      'listening': listeningLevel,
      'speaking': speakingLevel,
    };
    return skills.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  /// Ko'nikma ballini nomi bo'yicha olish
  int getSkillScore(String skill) {
    switch (skill) {
      case 'vocabulary':
        return vocabularyLevel;
      case 'grammar':
        return grammarLevel;
      case 'listening':
        return listeningLevel;
      case 'speaking':
        return speakingLevel;
      default:
        return 50;
    }
  }

  /// Profil to'liqmi (kamida 10 ta mashq)
  bool get isProfileReady => totalActivities >= 10;

  /// Cloud Functions dan kelgan Map ni parse qilish
  factory UserAiProfile.fromMap(Map<String, dynamic> map) {
    return UserAiProfile(
      userId: map['userId'] as String? ?? '',
      vocabularyLevel: (map['vocabularyLevel'] as num?)?.toInt() ?? 50,
      grammarLevel: (map['grammarLevel'] as num?)?.toInt() ?? 50,
      listeningLevel: (map['listeningLevel'] as num?)?.toInt() ?? 50,
      speakingLevel: (map['speakingLevel'] as num?)?.toInt() ?? 50,
      weakTopics: List<String>.from(map['weakTopics'] ?? []),
      strongTopics: List<String>.from(map['strongTopics'] ?? []),
      overallLevel: map['overallLevel'] as String? ?? 'A1',
      totalActivities: (map['totalActivities'] as num?)?.toInt() ?? 0,
      averageScore: (map['averageScore'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        vocabularyLevel,
        grammarLevel,
        listeningLevel,
        speakingLevel,
        overallLevel,
        totalActivities,
      ];
}
