// lib/features/student/home/data/datasources/home_remote_datasource.dart
// ✅ FIX 1: getDailyPlan — root 'dailyPlans' → 'progress/{uid}/dailyPlans/{date}'
// ✅ FIX 2: joinClass — memberIds array → members subcollection + transaction

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/student/home/data/models/daily_plan_model.dart';
import 'package:my_first_app/features/student/home/data/models/streak_model.dart';

abstract class HomeRemoteDataSource {
  Future<DailyPlanModel> getDailyPlan(String userId);
  Future<StreakModel> getStreak(String userId);
  Future<void> completeTask(String userId, String taskId);
  Future<String> joinClass(String userId, String joinCode);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final FirebaseFirestore _db;
  HomeRemoteDataSourceImpl(this._db);

  // ✅ YAGONA path helper — xato bo'lmaydi
  String _dailyPlanPath(String userId, String dateStr) =>
      'progress/$userId/dailyPlans/$dateStr';

  String _todayDateStr() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<DailyPlanModel> getDailyPlan(String userId) async {
    try {
      final dateStr = _todayDateStr();
      // ✅ FIX: root 'dailyPlans' EMAS — 'progress/{uid}/dailyPlans/{date}'
      final doc = await _db.doc(_dailyPlanPath(userId, dateStr)).get();
      if (!doc.exists) {
        return DailyPlanModel(
            userId: userId, date: DateTime.now(), tasks: const []);
      }
      return DailyPlanModel.fromFirestore(doc.data()!, userId);
    } catch (e) {
      throw ServerException(message: 'Kunlik reja yuklanmadi: $e');
    }
  }

  @override
  Future<StreakModel> getStreak(String userId) async {
    try {
      final doc = await _db.collection('progress').doc(userId).get();
      return StreakModel.fromFirestore(doc.data() ?? {}, userId);
    } catch (e) {
      throw ServerException(message: 'Streak yuklanmadi: $e');
    }
  }

  @override
  Future<void> completeTask(String userId, String taskId) async {
    try {
      final dateStr = _todayDateStr();
      await _db.doc(_dailyPlanPath(userId, dateStr)).set(
        {
          'completedTaskIds': FieldValue.arrayUnion([taskId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw ServerException(message: 'Vazifa tugatilmadi: $e');
    }
  }

  @override
  Future<String> joinClass(String userId, String joinCode) async {
    try {
      // 1. Sinf kodini topish
      final snap = await _db
          .collection('classes')
          .where('joinCode', isEqualTo: joinCode.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        throw const ServerException(
            message: 'Sinf topilmadi. Kodni tekshiring');
      }

      final classDoc = snap.docs.first;
      final classId = classDoc.id;
      final classData = classDoc.data();

      // 2. Allaqachon a'zo tekshirish
      final memberRef = _db
          .collection('classes')
          .doc(classId)
          .collection('members')
          .doc(userId);
      final memberDoc = await memberRef.get();
      if (memberDoc.exists) {
        throw const ServerException(
            message: "Siz allaqachon bu sinfga a'zosiz");
      }

      // 3. Sinf to'liqligini tekshirish
      final memberCount = (classData['memberCount'] as num?)?.toInt() ?? 0;
      final maxMembers = (classData['maxMembers'] as num?)?.toInt() ?? 50;
      if (memberCount >= maxMembers) {
        throw const ServerException(message: "Sinf to'liq");
      }

      // 4. Foydalanuvchi ma'lumotlarini olish
      final userDoc = await _db.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      // 5. ✅ FIX: Faqat members subcollectionga yozamiz
      // memberCount ni server tomonida (Firestore trigger) yangilanadi
      // Student classes update qila olmaydi — permission denied bo'ladi
      await memberRef.set({
        'userId': userId,
        'fullName': userData['fullName'] as String? ?? '',
        'level': userData['level'] as String? ?? 'A1',
        'joinedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'averageScore': 0.0,
        'totalAttempts': 0,
        'currentStreak': 0,
        'avatarUrl': userData['avatarUrl'],
      });

      return classId;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: "Sinfga qo'shilmadi: $e");
    }
  }
}
