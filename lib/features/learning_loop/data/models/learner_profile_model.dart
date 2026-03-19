// QO'YISH: lib/features/learning_loop/data/models/learner_profile_model.dart
// So'zona — LearnerProfile Firestore modeli

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/learner_profile.dart';

class LearnerProfileModel extends LearnerProfile {
  const LearnerProfileModel({
    required super.userId,
    super.overallScore,
    super.skillScores,
    super.strongAreas,
    super.weakAreas,
    super.suggestedLevel,
    super.suggestedLevelReason,
    super.totalAttempts,
    super.totalCorrect,
    super.averageSessionScore,
    super.lastAnalyzedAt,
    required super.updatedAt,
  });

  factory LearnerProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LearnerProfileModel.fromMap(data);
  }

  factory LearnerProfileModel.fromMap(Map<String, dynamic> map) {
    final skillMap = map['skillScores'] as Map<String, dynamic>? ?? {};

    return LearnerProfileModel(
      userId: map['userId'] as String? ?? '',
      overallScore: map['overallScore'] as int? ?? 0,
      skillScores: SkillScores(
        vocabulary: skillMap['vocabulary'] as int? ?? 0,
        grammar: skillMap['grammar'] as int? ?? 0,
        listening: skillMap['listening'] as int? ?? 0,
        speaking: skillMap['speaking'] as int? ?? 0,
        reading: skillMap['reading'] as int? ?? 0,
        artikel: skillMap['artikel'] as int? ?? 0,
      ),
      strongAreas: List<String>.from(map['strongAreas'] as List? ?? []),
      weakAreas: List<String>.from(map['weakAreas'] as List? ?? []),
      suggestedLevel: map['suggestedLevel'] as String?,
      suggestedLevelReason: map['suggestedLevelReason'] as String?,
      totalAttempts: map['totalAttempts'] as int? ?? 0,
      totalCorrect: map['totalCorrect'] as int? ?? 0,
      averageSessionScore:
          (map['averageSessionScore'] as num?)?.toDouble() ?? 0.0,
      lastAnalyzedAt: (map['lastAnalyzedAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'overallScore': overallScore,
      'skillScores': {
        'vocabulary': skillScores.vocabulary,
        'grammar': skillScores.grammar,
        'listening': skillScores.listening,
        'speaking': skillScores.speaking,
        'reading': skillScores.reading,
        'artikel': skillScores.artikel,
      },
      'strongAreas': strongAreas,
      'weakAreas': weakAreas,
      'suggestedLevel': suggestedLevel,
      'suggestedLevelReason': suggestedLevelReason,
      'totalAttempts': totalAttempts,
      'totalCorrect': totalCorrect,
      'averageSessionScore': averageSessionScore,
      'lastAnalyzedAt':
          lastAnalyzedAt != null ? Timestamp.fromDate(lastAnalyzedAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LearnerProfileModel.fromEntity(LearnerProfile entity) {
    return LearnerProfileModel(
      userId: entity.userId,
      overallScore: entity.overallScore,
      skillScores: entity.skillScores,
      strongAreas: entity.strongAreas,
      weakAreas: entity.weakAreas,
      suggestedLevel: entity.suggestedLevel,
      suggestedLevelReason: entity.suggestedLevelReason,
      totalAttempts: entity.totalAttempts,
      totalCorrect: entity.totalCorrect,
      averageSessionScore: entity.averageSessionScore,
      lastAnalyzedAt: entity.lastAnalyzedAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Yangi profil yaratish (default qiymatlar bilan)
  factory LearnerProfileModel.initial(String userId) {
    return LearnerProfileModel(
      userId: userId,
      updatedAt: DateTime.now(),
    );
  }
}
