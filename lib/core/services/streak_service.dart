// lib/core/services/streak_service.dart
// So'zona — Streak yangilash xizmati
// progress/{uid} collectioniga yozadi — users/{uid} ga tegmaydi
// student_home_provider allaqachon progress/{uid} dan o'qiydi

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/providers/firebase_providers.dart';

/// Streak yangilash xizmati
/// Foydalanuvchi app ochganda bir marta chaqiriladi.
/// progress/{uid} ga yozadi — mavjud provider bilan to'liq mos keladi.
class StreakService {
  final FirebaseFirestore _firestore;

  StreakService(this._firestore);

  /// Streak yangilash — app ochilganda chaqiriladi
  /// Bugun allaqachon yangilangan bo'lsa hech narsa qilmaydi (idempotent)
  Future<void> updateStreak(String uid) async {
    if (uid.isEmpty) return;

    try {
      final docRef = _firestore.collection('progress').doc(uid);
      final doc = await docRef.get();

      final now = DateTime.now();
      // Soat/daqiqa olmay — faqat sana taqqoslanadi
      final today = DateTime(now.year, now.month, now.day);

      if (!doc.exists) {
        // Yangi foydalanuvchi — birinchi kun
        await docRef.set({
          'currentStreak': 1,
          'longestStreak': 1,
          'lastActiveDate': Timestamp.fromDate(today),
        }, SetOptions(merge: true));
        // Profil badge uchun users/{uid}/currentStreak yangilanadi
        await _firestore
            .collection('users')
            .doc(uid)
            .set({'currentStreak': 1}, SetOptions(merge: true));
        debugPrint('✅ Streak: Yangi foydalanuvchi — 1-kun');
        return;
      }

      final data = doc.data() ?? {};
      final int currentStreak = _toInt(data['currentStreak']);
      final int longestStreak = _toInt(data['longestStreak']);
      final lastActiveRaw = data['lastActiveDate'];

      // lastActiveDate mavjud emasligini tekshirish
      if (lastActiveRaw == null) {
        await docRef.set({
          'currentStreak': 1,
          'longestStreak': longestStreak < 1 ? 1 : longestStreak,
          'lastActiveDate': Timestamp.fromDate(today),
        }, SetOptions(merge: true));
        // Profil badge uchun users/{uid}/currentStreak yangilanadi
        await _firestore
            .collection('users')
            .doc(uid)
            .set({'currentStreak': 1}, SetOptions(merge: true));
        debugPrint('✅ Streak: lastActiveDate yo\'q edi — 1 dan boshlandi');
        return;
      }

      // lastActiveDate ni sana formatiga o'tkazish (soatsiz)
      final DateTime lastActive;
      if (lastActiveRaw is Timestamp) {
        final d = lastActiveRaw.toDate();
        lastActive = DateTime(d.year, d.month, d.day);
      } else {
        lastActive = today;
      }

      // Bugun allaqachon kirgan — hech narsa o'zgartirma
      if (lastActive == today) {
        debugPrint('ℹ️ Streak: Bugun allaqachon yangilangan — skip');
        return;
      }

      // Streak yangilash mantiq:
      // Kecha kirgan        → streak + 1 (davom etdi)
      // Har o'tkazilgan kun → streak - 2 (minimum 0)
      // Misol: 7 streak, 1 kun o'tkazdi → 7 - 2 = 5
      //        3 streak, 1 kun o'tkazdi → 3 - 2 = 1
      //        1 streak, 1 kun o'tkazdi → max(0, 1-2) = 0
      final yesterday = today.subtract(const Duration(days: 1));
      final daysMissed = today.difference(lastActive).inDays;
      int newStreak;
      if (lastActive == yesterday) {
        // Kecha kirgan — streak davom etadi
        newStreak = currentStreak + 1;
        debugPrint('✅ Streak: Ketma-ket — $newStreak kun');
      } else {
        // O'tkazilgan kunlar * 2 streak kuyadi, minimum 0
        final penalty = daysMissed * 2;
        newStreak = (currentStreak - penalty).clamp(0, currentStreak);
        debugPrint(
            '⚠️ Streak: $daysMissed kun o\'tkazildi, -$penalty jazo → $newStreak streak qoldi');
      }

      // longestStreak ni yangilab borish
      final newLongest = newStreak > longestStreak ? newStreak : longestStreak;

      await docRef.set({
        'currentStreak': newStreak,
        'longestStreak': newLongest,
        'lastActiveDate': Timestamp.fromDate(today),
      }, SetOptions(merge: true));

      // Profil badge uchun users/{uid}/currentStreak ham yangilanadi
      // profile_header.dart users collectiondan o'qiydi
      await _firestore.collection('users').doc(uid).set(
        {'currentStreak': newStreak},
        SetOptions(merge: true),
      );

      debugPrint(
        '✅ Streak saqlandi: current=$newStreak, longest=$newLongest',
      );
    } catch (e) {
      // Xato bo'lsa app ishini to'xtatmaymiz — faqat log
      debugPrint('⚠️ StreakService xatosi: $e');
    }
  }

  /// Yordamchi — dynamic → int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Riverpod provider — student_home_screen da ishlatiladi
final streakServiceProvider = Provider<StreakService>((ref) {
  return StreakService(ref.watch(firestoreProvider));
});
