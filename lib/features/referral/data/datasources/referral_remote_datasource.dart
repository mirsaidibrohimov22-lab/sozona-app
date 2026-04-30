// lib/features/referral/data/datasources/referral_remote_datasource.dart
// So'zona — Referral remote datasource
// Cloud Functions: generateReferralCode, getReferralStats, redeemReferralCode

import 'package:cloud_functions/cloud_functions.dart';
import 'package:my_first_app/features/referral/domain/entities/referral_entity.dart';

abstract class ReferralRemoteDatasource {
  /// Kod yaratish yoki mavjudini olish
  Future<String> generateReferralCode();

  /// Statistika olish
  Future<ReferralEntity> getReferralStats();

  /// Boshqasining kodini qo'llash
  Future<RedeemResultEntity> redeemReferralCode(String code);
}

class ReferralRemoteDatasourceImpl implements ReferralRemoteDatasource {
  final FirebaseFunctions _functions;

  const ReferralRemoteDatasourceImpl({
    required FirebaseFunctions functions,
  }) : _functions = functions;

  // ─────────────────────────────────────────────
  // Kod yaratish
  // ─────────────────────────────────────────────
  @override
  Future<String> generateReferralCode() async {
    final callable = _functions.httpsCallable('generateReferralCode');
    final result = await callable.call<Map<String, dynamic>>();
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['code'] as String;
  }

  // ─────────────────────────────────────────────
  // Statistika olish
  // ─────────────────────────────────────────────
  @override
  Future<ReferralEntity> getReferralStats() async {
    final callable = _functions.httpsCallable('getReferralStats');
    final result = await callable.call<Map<String, dynamic>>();
    final data = Map<String, dynamic>.from(result.data as Map);

    return ReferralEntity(
      code: data['code'] as String?,
      usedCount: (data['usedCount'] as num?)?.toInt() ?? 0,
      deepLink: data['deepLink'] as String?,
      hasRedeemed: data['hasRedeemed'] as bool? ?? false,
    );
  }

  // ─────────────────────────────────────────────
  // Kodni qo'llash
  // ─────────────────────────────────────────────
  @override
  Future<RedeemResultEntity> redeemReferralCode(String code) async {
    final callable = _functions.httpsCallable('redeemReferralCode');
    final result = await callable.call<Map<String, dynamic>>({'code': code});
    final data = Map<String, dynamic>.from(result.data as Map);

    return RedeemResultEntity(
      success: data['success'] as bool? ?? false,
      message: data['message'] as String? ?? '',
    );
  }
}
