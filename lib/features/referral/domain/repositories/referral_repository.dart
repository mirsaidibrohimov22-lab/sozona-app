// lib/features/referral/domain/repositories/referral_repository.dart
// So'zona — Referral repository abstract interfeysi
// Clean Architecture: Domain layer — faqat contract, hech qanday impl yo'q

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/referral/domain/entities/referral_entity.dart';

abstract class ReferralRepository {
  /// Foydalanuvchi uchun referral kodi yaratadi.
  /// Agar allaqachon kod mavjud bo'lsa, uni qaytaradi.
  Future<Either<Failure, String>> generateReferralCode();

  /// Referral statistikasini oladi:
  /// kod, usedCount, deepLink, hasRedeemed
  Future<Either<Failure, ReferralEntity>> getReferralStats();

  /// Boshqa foydalanuvchi kodini qo'llaydi.
  /// Muvaffaqiyatli bo'lsa → ikkalasiga +7 kun premium + streak freeze
  Future<Either<Failure, RedeemResultEntity>> redeemReferralCode(String code);
}
