// lib/features/referral/domain/entities/referral_entity.dart
// So'zona — Referral (tavsiya) tizimi domain entity
// Clean Architecture: Domain layer — framework'ga bog'liq emas

import 'package:equatable/equatable.dart';

/// Foydalanuvchining referral statistikasini ifodalaydi.
/// [code]        — unikal SZ-XXXX-XXXX kodi (null → hali yaratilmagan)
/// [usedCount]   — kodni nechta yangi foydalanuvchi qo'llagan
/// [deepLink]    — QR code uchun deep link (sozona://referral?code=...)
/// [hasRedeemed] — bu foydalanuvchi birovning kodini allaqachon qo'llaganmi
class ReferralEntity extends Equatable {
  final String? code;
  final int usedCount;
  final String? deepLink;
  final bool hasRedeemed;

  const ReferralEntity({
    required this.code,
    required this.usedCount,
    required this.deepLink,
    required this.hasRedeemed,
  });

  /// Hali kod yaratilmagan yoki yuklanmagan holat
  const ReferralEntity.empty()
      : code = null,
        usedCount = 0,
        deepLink = null,
        hasRedeemed = false;

  /// Kod mavjudmi?
  bool get hasCode => code != null && code!.isNotEmpty;

  /// QR uchun to'liq deep link (kod bo'lsa)
  String get qrData =>
      deepLink ?? (code != null ? 'sozona://referral?code=$code' : '');

  @override
  List<Object?> get props => [code, usedCount, deepLink, hasRedeemed];
}

/// Kodni qo'llash natijasi
class RedeemResultEntity extends Equatable {
  final bool success;
  final String message;

  const RedeemResultEntity({
    required this.success,
    required this.message,
  });

  @override
  List<Object?> get props => [success, message];
}
