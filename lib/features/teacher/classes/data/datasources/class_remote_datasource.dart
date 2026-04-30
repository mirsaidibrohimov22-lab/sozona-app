// lib/features/teacher/classes/data/datasources/class_remote_datasource.dart
// ✅ FIX v2.0: joinClassByCode → Cloud Function orqali (Firestore Rules bypass)
// Sabab: Student classes/{id}/members/ ga to'g'ridan yoza olmaydi (PERMISSION_DENIED)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/features/teacher/classes/data/models/class_model.dart';
import 'package:my_first_app/features/teacher/classes/data/models/student_summary_model.dart';

abstract class ClassRemoteDataSource {
  Future<List<ClassModel>> getClasses({required String teacherId});

  Future<ClassModel> createClass({
    required String name,
    String? description,
    required String teacherId,
    required String teacherName,
    int maxStudents,
    String? language,
    String? level,
  });

  Future<ClassModel> updateClass({
    required String classId,
    String? name,
    String? description,
    int? maxStudents,
    bool? isActive,
  });

  Future<void> deleteClass({required String classId});

  Future<ClassModel> getClassById({required String classId});

  // ✅ Xato 1 tuzatma: getClassMembers abstract methodga qo'shildi
  Future<List<StudentSummaryModel>> getClassMembers({required String classId});

  Future<ClassModel> joinClassByCode({
    required String joinCode,
    required String studentId,
    required String studentName,
    required String studentLevel,
  });

  Future<void> removeStudentFromClass({
    required String classId,
    required String studentId,
  });

  Future<List<ClassModel>> getStudentClasses({required String studentId});
}

