// lib/core/services/daily_box_service.dart
// So'zona — Kundalik sirpriz quti xizmati
//
// LOGIKA:
//   progress/{uid} — lastBoxOpenDate, totalXp, badges
//   users/{uid}    — premiumExpiresAt (faqat premiumDay mukofotida)
//
// CHAQIRISH:
//   final svc = ref.read(dailyBoxServiceProvider);
//   final canOpen = await svc.canOpenToday(uid);
//   final reward  = await svc.openBox(uid);

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/providers/firebase_providers.dart';

// ═══════════════════════════════════════════════════════════════
// MUKOFOT TURLARI
// ═══════════════════════════════════════════════════════════════

enum DailyRewardType {
  xp50, // 40% — 50 XP
  xp100, // 20% — 100 XP
  premiumDay, // 10% — 1 kun premium
  badge, // 10% — 'lucky_star' badge
  nothing, // 20% — ertaga qaytib keling
}

class DailyReward {
  final DailyRewardType type;

  const DailyReward(this.type);

  /// Foydalanuvchiga ko'rsatiladigan xabar
  String get message {
    return switch (type) {
      DailyRewardType.xp50 => '🎉 50 XP yutdingiz!',
      DailyRewardType.xp100 => '🎉 100 XP yutdingiz!',
      DailyRewardType.premiumDay => '🎁 1 kun bepul premium!',
      DailyRewardType.badge => '🏅 "Omadli Yulduz" badge!',
      DailyRewardType.nothing => '🌟 Ertaga katta sovg\'a kutmoqda...',
    };
  }

  /// Emoji — widget markazida ko'rsatiladi
  String get emoji {
    return switch (type) {
      DailyRewardType.xp50 => '⭐',
      DailyRewardType.xp100 => '🌟',
      DailyRewardType.premiumDay => '👑',
      DailyRewardType.badge => '🏅',
      DailyRewardType.nothing => '🎀',
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// XIZMAT
// ═══════════════════════════════════════════════════════════════

class DailyBoxService {
  final FirebaseFirestore _firestore;

  DailyBoxService(this._firestore);

  // ─────────────────────────────────────────────────────────────
  // canOpenToday — bugun quti ochilganmi tekshirish
  // ─────────────────────────────────────────────────────────────
  Future<bool> canOpenToday(String uid) async {
    if (uid.isEmpty) return false;

    try {
      final doc = await _firestore.collection('progress').doc(uid).get();
      if (!doc.exists) return true; // Yangi foydalanuvchi — ocha oladi

      final raw = doc.data()?['lastBoxOpenDate'];
      if (raw == null) return true; // Hali hech ochilmagan

      if (raw is! Timestamp) return true;

      final last = raw.toDate();
      final now = DateTime.now();

      // Bugunning sanasi bilan taqqoslaymiz (soat muhim emas)
      final lastDate = DateTime(last.year, last.month, last.day);
      final today = DateTime(now.year, now.month, now.day);

      return lastDate.isBefore(today); // Bugun ochilmagan → true
    } catch (e) {
      return false; // Xato bo'lsa — ochirmaylik
    }
  }

  // ─────────────────────────────────────────────────────────────
  // openBox — Cloud Function orqali xavfsiz mukofot berish
  // Server tomonida: mukofot tanlash + Firestore yozish
  // ─────────────────────────────────────────────────────────────
  Future<DailyReward> openBox(String uid) async {
    if (uid.isEmpty) return const DailyReward(DailyRewardType.nothing);

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('claimDailyReward');
      final result = await callable.call<Map<String, dynamic>>();
      final rewardType = result.data['rewardType'] as String? ?? 'nothing';

      return DailyReward(_rewardTypeFromString(rewardType));
    } catch (e) {
      debugPrint('⚠️ claimDailyReward xatosi: $e');
      return const DailyReward(DailyRewardType.nothing);
    }
  }

  DailyRewardType _rewardTypeFromString(String type) {
    return switch (type) {
      'xp50' => DailyRewardType.xp50,
      'xp100' => DailyRewardType.xp100,
      'premiumDay' => DailyRewardType.premiumDay,
      'badge' => DailyRewardType.badge,
      _ => DailyRewardType.nothing,
    };
  }

  // ─────────────────────────────────────────────────────────────
  // _pickReward — ehtimollik jadvaliga ko'ra tanlash
  //   xp50:       40%   (0–39)
  //   xp100:      20%   (40–59)
  //   premiumDay: 10%   (60–69)
  //   badge:      10%   (70–79)
  //   nothing:    20%   (80–99)
  // ─────────────────────────────────────────────────────────────
  DailyReward _pickReward() {
    final roll = Random().nextInt(100);

    if (roll < 40) return const DailyReward(DailyRewardType.xp50);
    if (roll < 60) return const DailyReward(DailyRewardType.xp100);
    if (roll < 70) return const DailyReward(DailyRewardType.premiumDay);
    if (roll < 80) return const DailyReward(DailyRewardType.badge);
    return const DailyReward(DailyRewardType.nothing);
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════

final dailyBoxServiceProvider = Provider<DailyBoxService>((ref) {
  return DailyBoxService(ref.watch(firestoreProvider));
});
