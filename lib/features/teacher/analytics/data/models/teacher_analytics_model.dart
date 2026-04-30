// lib/features/teacher/analytics/data/models/teacher_analytics_model.dart
// So'zona — Teacher Analytics Model
// ✅ YANGI: studentBreakdowns — har bir o'quvchi zaif sohalari
// ✅ FIX: avgScore allaqachon 0–100, *100 kerak emas
// ✅ FIX: attempts → percentage, activities → scorePercent

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/teacher/analytics/domain/entities/teacher_analytics.dart';

class ClassAnalyticsModel extends ClassAnalytics {
  const ClassAnalyticsModel({
    required super.classId,
    required super.className,
    super.totalStudents,
    super.activeStudents,
    super.avgScore,
    super.skillBreakdown,
    super.weeklyActivity,
    super.aiRecommendations,
    required super.updatedAt,
    super.studentBreakdowns,
  });

  /// [attempts]  — 'attempts' koleksiyasidan (quiz natijalari)
  ///   Maydonlar: userId, percentage (0–100), contentType, createdAt
  ///
  /// [activities] — 'activities' koleksiyasidan (speaking, listening, flashcard)
  ///   Maydonlar: userId, scorePercent (0–100), skillType, timestamp
  ///
  /// [memberNames] — members subcollectiondan olingan userId → displayName map
  factory ClassAnalyticsModel.fromData({
    required String classId,
    required String className,
    required List<Map<String, dynamic>> attempts,
    required List<Map<String, dynamic>> activities,
    required int totalStudents,
    Map<String, String> memberNames = const {},
  }) {
    final now = DateTime.now();
    final since24h =
        now.subtract(const Duration(days: 7)); // 7 kun ichida aktiv bo'lganlar

    final activeSet = <String>{};
    final allScores = <double>[];

    // O'quvchi bo'yicha ma'lumotlar
    final studentSkills = <String, Map<String, List<double>>>{};
    final studentTopics = <String, Set<String>>{};
    final studentLastActive = <String, DateTime>{};
    final studentActivitiesCount = <String, int>{};

    final classSkillMap = <String, List<double>>{
      'quiz': [],
      'speaking': [],
      'listening': [],
      'flashcard': [],
    };

    // ── ATTEMPTS (quiz natijalari) ──
    for (final a in attempts) {
      final pct = (a['percentage'] as num?)?.toDouble() ?? 0.0;
      final uid = a['userId'] as String? ?? '';
      final ts = (a['createdAt'] as Timestamp?)?.toDate();

      if (uid.isEmpty) continue;

      if (ts != null && ts.isAfter(since24h)) activeSet.add(uid);
      allScores.add(pct);

      final type = _normalizeType(a['contentType'] as String? ?? 'quiz');
      classSkillMap.putIfAbsent(type, () => []).add(pct);

      // Per-student
      _addStudentScore(studentSkills, uid, type, pct);
      studentActivitiesCount[uid] = (studentActivitiesCount[uid] ?? 0) + 1;
      if (ts != null) {
        final existing = studentLastActive[uid];
        if (existing == null || ts.isAfter(existing)) {
          studentLastActive[uid] = ts;
        }
      }

      // Zaif mavzu — 60 dan past bo'lsa
      if (pct < 60) {
        final topic = a['contentTitle'] as String? ?? '';
        if (topic.isNotEmpty) {
          studentTopics.putIfAbsent(uid, () => {}).add(topic);
        }
      }
    }

    // ── ACTIVITIES (speaking, listening, flashcard) ──
    for (final a in activities) {
      final pct = (a['scorePercent'] as num?)?.toDouble() ?? 0.0;
      final uid = a['userId'] as String? ?? '';
      final ts = (a['timestamp'] as Timestamp?)?.toDate();

      if (uid.isEmpty) continue;

      if (ts != null && ts.isAfter(since24h)) activeSet.add(uid);
      allScores.add(pct);

      final type = _normalizeType(a['skillType'] as String? ?? 'quiz');
      classSkillMap.putIfAbsent(type, () => []).add(pct);

      // Per-student
      _addStudentScore(studentSkills, uid, type, pct);
      studentActivitiesCount[uid] = (studentActivitiesCount[uid] ?? 0) + 1;
      if (ts != null) {
        final existing = studentLastActive[uid];
        if (existing == null || ts.isAfter(existing)) {
          studentLastActive[uid] = ts;
        }
      }

      // Zaif mavzu
      if (pct < 60) {
        final topic = a['topic'] as String? ?? '';
        if (topic.isNotEmpty) {
          studentTopics.putIfAbsent(uid, () => {}).add(topic);
        }
      }
    }

    // Sinf umumiy
    final avg = allScores.isEmpty
        ? 0.0
        : allScores.reduce((a, b) => a + b) / allScores.length;

    final skillBreakdown = <String, double>{};
    for (final entry in classSkillMap.entries) {
      if (entry.value.isNotEmpty) {
        skillBreakdown[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    // ── PER-STUDENT BREAKDOWNS ──
    final studentBreakdowns = <StudentWeakAreas>[];
    final allStudentIds = <String>{
      ...studentSkills.keys,
      ...memberNames.keys,
    };

    for (final uid in allStudentIds) {
      final skills = studentSkills[uid] ?? {};
      final scores = <String, double>{};

      for (final entry in skills.entries) {
        if (entry.value.isNotEmpty) {
          scores[entry.key] =
              entry.value.reduce((a, b) => a + b) / entry.value.length;
        }
      }

      // Umumiy ball
      final allStudentScores = skills.values.expand((l) => l).toList();
      final studentAvg = allStudentScores.isEmpty
          ? 0.0
          : allStudentScores.reduce((a, b) => a + b) / allStudentScores.length;

      studentBreakdowns.add(StudentWeakAreas(
        userId: uid,
        displayName: memberNames[uid] ?? _shortId(uid),
        skillScores: scores,
        weakTopics: studentTopics[uid]?.take(3).toList() ?? [],
        lastActive: studentLastActive[uid],
        avgScore: studentAvg,
        totalActivities: studentActivitiesCount[uid] ?? 0,
      ));
    }

    // Ball bo'yicha tartiblash (pastdan yuqoriga — eng ko'p qiynalaganlar birinchi)
    studentBreakdowns.sort((a, b) => a.avgScore.compareTo(b.avgScore));

    return ClassAnalyticsModel(
      classId: classId,
      className: className,
      totalStudents: totalStudents,
      activeStudents: activeSet.length,
      avgScore: avg,
      skillBreakdown: skillBreakdown,
      weeklyActivity: const [],
      aiRecommendations:
          _buildRecommendations(avg, skillBreakdown, studentBreakdowns),
      updatedAt: now,
      studentBreakdowns: studentBreakdowns,
    );
  }

  static void _addStudentScore(
    Map<String, Map<String, List<double>>> map,
    String uid,
    String skill,
    double score,
  ) {
    map.putIfAbsent(uid, () => {});
    map[uid]!.putIfAbsent(skill, () => []).add(score);
  }

  static String _shortId(String uid) {
    if (uid.length <= 8) return uid;
    return 'O\'quvchi ${uid.substring(0, 6)}';
  }

  static String _normalizeType(String raw) {
    switch (raw.toLowerCase()) {
      case 'speaking':
        return 'speaking';
      case 'listening':
        return 'listening';
      case 'flashcard':
        return 'flashcard';
      default:
        return 'quiz';
    }
  }

  static List<String> _buildRecommendations(
    double avg,
    Map<String, double> skills,
    List<StudentWeakAreas> students,
  ) {
    final recs = <String>[];

    if (avg < 50) {
      recs.add('O\'quvchilar qiynalmoqda — dars sur\'atini sekinlashtiring');
      recs.add('Qo\'shimcha tushuntirish va mashq kerak');
    } else if (avg < 70) {
      recs.add('O\'rtacha natija — zaif joylarga e\'tibor bering');
    } else {
      recs.add('Ajoyib natijalar! Murakkablikni oshirishni ko\'ring');
    }

    // Zaif ko'nikma tavsiyasi
    String? weakSkill;
    double weakScore = 101;
    skills.forEach((skill, score) {
      if (score < weakScore) {
        weakScore = score;
        weakSkill = skill;
      }
    });
    if (weakSkill != null && weakScore < 60) {
      final name = _skillName(weakSkill!);
      recs.add(
          '$name ko\'nikmasi zaif (${weakScore.round()}%) — ko\'proq mashq kerak');
    }

    // Qiynalayotgan o'quvchilar
    final struggling = students.where((s) => s.needsAttention).length;
    if (struggling > 0) {
      recs.add('$struggling o\'quvchi qiynalmoqda — alohida e\'tibor bering');
    }

    return recs;
  }

  static String _skillName(String skill) {
    switch (skill) {
      case 'speaking':
        return 'Gapirish';
      case 'listening':
        return 'Tinglash';
      case 'flashcard':
        return 'Lug\'at';
      default:
        return 'Grammatika/Quiz';
    }
  }
}
