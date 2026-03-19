// lib/features/teacher/analytics/data/datasources/teacher_analytics_remote_datasource.dart
// So'zona — Teacher Analytics Remote DataSource
// ✅ YANGI: memberNames — users koleksiyasidan o'quvchi ismlari olinadi
// ✅ FIX: Speaking/Listening ham ko'rinadi (attempts + activities)
// ✅ FIX: Firestore whereIn max 30 ta — batch query

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/teacher/analytics/data/models/teacher_analytics_model.dart';

abstract class TeacherAnalyticsRemoteDataSource {
  Future<ClassAnalyticsModel> getClassAnalytics(String classId);
}

class TeacherAnalyticsRemoteDataSourceImpl
    implements TeacherAnalyticsRemoteDataSource {
  final FirebaseFirestore _db;
  TeacherAnalyticsRemoteDataSourceImpl(this._db);

  @override
  Future<ClassAnalyticsModel> getClassAnalytics(String classId) async {
    if (classId.isEmpty) {
      throw const ServerException(
        message: "classId bo'sh bo'lishi mumkin emas",
        code: 'INVALID_ARGUMENT',
      );
    }

    try {
      // 1. Sinf ma'lumotlari
      final classDoc = await _db.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        throw const ServerException(
          message: 'Sinf topilmadi',
          code: 'NOT_FOUND',
        );
      }
      final classData = classDoc.data() ?? {};

      // 2. O'quvchilar ro'yxati (members subcollection)
      final membersSnap = await _db
          .collection('classes')
          .doc(classId)
          .collection('members')
          .get();
      final totalStudents = membersSnap.docs.length;
      final memberIds = membersSnap.docs.map((d) => d.id).toList();

      // 3. O'quvchi ismlari — parallel fetch
      final memberNames = await _fetchMemberNames(memberIds);

      // 4. So'nggi 30 kun
      final since = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 30)),
      );

      // 5. Quiz natijalari — attempts koleksiyasi (classId bo'yicha)
      final attemptsSnap = await _db
          .collection('attempts')
          .where('classId', isEqualTo: classId)
          .where('createdAt', isGreaterThan: since)
          .get();
      final attempts = attemptsSnap.docs.map((d) => d.data()).toList();

      // 6. Speaking/Listening/Flashcard — activities koleksiyasi
      final activities = await _fetchActivitiesByMembers(
        memberIds: memberIds,
        since: since,
      );

      debugPrint(
        '📊 Analytics: ${attempts.length} quiz attempt, '
        '${activities.length} activity, $totalStudents o\'quvchi, '
        '${memberNames.length} ism topildi',
      );

      return ClassAnalyticsModel.fromData(
        classId: classId,
        className: classData['name'] as String? ?? 'Sinf',
        attempts: attempts,
        activities: activities,
        totalStudents: totalStudents,
        memberNames: memberNames,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Analitika yuklanmadi: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // O'QUVCHI ISMLARI — users koleksiyasidan
  // ═══════════════════════════════════════════════════════════════
  Future<Map<String, String>> _fetchMemberNames(List<String> memberIds) async {
    if (memberIds.isEmpty) return {};

    final names = <String, String>{};
    const batchSize = 30;

    for (int i = 0; i < memberIds.length; i += batchSize) {
      final batch = memberIds.skip(i).take(batchSize).toList();
      try {
        final snaps = await Future.wait(
          batch.map((uid) => _db.collection('users').doc(uid).get()),
        );
        for (final doc in snaps) {
          if (!doc.exists) continue;
          final data = doc.data();
          if (data == null) continue;

          // displayName → name → email (birinchi topilgani)
          final name = (data['displayName'] as String?)?.trim() ??
              (data['name'] as String?)?.trim() ??
              (data['fullName'] as String?)?.trim() ??
              _emailToName(data['email'] as String?) ??
              'O\'quvchi ${doc.id.substring(0, 6)}';

          names[doc.id] = name;
        }
      } catch (e) {
        // Ism yuklanmasa — userId qisqartiriladi (quyida fallback)
        debugPrint('⚠️ Member names batch xatosi: $e');
      }
    }

    return names;
  }

  String? _emailToName(String? email) {
    if (email == null || email.isEmpty) return null;
    final local = email.split('@').first;
    // ali.valiyev → Ali Valiyev
    return local
        .split(RegExp(r'[._]'))
        .map((p) => p.isNotEmpty ? '${p[0].toUpperCase()}${p.substring(1)}' : p)
        .join(' ');
  }

  // ═══════════════════════════════════════════════════════════════
  // FAOLLIKLAR — activities koleksiyasidan
  // ═══════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> _fetchActivitiesByMembers({
    required List<String> memberIds,
    required Timestamp since,
  }) async {
    if (memberIds.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    const batchSize = 30;

    for (int i = 0; i < memberIds.length; i += batchSize) {
      final batch = memberIds.skip(i).take(batchSize).toList();
      try {
        final snap = await _db
            .collection('activities')
            .where('userId', whereIn: batch)
            .where('timestamp', isGreaterThan: since)
            .get();
        results.addAll(snap.docs.map((d) => d.data()));
      } catch (e) {
        debugPrint('⚠️ Activities batch xatosi: $e');
      }
    }

    return results;
  }
}
