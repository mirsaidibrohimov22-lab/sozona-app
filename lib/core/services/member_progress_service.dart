// lib/core/services/member_progress_service.dart
// ✅ YANGI: Markaziy member progress yangilash service
//
// MUAMMO:
//   Quiz, Listening, Speaking, Flashcard — har biri submit qilganda
//   classes/{classId}/members/{userId} dagi averageScore yangilanmas edi.
//   Shuning uchun o'qituvchi doim 0% ko'rar edi.
//
// YECHIM:
//   Har qanday mashq tugaganda shu service ni chaqirish yetarli.
//   Service o'zi Firestore dan o'quvchining barcha sinflarini topib,
//   hammasida averageScore, totalAttempts, lastActiveAt ni yangilaydi.
//
// QANDAY ISHLATISH:
//   await MemberProgressService.instance.recordAttempt(
//     userId: userId,
//     scorePercent: 85.0,
//     skillType: 'listening',  // 'quiz' | 'listening' | 'speaking' | 'flashcard'
//   );

import 'package:cloud_firestore/cloud_firestore.dart';

class MemberProgressService {
  MemberProgressService._();
  static final instance = MemberProgressService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Mashq natijasini barcha sinf member hujjatlariga yoz.
  ///
  /// [userId]       — o'quvchi Firebase UID
  /// [scorePercent] — 0–100 oralig'idagi ball
  /// [skillType]    — 'quiz' | 'listening' | 'speaking' | 'flashcard'
  Future<void> recordAttempt({
    required String userId,
    required double scorePercent,
    required String skillType,
  }) async {
    if (userId.isEmpty) return;

    try {
      // 1. O'quvchi qaysi sinflarda ekanligini aniqlaymiz
      final classIds = await _getStudentClassIds(userId);
      if (classIds.isEmpty) return; // Hech bir sinfda emas

      // 2. Har bir sinfda member hujjatini yangilaymiz
      await Future.wait(
        classIds.map((classId) => _updateMember(
              classId: classId,
              userId: userId,
              scorePercent: scorePercent,
            )),
      );
    } catch (e) {
      // Xato butun mashq jarayonini buzmasin
      // ignore: avoid_print
      print('⚠️ MemberProgressService xato: $e');
    }
  }

  /// O'quvchining barcha sinf IDlarini olish.
  ///
  /// Firestore da ikki joy tekshiriladi:
  ///   a) users/{userId}.classIds (massiv maydoni)  — tez
  ///   b) classes collection da teacherId bo'yicha emas,
  ///      members subcollection da userId bo'yicha query  — to'liq
  Future<List<String>> _getStudentClassIds(String userId) async {
    // a) users hujjatida classIds massivi bor bo'lsa — tezkor yo'l
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      final data = userDoc.data();
      if (data != null && data['classIds'] is List) {
        final ids = List<String>.from(data['classIds'] as List);
        if (ids.isNotEmpty) return ids;
      }
    } catch (_) {}

    // b) Fallback: classes/{classId}/members/{userId} ni qidiramiz
    try {
      // ✅ FIX: collectionGroup da FieldPath.documentId() bilan where() ishlamaydi
      // (Android: "invalid document path with odd number of segments")
      // Yechim: barcha members ni olib, clientda filterlash
      final snap = await _db
          .collectionGroup('members')
          .where('userId', isEqualTo: userId)
          .get();

      return snap.docs
          .map((doc) {
            // Path: classes/{classId}/members/{docId}
            return doc.reference.parent.parent?.id ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Bitta sinf member hujjatini yangilash.
  /// O'rtacha ball: ((prevAvg * prevTotal) + newScore) / (prevTotal + 1)
  Future<void> _updateMember({
    required String classId,
    required String userId,
    required double scorePercent,
  }) async {
    final ref = _db
        .collection('classes')
        .doc(classId)
        .collection('members')
        .doc(userId);

    try {
      final snap = await ref.get();
      if (!snap.exists) return; // Bu sinfda a'zo emas

      final data = snap.data() ?? {};
      final prevTotal = (data['totalAttempts'] as int?) ?? 0;
      final prevAvg = (data['averageScore'] as num?)?.toDouble() ?? 0.0;

      final newTotal = prevTotal + 1;
      final newAvg = ((prevAvg * prevTotal) + scorePercent) / newTotal;

      await ref.update({
        'averageScore': double.parse(newAvg.toStringAsFixed(1)),
        'totalAttempts': newTotal,
        'lastActiveAt': Timestamp.now(),
      });
    } catch (_) {
      // Xato — o'tkazib yuboramiz
    }
  }
}
