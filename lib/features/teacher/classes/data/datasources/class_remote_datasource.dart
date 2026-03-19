// QO'YISH: lib/features/teacher/classes/data/datasources/class_remote_datasource.dart
// So'zona — Sinf Firestore DataSource
// Firestore bilan to'g'ridan-to'g'ri muloqot

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/features/teacher/classes/data/models/class_model.dart';
import 'package:my_first_app/features/teacher/classes/data/models/student_summary_model.dart';

/// Sinf remote datasource interfeysi
abstract class ClassRemoteDataSource {
  /// O'qituvchi sinflarini Firestore'dan olish
  Future<List<ClassModel>> getClasses({required String teacherId});

  /// Yangi sinf yaratish
  Future<ClassModel> createClass({
    required String name,
    String? description,
    required String teacherId,
    required String teacherName,
    required String language,
    required String level,
  });

  /// Sinf ma'lumotlarini olish
  Future<ClassModel> getClassById({required String classId});

  /// Sinf ma'lumotlarini yangilash
  Future<ClassModel> updateClass({
    required String classId,
    String? name,
    String? description,
    bool? isActive,
  });

  /// Sinf a'zolari ro'yxatini olish
  Future<List<StudentSummaryModel>> getClassMembers({required String classId});

  /// Join code orqali sinf topish va qo'shilish
  Future<ClassModel> joinClassByCode({
    required String joinCode,
    required String studentId,
    required String studentName,
    required String studentLevel,
  });

  /// O'quvchini sinfdan chiqarish
  Future<void> removeStudentFromClass({
    required String classId,
    required String studentId,
  });

  /// Student qo'shilgan sinflar
  Future<List<ClassModel>> getStudentClasses({required String studentId});
}

/// Firestore implementatsiyasi
class ClassRemoteDataSourceImpl implements ClassRemoteDataSource {
  final FirebaseFirestore _firestore;

  ClassRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // ─── Firestore yo'llari ───
  CollectionReference get _classes => _firestore.collection('classes');

  /// 6 belgili join code generatsiya qilish
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
    required String language,
    required String level,
  }) async {
    try {
      // Join code yaratish — unique bo'lishini tekshirish
      String joinCode = _generateJoinCode();
      bool isUnique = false;
      int attempts = 0;

      while (!isUnique && attempts < 10) {
        final existing = await _classes
            .where('joinCode', isEqualTo: joinCode)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          isUnique = true;
        } else {
          joinCode = _generateJoinCode();
          attempts++;
        }
      }

      final now = DateTime.now();
      final docRef = _classes.doc();

      final model = ClassModel(
        id: docRef.id,
        name: name,
        description: description,
        teacherId: teacherId,
        teacherName: teacherName,
        language: language,
        level: level,
        joinCode: joinCode,
        memberCount: 0,
        maxMembers: 50,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(model.toFirestore());
      return model;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinf yaratib bo\'lmadi',
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
          code: 'NOT_FOUND',
        );
      }

      return ClassModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinf ma\'lumotlari yuklanmadi',
        code: e.code,
      );
    }
  }

  @override
  Future<ClassModel> updateClass({
    required String classId,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (isActive != null) updateData['isActive'] = isActive;

      await _classes.doc(classId).update(updateData);
      return getClassById(classId: classId);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinf yangilanmadi',
        code: e.code,
      );
    }
  }

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

      return snapshot.docs.map(StudentSummaryModel.fromFirestore).toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'A\'zolar yuklanmadi',
        code: e.code,
      );
    }
  }

  @override
  Future<ClassModel> joinClassByCode({
    required String joinCode,
    required String studentId,
    required String studentName,
    required String studentLevel,
  }) async {
    try {
      // Join code bilan sinf topish
      final snapshot = await _classes
          .where('joinCode', isEqualTo: joinCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw const ServerException(
          message: 'Bunday kod bilan sinf topilmadi',
          code: 'CLASS_NOT_FOUND',
        );
      }

      final classDoc = snapshot.docs.first;
      final classModel = ClassModel.fromFirestore(classDoc);

      // Allaqachon a'zo emasligini tekshirish
      final memberDoc = await _classes
          .doc(classModel.id)
          .collection('members')
          .doc(studentId)
          .get();

      if (memberDoc.exists) {
        throw const ServerException(
          message: 'Siz bu sinfga allaqachon a\'zo siz',
          code: 'ALREADY_MEMBER',
        );
      }

      // Sinf to'liq emasligini tekshirish
      if (classModel.isFull) {
        throw const ServerException(
          message: 'Sinf to\'liq. Boshqa sinfga qo\'shiling.',
          code: 'CLASS_FULL',
        );
      }

      // Transaction — atomik operatsiya
      await _firestore.runTransaction((transaction) async {
        final now = DateTime.now();

        // 1. Members subcollection'ga qo'shish
        final memberRef =
            _classes.doc(classModel.id).collection('members').doc(studentId);

        transaction.set(memberRef, {
          'userId': studentId,
          'fullName': studentName,
          'level': studentLevel,
          'joinedAt': Timestamp.fromDate(now),
          'lastActiveAt': Timestamp.fromDate(now),
          'averageScore': 0.0,
          'totalAttempts': 0,
          'currentStreak': 0,
          'avatarUrl': null,
        });

        // 2. memberCount oshirish
        transaction.update(
          _classes.doc(classModel.id),
          {
            'memberCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      // Yangilangan sinf ma'lumotlarini qaytarish
      return getClassById(classId: classModel.id);
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinfga qo\'shib bo\'lmadi',
        code: e.code,
      );
    }
  }

  @override
  Future<void> removeStudentFromClass({
    required String classId,
    required String studentId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Members'dan o'chirish
        final memberRef =
            _classes.doc(classId).collection('members').doc(studentId);
        transaction.delete(memberRef);

        // 2. memberCount kamaytirish
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

  @override
  Future<List<ClassModel>> getStudentClasses({
    required String studentId,
  }) async {
    try {
      // ✅ FIX: collectionGroup ishlatmaymiz — u Firestore da murakkab path talab qiladi
      // Yechim: barcha faol sinflarni olamiz, har birida members/{studentId} borligini tekshiramiz
      // Bu rules bilan to'liq mos: "uid() == memberId" (memberId = studentId)
      final allClassesSnap = await _firestore
          .collection('classes')
          .where('isActive', isEqualTo: true)
          .get();

      final classes = <ClassModel>[];
      for (final classDoc in allClassesSnap.docs) {
        try {
          // Har bir sinfda members/{studentId} document borligini tekshiramiz
          final memberDoc = await _firestore
              .collection('classes')
              .doc(classDoc.id)
              .collection('members')
              .doc(studentId)
              .get();

          if (memberDoc.exists) {
            final model = ClassModel.fromFirestore(classDoc);
            classes.add(model);
          }
        } catch (_) {
          // Bitta sinf yuklanmasa ham davom etadi
        }
      }

      return classes;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Sinflar yuklanmadi',
        code: e.code,
      );
    }
  }
}

/// Provider
final classRemoteDataSourceProvider = Provider<ClassRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ClassRemoteDataSourceImpl(firestore: firestore);
});
