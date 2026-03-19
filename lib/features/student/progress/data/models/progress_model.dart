// lib/features/student/progress/data/models/progress_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/student/progress/domain/entities/progress.dart';

class UserProgressModel extends UserProgress {
  const UserProgressModel({
    required super.userId,
    super.totalXp,
    super.currentStreak,
    super.longestStreak,
    super.totalQuizzes,
    super.averageQuizScore,
    super.skillScores,
    super.recentActivity,
    super.weakAreas,
    required super.updatedAt,
  });

  factory UserProgressModel.fromFirestore(Map<String, dynamic> d, String uid) {
    final skills = d['skillScores'] as Map<String, dynamic>? ?? {};
    return UserProgressModel(
      userId: uid,
      totalXp: (d['totalXp'] as num?)?.toInt() ?? 0,
      currentStreak: (d['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (d['longestStreak'] as num?)?.toInt() ?? 0,
      totalQuizzes: (d['totalQuizzes'] as num?)?.toInt() ?? 0,
      averageQuizScore: (d['averageQuizScore'] as num?)?.toDouble() ?? 0.0,
      skillScores: SkillScores(
        quiz: (skills['quiz'] as num?)?.toDouble() ?? 0,
        flashcard: (skills['flashcard'] as num?)?.toDouble() ?? 0,
        listening: (skills['listening'] as num?)?.toDouble() ?? 0,
        speaking: (skills['speaking'] as num?)?.toDouble() ?? 0,
        artikel: (skills['artikel'] as num?)?.toDouble() ?? 0,
      ),
      weakAreas: List<String>.from(d['weakAreas'] ?? []),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