class ClassRemoteDataSourceImpl implements ClassRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  ClassRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  CollectionReference get _classes => _firestore.collection('classes');

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(
      List.generate(
        6,
        (i) => chars.codeUnitAt((random ~/ (i + 1)) % chars.length),
      ),
    );
  }

  @override
  Future<List<ClassModel>> getClasses({required String teacherId}) async {
    try {
      final snapshot = await _classes
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(ClassModel.fromFirestore).toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinflar yuklanmadi',
        code: e.code,
      );
    }
  }

  @override
  Future<ClassModel> createClass({
    required String name,
    String? description,
    required String teacherId,
    required String teacherName,
    int maxStudents = 50,
    String? language,
    String? level,
  }) async {
    try {
      String joinCode = _generateJoinCode();

      // Join code unikal bo'lishini ta'minlash
      bool isUnique = false;
      while (!isUnique) {
        final existing = await _classes
            .where('joinCode', isEqualTo: joinCode)
            .limit(1)
            .get();
        if (existing.docs.isEmpty) {
          isUnique = true;
        } else {
          joinCode = _generateJoinCode();
        }
      }

      final docRef = await _classes.add({
        'name': name,
        'description': description ?? '',
        'teacherId': teacherId,
        'teacherName': teacherName,
        'joinCode': joinCode,
        'memberCount': 0,
        'maxStudents': maxStudents,
        'isActive': true,
        'language': language ?? 'english',
        'level': level ?? 'A1',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await getClassById(classId: docRef.id);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinf yaratib bo\'lmadi',
        code: e.code,
      );
    }
  }

  @override
  Future<ClassModel> updateClass({
    required String classId,
    String? name,
    String? description,
    int? maxStudents,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (maxStudents != null) updateData['maxStudents'] = maxStudents;
      if (isActive != null) updateData['isActive'] = isActive;

      await _classes.doc(classId).update(updateData);
      return await getClassById(classId: classId);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinf yangilanmadi',
        code: e.code,
      );
    }
  }

  @override
  Future<void> deleteClass({required String classId}) async {
    try {
      await _classes.doc(classId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinf o\'chirilmadi',
        code: e.code,
      );
    }
  }

  @override
  Future<ClassModel> getClassById({required String classId}) async {
    try {
      final doc = await _classes.doc(classId).get();
      if (!doc.exists) {
        throw const ServerException(
          message: 'Sinf topilmadi',
          code: 'CLASS_NOT_FOUND',
        );
      }
      return ClassModel.fromFirestore(doc);
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinf topilmadi',
        code: e.code,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ FIX: joinClassByCode → Cloud Function orqali
  // Avval to'g'ridan Firestore ga yozardi → PERMISSION_DENIED xatosi
  // Endi Cloud Function (admin huquqlari) orqali yozadi → ishlaydi
  // ═══════════════════════════════════════════════════════════════
  @override
  Future<ClassModel> joinClassByCode({
    required String joinCode,
    required String studentId,
    required String studentName,
    required String studentLevel,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'joinClassByCode',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 15),
        ),
      );

      final result = await callable.call({
        'joinCode': joinCode.toUpperCase().trim(),
        'studentName': studentName,
        'studentLevel': studentLevel,
      });

      final data = result.data as Map<String, dynamic>;
      final classId = data['classId'] as String;

      // Sinf ma'lumotlarini Firestore dan to'liq olish
      return await getClassById(classId: classId);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('⚠️ joinClass Functions xatosi: ${e.code} — ${e.message}');
      // Xato kodini o'zbek tiliga tarjima
      final message = _translateFunctionsError(e.code, e.message);
      throw ServerException(message: message, code: e.code);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinfga qo\'shib bo\'lmadi',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Sinfga qo\'shib bo\'lmadi: $e');
    }
  }

  String _translateFunctionsError(String code, String? message) {
    switch (code) {
      case 'not-found':
        return 'Bunday kod bilan sinf topilmadi';
      case 'already-exists':
        return 'Siz bu sinfga allaqachon a\'zo siz';
      case 'resource-exhausted':
        return 'Sinf to\'liq. Boshqa sinfga qo\'shiling.';
      case 'unauthenticated':
        return 'Tizimga kirish kerak';
      case 'invalid-argument':
        return 'Kod 6 ta belgidan iborat bo\'lishi kerak';
      default:
        return message ?? 'Sinfga qo\'shib bo\'lmadi';
    }
  }

  @override
  Future<void> removeStudentFromClass({
    required String classId,
    required String studentId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final memberRef =
            _classes.doc(classId).collection('members').doc(studentId);
        transaction.delete(memberRef);

        transaction.update(
          _classes.doc(classId),
          {
            'memberCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'O\'quvchi chiqarib bo\'lmadi',
        code: e.code,
      );
    }
  }

  // ✅ Xato 1 tuzatma: getClassMembers implementatsiyasi qo'shildi
  @override
  Future<List<StudentSummaryModel>> getClassMembers({
    required String classId,
  }) async {
    try {
      final snapshot = await _classes
          .doc(classId)
          .collection('members')
          .orderBy('joinedAt', descending: false)
          .get();

      if (snapshot.docs.isEmpty) return [];

      final memberIds = snapshot.docs.map((d) => d.id).toList();

      // ✅ YANGI: activities dan real statistika (members doc stale bo'lishi mumkin)
      final since = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 90)),
      );

      final activityMap = <String, List<Map<String, dynamic>>>{};
      const batchSize = 30;
      for (int i = 0; i < memberIds.length; i += batchSize) {
        final batch = memberIds.skip(i).take(batchSize).toList();
        try {
          final actSnap = await _firestore
              .collection('activities')
              .where('userId', whereIn: batch)
              .where('timestamp', isGreaterThan: since)
              .get();
          for (final doc in actSnap.docs) {
            final data = doc.data();
            final uid = data['userId'] as String? ?? '';
            activityMap.putIfAbsent(uid, () => []).add(data);
          }
        } catch (_) {}
      }

      // Progress collectiondan streak
      final progressMap = <String, int>{};
      await Future.wait(memberIds.map((uid) async {
        try {
          final pDoc = await _firestore.collection('progress').doc(uid).get();
          if (pDoc.exists) {
            progressMap[uid] =
                (pDoc.data()?['currentStreak'] as num?)?.toInt() ?? 0;
          }
        } catch (_) {}
      }));

      return snapshot.docs.map((doc) {
        final base = StudentSummaryModel.fromFirestore(doc);
        final acts = activityMap[doc.id] ?? [];

        if (acts.isEmpty) {
          // activities yo'q — members docdan kelgan qiymatlar
          return StudentSummaryModel(
            userId: base.userId,
            fullName: base.fullName,
            level: base.level,
            joinedAt: base.joinedAt,
            lastActiveAt: base.lastActiveAt,
            averageScore: base.averageScore,
            totalAttempts: base.totalAttempts,
            currentStreak: progressMap[doc.id] ?? base.currentStreak,
            avatarUrl: base.avatarUrl,
            skillScores: base.skillScores,
          );
        }

        // activities dan real statistika hisoblash
        final totalAttempts = acts.length;
        final avgScore = acts.fold<double>(
                0,
                (sum, a) =>
                    sum + ((a['scorePercent'] as num?)?.toDouble() ?? 0)) /
            totalAttempts;

        final skillMap = <String, List<double>>{
          'quiz': [],
          'listening': [],
          'speaking': [],
          'flashcard': [],
        };
        for (final a in acts) {
          final skill = a['skillType'] as String? ?? '';
          final score = (a['scorePercent'] as num?)?.toDouble() ?? 0;
          if (skillMap.containsKey(skill)) skillMap[skill]!.add(score);
        }

        double skillAvg(List<double> list) =>
            list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;

        return StudentSummaryModel(
          userId: base.userId,
          fullName: base.fullName,
          level: base.level,
          joinedAt: base.joinedAt,
          lastActiveAt: base.lastActiveAt,
          averageScore: double.parse(avgScore.toStringAsFixed(1)),
          totalAttempts: totalAttempts,
          currentStreak: progressMap[doc.id] ?? base.currentStreak,
          avatarUrl: base.avatarUrl,
          skillScores: {
            'quiz':
                double.parse(skillAvg(skillMap['quiz']!).toStringAsFixed(1)),
            'listening': double.parse(
                skillAvg(skillMap['listening']!).toStringAsFixed(1)),
            'speaking': double.parse(
                skillAvg(skillMap['speaking']!).toStringAsFixed(1)),
            'flashcard': double.parse(
                skillAvg(skillMap['flashcard']!).toStringAsFixed(1)),
          },
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'A\'zolar yuklanmadi',
        code: e.code,
      );
    }
  }

  @override
  Future<List<ClassModel>> getStudentClasses(
      {required String studentId}) async {
    try {
      final allClassesSnap =
          await _classes.where('isActive', isEqualTo: true).get();

      final studentClasses = <ClassModel>[];

      for (final classDoc in allClassesSnap.docs) {
        final memberDoc = await _classes
            .doc(classDoc.id)
            .collection('members')
            .doc(studentId)
            .get();

        if (memberDoc.exists) {
          studentClasses.add(ClassModel.fromFirestore(classDoc));
        }
      }

      return studentClasses;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinflar yuklanmadi',
        code: e.code,
      );
    }
  }
}

// ✅ Xato 2 tuzatma: classRemoteDataSourceProvider qo'shildi
final classRemoteDataSourceProvider = Provider<ClassRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ClassRemoteDataSourceImpl(firestore: firestore);
});
