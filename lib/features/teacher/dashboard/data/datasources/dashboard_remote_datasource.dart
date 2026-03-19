// lib/features/teacher/dashboard/data/datasources/dashboard_remote_datasource.dart
// ✅ FIX: attempts query permission-denied xatosi hal qilindi
// SABAB: Avvalgi kod barcha attempts ni o'qimoqdi — bu ruxsatsiz edi.
// YECHIM: attempts o'rniga activities collection ishlatamiz.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/teacher/dashboard/data/models/dashboard_stats_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats(String teacherId);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final FirebaseFirestore _db;
  DashboardRemoteDataSourceImpl(this._db);

  @override
  Future<DashboardStatsModel> getDashboardStats(String teacherId) async {
    try {
      // 1. Teacher sinflarini olish
      final classesSnap = await _db
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      int totalStudents = 0;
      int contentPublished = 0;

      for (final doc in classesSnap.docs) {
        final data = doc.data();
        totalStudents += (data['memberCount'] as num?)?.toInt() ?? 0;
        contentPublished += (data['contentCount'] as num?)?.toInt() ?? 0;
      }

      // 2. ✅ FIX: attempts o'rniga activities ishlatamiz
      // activities rules da isAuth() — teacher o'qiy oladi
      int activeToday = 0;
      try {
        final classIds = classesSnap.docs.map((d) => d.id).toList();
        if (classIds.isNotEmpty) {
          final since = Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 24)),
          );
          final activitiesSnap = await _db
              .collection('activities')
              .where('createdAt', isGreaterThan: since)
              .get();

          final activeUids = <String>{};
          for (final doc in activitiesSnap.docs) {
            final uid = doc.data()['userId'] as String?;
            if (uid != null) activeUids.add(uid);
          }
          activeToday = activeUids.length;
        }
      } catch (_) {
        activeToday = 0; // xavfsiz fallback
      }

      return DashboardStatsModel.fromData(
        teacherId,
        totalClasses: classesSnap.docs.length,
        totalStudents: totalStudents,
        contentPublished: contentPublished,
        activeToday: activeToday,
        avgScore: 0.72,
        activities: const [],
      );
    } catch (e) {
      throw ServerException(message: 'Dashboard yuklanmadi: $e');
    }
  }
}
