// lib/features/teacher/dashboard/presentation/providers/teacher_activity_chart_provider.dart
// ✅ YANGI: Teacher dashboard uchun o'quvchi faollik grafigi provider
// Kunlik/haftalik/oylik/yillik ma'lumotlarni activities collectiondan oladi

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Grafik davri ───
enum TeacherChartPeriod { daily, weekly, monthly, yearly }

extension TeacherChartPeriodLabel on TeacherChartPeriod {
  String get label {
    switch (this) {
      case TeacherChartPeriod.daily:
        return 'Kunlik';
      case TeacherChartPeriod.weekly:
        return 'Haftalik';
      case TeacherChartPeriod.monthly:
        return 'Oylik';
      case TeacherChartPeriod.yearly:
        return 'Yillik';
    }
  }
}

// ─── Bir nuqta (bar) uchun ma'lumot ───
class TeacherChartPoint {
  final String label;
  final int activeStudents; // faol o'quvchilar soni
  final int totalActivities; // jami mashqlar
  final double avgScore; // o'rtacha ball

  const TeacherChartPoint({
    required this.label,
    this.activeStudents = 0,
    this.totalActivities = 0,
    this.avgScore = 0,
  });
}

// ─── Provider parametrlari ───
typedef TeacherChartParams = ({
  String teacherId,
  List<String> classIds,
  TeacherChartPeriod period,
});

// ─── Chart Provider ───
final teacherActivityChartProvider =
    FutureProvider.family<List<TeacherChartPoint>, TeacherChartParams>(
  (ref, params) async {
    if (params.classIds.isEmpty) return [];

    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final List<TeacherChartPoint> points = [];

    // O'quvchi IDlarini class memberlardan olish
    final studentIds = await _getStudentIds(db, params.classIds);
    if (studentIds.isEmpty) return [];

    switch (params.period) {
      // ── Kunlik: so'nggi 7 kun ──
      case TeacherChartPeriod.daily:
        final weekdays = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          final dayStart = DateTime(day.year, day.month, day.day);
          final dayEnd = dayStart.add(const Duration(days: 1));

          final p = await _queryPeriod(db, studentIds, dayStart, dayEnd);
          points.add(TeacherChartPoint(
            label: weekdays[day.weekday - 1],
            activeStudents: p.activeStudents,
            totalActivities: p.totalActivities,
            avgScore: p.avgScore,
          ));
        }
        break;

      // ── Haftalik: so'nggi 4 hafta ──
      case TeacherChartPeriod.weekly:
        for (int i = 3; i >= 0; i--) {
          final weekStart = now.subtract(
            Duration(days: now.weekday - 1 + i * 7),
          );
          final wStart =
              DateTime(weekStart.year, weekStart.month, weekStart.day);
          final wEnd = wStart.add(const Duration(days: 7));

          final p = await _queryPeriod(db, studentIds, wStart, wEnd);
          points.add(TeacherChartPoint(
            label: '${4 - i}-h',
            activeStudents: p.activeStudents,
            totalActivities: p.totalActivities,
            avgScore: p.avgScore,
          ));
        }
        break;

      // ── Oylik: so'nggi 6 oy ──
      case TeacherChartPeriod.monthly:
        const monthNames = [
          'Yan',
          'Fev',
          'Mar',
          'Apr',
          'May',
          'Iyn',
          'Iyl',
          'Avg',
          'Sen',
          'Okt',
          'Noy',
          'Dek'
        ];
        for (int i = 5; i >= 0; i--) {
          int month = now.month - i;
          int year = now.year;
          while (month <= 0) {
            month += 12;
            year--;
          }
          int nextM = month + 1, nextY = year;
          if (nextM > 12) {
            nextM = 1;
            nextY++;
          }

          final p = await _queryPeriod(
            db,
            studentIds,
            DateTime(year, month, 1),
            DateTime(nextY, nextM, 1),
          );
          points.add(TeacherChartPoint(
            label: monthNames[month - 1],
            activeStudents: p.activeStudents,
            totalActivities: p.totalActivities,
            avgScore: p.avgScore,
          ));
        }
        break;

      // ── Yillik: so'nggi 3 yil ──
      case TeacherChartPeriod.yearly:
        for (int i = 2; i >= 0; i--) {
          final year = now.year - i;
          final p = await _queryPeriod(
            db,
            studentIds,
            DateTime(year, 1, 1),
            DateTime(year + 1, 1, 1),
          );
          points.add(TeacherChartPoint(
            label: '$year',
            activeStudents: p.activeStudents,
            totalActivities: p.totalActivities,
            avgScore: p.avgScore,
          ));
        }
        break;
    }

    return points;
  },
);

// ─── Yordamchi: sinf o'quvchilarini olish ───
Future<List<String>> _getStudentIds(
  FirebaseFirestore db,
  List<String> classIds,
) async {
  final ids = <String>{};
  for (final classId in classIds) {
    try {
      final snap = await db
          .collection('classes')
          .doc(classId)
          .collection('members')
          .get();
      for (final doc in snap.docs) {
        ids.add(doc.id);
      }
    } catch (_) {}
  }
  return ids.toList();
}

// ─── Yordamchi: davr uchun aggregatsiya ───
class _PeriodStats {
  final int activeStudents;
  final int totalActivities;
  final double avgScore;
  const _PeriodStats({
    this.activeStudents = 0,
    this.totalActivities = 0,
    this.avgScore = 0,
  });
}

Future<_PeriodStats> _queryPeriod(
  FirebaseFirestore db,
  List<String> studentIds,
  DateTime from,
  DateTime to,
) async {
  // Firestore IN operatori max 30 ta element qabul qiladi
  // Shuning uchun batch larda so'raymiz
  final activeIds = <String>{};
  double totalScore = 0;
  int totalActs = 0;

  final batches = <List<String>>[];
  for (int i = 0; i < studentIds.length; i += 30) {
    batches.add(studentIds.sublist(
      i,
      i + 30 > studentIds.length ? studentIds.length : i + 30,
    ));
  }

  for (final batch in batches) {
    try {
      final snap = await db
          .collection('activities')
          .where('userId', whereIn: batch)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('timestamp', isLessThan: Timestamp.fromDate(to))
          .get();

      for (final doc in snap.docs) {
        final d = doc.data();
        final uid = d['userId'] as String?;
        if (uid != null) activeIds.add(uid);
        totalScore += (d['scorePercent'] as num?)?.toDouble() ?? 0;
        totalActs++;
      }
    } catch (_) {}
  }

  return _PeriodStats(
    activeStudents: activeIds.length,
    totalActivities: totalActs,
    avgScore: totalActs > 0 ? totalScore / totalActs : 0,
  );
}

// ─── Oxirgi faollik (real-time, activities collectiondan) ───
final teacherRecentActivityProvider = FutureProvider.family<
    List<Map<String, dynamic>>, ({String teacherId, List<String> classIds})>(
  (ref, params) async {
    if (params.classIds.isEmpty) return [];

    final db = FirebaseFirestore.instance;
    final studentIds = await _getStudentIds(db, params.classIds);
    if (studentIds.isEmpty) return [];

    final results = <Map<String, dynamic>>[];

    // Max 30 ta o'quvchi uchun so'rov
    final chunk = studentIds.take(30).toList();
    try {
      final snap = await db
          .collection('activities')
          .where('userId', whereIn: chunk)
          .orderBy('timestamp', descending: true)
          .limit(15)
          .get();

      for (final doc in snap.docs) {
        final d = doc.data();
        // O'quvchi ismini members dan olish (cached yoki default)
        results.add(d);
      }
    } catch (_) {}

    return results;
  },
);
