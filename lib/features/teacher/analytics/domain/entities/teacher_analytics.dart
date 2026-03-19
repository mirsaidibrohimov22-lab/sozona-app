// lib/features/teacher/analytics/domain/entities/teacher_analytics.dart
// So'zona — Teacher Analytics Domain Entity
// ✅ YANGI: StudentWeakAreas — har bir o'quvchi uchun zaif soha ma'lumoti
// ✅ YANGI: ClassAnalytics.studentBreakdowns — per-student grafik uchun

import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════
// O'QUVCHI ZAIF SOHALARI
// ═══════════════════════════════════════════════════════════════
class StudentWeakAreas extends Equatable {
  final String userId;
  final String displayName;

  /// Ko'nikma ballari — {'quiz': 72.5, 'speaking': 45.0, ...}
  final Map<String, double> skillScores;

  /// Zaif mavzu nomlari — AI adaptive engine uchun
  final List<String> weakTopics;

  /// So'nggi faollik
  final DateTime? lastActive;

  /// Umumiy o'rtacha ball
  final double avgScore;

  /// Jami mashqlar soni
  final int totalActivities;

  const StudentWeakAreas({
    required this.userId,
    required this.displayName,
    this.skillScores = const {},
    this.weakTopics = const [],
    this.lastActive,
    this.avgScore = 0,
    this.totalActivities = 0,
  });

  /// Eng zaif ko'nikma
  String get weakestSkill {
    if (skillScores.isEmpty) return 'quiz';
    return skillScores.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  /// Eng kuchli ko'nikma
  String get strongestSkill {
    if (skillScores.isEmpty) return 'quiz';
    return skillScores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// O'quvchi qiynalayaptimi? (umumiy ball 60% dan past)
  bool get needsAttention => avgScore < 60;

  /// So'nggi 3 kun ichida faol bo'lganmi
  bool get isRecentlyActive {
    if (lastActive == null) return false;
    return DateTime.now().difference(lastActive!).inDays <= 3;
  }

  @override
  List<Object?> get props => [userId];
}

// ═══════════════════════════════════════════════════════════════
// SINF ANALITIKASI
// ═══════════════════════════════════════════════════════════════
class ClassAnalytics extends Equatable {
  final String classId;
  final String className;
  final int totalStudents;
  final int activeStudents;

  /// O'rtacha ball — 0.0 dan 100.0 gacha
  final double avgScore;

  /// Ko'nikma bo'yicha sinf breakdown — {'quiz': 72.5, 'speaking': 65.0, ...}
  final Map<String, double> skillBreakdown;

  final List<WeeklyActivity> weeklyActivity;
  final List<String> aiRecommendations;
  final DateTime updatedAt;

  /// ✅ YANGI: Har bir o'quvchi uchun zaif soha ma'lumoti
  final List<StudentWeakAreas> studentBreakdowns;

  const ClassAnalytics({
    required this.classId,
    required this.className,
    this.totalStudents = 0,
    this.activeStudents = 0,
    this.avgScore = 0,
    this.skillBreakdown = const {},
    this.weeklyActivity = const [],
    this.aiRecommendations = const [],
    required this.updatedAt,
    this.studentBreakdowns = const [],
  });

  /// Eng ko'p qiynalayotgan o'quvchilar (ball 60% dan past, kamida 1 faollik)
  List<StudentWeakAreas> get strugglingStudents => studentBreakdowns
      .where((s) => s.needsAttention && s.totalActivities > 0)
      .toList()
    ..sort((a, b) => a.avgScore.compareTo(b.avgScore));

  /// Faol o'quvchilar (so'nggi 3 kun)
  List<StudentWeakAreas> get recentlyActiveStudents =>
      studentBreakdowns.where((s) => s.isRecentlyActive).toList();

  @override
  List<Object?> get props => [classId];
}

// ═══════════════════════════════════════════════════════════════
// HAFTALIK FAOLLIK
// ═══════════════════════════════════════════════════════════════
class WeeklyActivity extends Equatable {
  final String week;
  final int attempts;
  final double avgScore;

  const WeeklyActivity({
    required this.week,
    this.attempts = 0,
    this.avgScore = 0,
  });

  @override
  List<Object?> get props => [week];
}
