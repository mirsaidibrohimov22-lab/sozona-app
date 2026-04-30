// lib/core/services/deep_link_service.dart
// So'zona — Deep Link xizmati
//
// MAQSAD:
//   sozona://referral?code=SZ-XXXX-XXXX linkni tutib olish va
//   redeemReferralCode Cloud Function ni avtomatik chaqirish.
//
// ISHLATILISH:
//   main.dart → _initBackgroundServices() ichida:
//     await DeepLinkService.init();
//
// PAKET: app_links (firebase_dynamic_links o'chirilgan — 2025-avg)
//   pubspec.yaml ga: app_links: ^6.3.0
//
// ANDROID QOIDA:
//   android/app/src/main/AndroidManifest.xml ga intent-filter kerak:
//   (pastda izoh ko'rsatilgan)

import 'package:app_links/app_links.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  // AppLinks instance — bir marta yaratiladi
  static final _appLinks = AppLinks();

  // Takroriy qayta ishlashdan saqlash uchun oxirgi kod
  static String? _lastHandledCode;

  /// Servisni ishga tushirish — _initBackgroundServices() dan chaqiriladi
  /// runApp() dan KEYIN ishlaydi → splash ni bloklamaydi
  static Future<void> init() async {
    // ── 1. Sovuq ishga tushish (app yopiq edi) ──────────────────
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        debugPrint('🔗 DeepLink (cold): $uri');
        await _handleLink(uri);
      }
    } catch (e) {
      debugPrint('⚠️ DeepLink cold start xatosi: $e');
    }

    // ── 2. Iliq ishga tushish (app fonda edi) ───────────────────
    _appLinks.uriLinkStream.listen(
      (uri) async {
        debugPrint('🔗 DeepLink (warm): $uri');
        await _handleLink(uri);
      },
      onError: (e) => debugPrint('⚠️ DeepLink stream xatosi: $e'),
    );
  }

  /// Linki tahlil qilish va referral kodini qo'llash
  /// sozona://referral?code=SZ-XXXX-XXXX
  static Future<void> _handleLink(Uri uri) async {
    // Faqat referral linkini qayta ishlaymiz
    if (uri.host != 'referral') return;

    final code = uri.queryParameters['code'];
    if (code == null || code.trim().isEmpty) return;

    // Bir xil kodni ikki marta qayta ishlamaslik
    final trimmed = code.trim().toUpperCase();
    if (trimmed == _lastHandledCode) return;
    _lastHandledCode = trimmed;

    // Foydalanuvchi tizimga kirgan bo'lsa chaqiramiz
    // Kirmaganda — link e'tiborga olinmaydi (referral_screen da qo'lda kiritadi)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(
          '⏭️ DeepLink: foydalanuvchi tizimga kirmagan — o\'tkazib yuborildi');
      return;
    }

    try {
      final fn = FirebaseFunctions.instanceFor(region: 'us-central1');
      final result = await fn
          .httpsCallable('redeemReferralCode')
          .call<Map<String, dynamic>>({'code': trimmed});

      final message = (result.data as Map?)?['message'] as String?;
      debugPrint('✅ Referral kodi avtomatik qo\'llandi: $trimmed → $message');
    } on FirebaseFunctionsException catch (e) {
      // already-exists — allaqachon qo'llagan, xato hisoblanmaydi
      if (e.code == 'already-exists') {
        debugPrint('ℹ️ Referral: allaqachon qo\'llangan — $trimmed');
        return;
      }
      // failed-precondition — o'z kodini qo'llashga urinish
      if (e.code == 'failed-precondition') {
        debugPrint('ℹ️ Referral: o\'z kodini qo\'llab bo\'lmaydi');
        return;
      }
      debugPrint('⚠️ Referral redeem xatosi: [${e.code}] ${e.message}');
    } catch (e) {
      debugPrint('⚠️ Referral redeem kutilmagan xato: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ANDROID SOZLASH (bir martalik qo'lda bajarish kerak)
// ═══════════════════════════════════════════════════════════════
//
// android/app/src/main/AndroidManifest.xml
// <activity ...> tegi ichiga qo'shing:
//
//   <intent-filter>
//     <action android:name="android.intent.action.VIEW" />
//     <category android:name="android.intent.category.DEFAULT" />
//     <category android:name="android.intent.category.BROWSABLE" />
//     <data android:scheme="sozona" android:host="referral" />
//   </intent-filter>
//
// Bu qo'shilmasa — sozona://referral?code=... linki app ni ochmaidi,
// lekin qo'lda kod kiritish to'liq ishlayveradi.
// ═══════════════════════════════════════════════════════════════
