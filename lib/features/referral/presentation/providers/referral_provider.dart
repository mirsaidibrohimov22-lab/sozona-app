// lib/features/referral/presentation/providers/referral_provider.dart
// So'zona — Referral tizimi Riverpod StateNotifier provider
// Firebase direct calls (profile_screen promo kod stili)

import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════

class ReferralState extends Equatable {
  /// Statistika yuklanmoqdami (birinchi yuklash)
  final bool isLoading;

  /// Referral kodi qo'llanmoqdami
  final bool isRedeeming;

  /// Foydalanuvchining unikal referral kodi (null → hali yuklanmagan)
  final String? code;

  /// Bu kodni nechta yangi foydalanuvchi qo'llagan
  final int usedCount;

  /// QR code va ulashish uchun deep link
  final String? deepLink;

  /// Bu foydalanuvchi birovning kodini allaqachon qo'llaganmi
  final bool hasRedeemed;

  /// Xatolik xabari (null → xato yo'q)
  final String? error;

  /// Muvaffaqiyat xabari (null → hech qanday amal bajurilmagan)
  final String? successMessage;

  const ReferralState({
    this.isLoading = false,
    this.isRedeeming = false,
    this.code,
    this.usedCount = 0,
    this.deepLink,
    this.hasRedeemed = false,
    this.error,
    this.successMessage,
  });

  /// QR code va ulashish uchun to'liq ma'lumot.
  /// deepLink server dan kelgan bo'lsa — uni ishlatadi.
  /// Aks holda local hisoblaydi (offline holat).
  String get qrData =>
      deepLink ?? (code != null ? 'sozona://referral?code=$code' : '');

  ReferralState copyWith({
    bool? isLoading,
    bool? isRedeeming,
    String? code,
    int? usedCount,
    String? deepLink,
    bool? hasRedeemed,
    String? error,
    String? successMessage,
    // null qilib tozalash uchun flag'lar
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ReferralState(
      isLoading: isLoading ?? this.isLoading,
      isRedeeming: isRedeeming ?? this.isRedeeming,
      code: code ?? this.code,
      usedCount: usedCount ?? this.usedCount,
      deepLink: deepLink ?? this.deepLink,
      hasRedeemed: hasRedeemed ?? this.hasRedeemed,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isRedeeming,
        code,
        usedCount,
        deepLink,
        hasRedeemed,
        error,
        successMessage,
      ];
}

// ═══════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════

class ReferralNotifier extends StateNotifier<ReferralState> {
  ReferralNotifier() : super(const ReferralState());

  // Cloud Functions instance — us-central1 region
  final _fn = FirebaseFunctions.instanceFor(region: 'us-central1');

  // ─────────────────────────────────────────────
  // load() — referral ma'lumotlarini yuklash
  // 1. Avval kod yaratiladi (yo'q bo'lsa)
  // 2. Keyin statistika olinadi
  // ─────────────────────────────────────────────
  Future<void> load() async {
    // Allaqachon yuklangan bo'lsa, qayta yuklamaslik
    if (state.code != null && !state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Kod yaratish (yo'q bo'lsa) — mavjud bo'lsa ham xavfsiz
      await _fn
          .httpsCallable('generateReferralCode')
          .call<Map<String, dynamic>>();

      // 2. To'liq statistika olish
      final statsResult = await _fn
          .httpsCallable('getReferralStats')
          .call<Map<String, dynamic>>();
      final data = Map<String, dynamic>.from(statsResult.data as Map);

      state = state.copyWith(
        isLoading: false,
        code: data['code'] as String?,
        usedCount: (data['usedCount'] as num?)?.toInt() ?? 0,
        deepLink: data['deepLink'] as String?,
        hasRedeemed: data['hasRedeemed'] as bool? ?? false,
      );
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Xatolik yuz berdi. Qayta urining.',
      );
    }
  }

  // ─────────────────────────────────────────────
  // reload() — statistikani majburiy yangilash
  // Masalan: kod qo'llangandan keyin yangi usedCount olish
  // ─────────────────────────────────────────────
  Future<void> reload() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _fn
          .httpsCallable('getReferralStats')
          .call<Map<String, dynamic>>();
      final data = Map<String, dynamic>.from(result.data as Map);

      state = state.copyWith(
        isLoading: false,
        usedCount: (data['usedCount'] as num?)?.toInt() ?? 0,
        hasRedeemed: data['hasRedeemed'] as bool? ?? state.hasRedeemed,
      );
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e));
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  // ─────────────────────────────────────────────
  // redeem(code) — birovning kodini qo'llash
  // Muvaffaqiyatli bo'lsa: hasRedeemed = true, successMessage to'ldiriladi
  // ─────────────────────────────────────────────
  Future<void> redeem(String code) async {
    if (state.isRedeeming) return;

    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      state = state.copyWith(error: 'Referral kodni kiriting.');
      return;
    }

    state = state.copyWith(
      isRedeeming: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final result = await _fn
          .httpsCallable('redeemReferralCode')
          .call<Map<String, dynamic>>(
        {'code': trimmed},
      );
      final data = Map<String, dynamic>.from(result.data as Map);

      state = state.copyWith(
        isRedeeming: false,
        hasRedeemed: true,
        successMessage: data['message'] as String? ??
            "Kod qabul qilindi! 1 hafta So'zona ishlating — 3 kun premium kutmoqda! 🎁",
      );
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(
        isRedeeming: false,
        error: _mapError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isRedeeming: false,
        error: 'Xatolik yuz berdi. Qayta urining.',
      );
    }
  }

  // ─────────────────────────────────────────────
  // Xabarlarni tozalash (SnackBar ko'rsatilgandan keyin)
  // ─────────────────────────────────────────────
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  // ─────────────────────────────────────────────
  // Firebase xatoliklarini o'zbekchaga tarjima qilish
  // ─────────────────────────────────────────────
  String _mapError(FirebaseFunctionsException e) {
    return switch (e.code) {
      'unauthenticated' => 'Tizimga kiring.',
      'not-found' => e.message ?? 'Topilmadi.',
      'already-exists' => "Siz allaqachon referral kodi qo'llagansiz.",
      'failed-precondition' => "O'z kodingizni qo'llab bo'lmaydi.",
      'resource-exhausted' => "Bu kod o'z limitiga yetdi.",
      'invalid-argument' => "Kod formati noto'g'ri. Namuna: SZ-ABCD-1234",
      _ => e.message ?? 'Server xatoligi yuz berdi.',
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════

/// Referral tizimi asosiy provideri.
/// Foydalanish: ref.watch(referralProvider)
/// Notifier: ref.read(referralProvider.notifier).load()
final referralProvider =
    StateNotifierProvider<ReferralNotifier, ReferralState>((ref) {
  return ReferralNotifier();
});
