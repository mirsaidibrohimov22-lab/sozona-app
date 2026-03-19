// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Failure Types
// ═══════════════════════════════════════════════════════════════
//
// Ilovadagi barcha xatolik turlari shu yerda.
// Har bir xatolik turi — aniq xabar va kod bilan.
//
// Bolaga tushuntirish:
// Doktor kasallikni aniqlaydi — gripp, angina, yoki allergiya.
// Failure ham shunday — xatolikni ANIQLAYDI: server xatomi,
// internet yo'qmi, yoki parol noto'g'rimi.
// ═══════════════════════════════════════════════════════════════

import 'package:equatable/equatable.dart';

/// Barcha xatoliklarning ota-onasi (base class).
///
/// Domain layer da xatolik qaytarish uchun ishlatiladi.
/// Har bir xatolik turida [message] va [code] bor.
///
/// Foydalanish (Repository da):
/// ```dart
/// try {
///   final data = await remoteDataSource.getQuizzes();
///   return Right(data);
/// } on ServerException catch (e) {
///   return Left(ServerFailure(message: e.message));
/// }
/// ```
abstract class Failure extends Equatable {
  /// Foydalanuvchiga ko'rsatiladigan xatolik xabari
  final String message;

  /// Xatolik kodi (logging va debugging uchun)
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

// ═══════════════════════════════════════════
// 🌐 SERVER XATOLIKLARI
// ═══════════════════════════════════════════

/// Server (Firebase, Cloud Functions) bilan bog'liq xatolik.
///
/// Misol: Firestore timeout, Cloud Function 500 xatosi
class ServerFailure extends Failure {
  /// HTTP status kodi (bo'lsa)
  final int? statusCode;

  const ServerFailure({
    super.message = 'Server bilan aloqa xatosi',
    super.code = 'SERVER_ERROR',
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// Internet aloqasi yo'q.
///
/// Misol: Wi-Fi o'chiq, mobil internet ishlamayapti
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Internetga ulanish yo\'q',
    super.code = 'NETWORK_ERROR',
  });
}

// ═══════════════════════════════════════════
// 💾 CACHE XATOLIKLARI
// ═══════════════════════════════════════════

/// Local cache (Hive) bilan bog'liq xatolik.
///
/// Misol: Cache bo'sh, Hive box ochilmadi
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Ma\'lumot topilmadi',
    super.code = 'CACHE_ERROR',
  });
}

// ═══════════════════════════════════════════
// 🔐 AUTH XATOLIKLARI
// ═══════════════════════════════════════════

/// Autentifikatsiya bilan bog'liq xatolik.
///
/// Misol: Noto'g'ri parol, email allaqachon mavjud, OTP xato
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Autentifikatsiya xatosi',
    super.code = 'AUTH_ERROR',
  });

  /// Noto'g'ri email yoki parol
  const AuthFailure.invalidCredentials()
      : this(
          message: 'Email yoki parol noto\'g\'ri',
          code: 'INVALID_CREDENTIALS',
        );

  /// Email allaqachon ro'yxatdan o'tgan
  const AuthFailure.emailAlreadyExists()
      : this(
          message: 'Bu email allaqachon ro\'yxatdan o\'tgan',
          code: 'EMAIL_EXISTS',
        );

  /// Telefon raqam allaqachon mavjud
  const AuthFailure.phoneAlreadyExists()
      : this(
          message: 'Bu telefon raqam allaqachon ro\'yxatdan o\'tgan',
          code: 'PHONE_EXISTS',
        );

  /// OTP kodi noto'g'ri
  const AuthFailure.invalidOtp()
      : this(
          message: 'Tasdiqlash kodi noto\'g\'ri',
          code: 'INVALID_OTP',
        );

  /// OTP muddati o'tgan
  const AuthFailure.otpExpired()
      : this(
          message: 'Tasdiqlash kodi muddati o\'tgan. Qayta yuborilsin?',
          code: 'OTP_EXPIRED',
        );

  /// Foydalanuvchi topilmadi
  const AuthFailure.userNotFound()
      : this(
          message: 'Foydalanuvchi topilmadi',
          code: 'USER_NOT_FOUND',
        );

  /// Sessiya tugagan — qayta login kerak
  const AuthFailure.sessionExpired()
      : this(
          message: 'Sessiya tugadi. Qayta kiring.',
          code: 'SESSION_EXPIRED',
        );

  /// Juda ko'p urinish — vaqtincha bloklangan
  const AuthFailure.tooManyAttempts()
      : this(
          message: 'Juda ko\'p urinish. Biroz kuting.',
          code: 'TOO_MANY_ATTEMPTS',
        );
}

// ═══════════════════════════════════════════
// ✅ VALIDATSIYA XATOLIKLARI
// ═══════════════════════════════════════════

/// Input validatsiya xatosi.
///
/// Misol: Noto'g'ri email format, parol juda qisqa
class ValidationFailure extends Failure {
  /// Qaysi maydon noto'g'ri
  final String? field;

  const ValidationFailure({
    super.message = 'Ma\'lumot noto\'g\'ri',
    super.code = 'VALIDATION_ERROR',
    this.field,
  });

  @override
  List<Object?> get props => [message, code, field];
}

// ═══════════════════════════════════════════
// 🤖 AI XATOLIKLARI
// ═══════════════════════════════════════════

/// AI provayderlar bilan umumiy xatolik.
///
/// Misol: OpenAI timeout, Gemini xatosi
class AiFailure extends Failure {
  /// Qaysi AI provayder xato berdi
  final String? provider;

  const AiFailure({
    super.message = 'AI xizmati vaqtincha ishlamayapti',
    super.code = 'AI_ERROR',
    this.provider,
  });

  @override
  List<Object?> get props => [message, code, provider];
}

/// AI javobining JSON formati noto'g'ri.
///
/// Misol: AI to'g'ri JSON qaytarmadi, schema validation failed
class AiJsonInvalidFailure extends Failure {
  /// Qaysi sxema buzildi
  final List<String>? validationErrors;

  const AiJsonInvalidFailure({
    super.message = 'AI javob formati noto\'g\'ri. Qayta urinib ko\'ring.',
    super.code = 'AI_JSON_INVALID',
    this.validationErrors,
  });

  @override
  List<Object?> get props => [message, code, validationErrors];
}

/// AI so'rovlar limiti tugadi.
///
/// Misol: 60 so'rov/min limitiga yetdi
class RateLimitFailure extends Failure {
  /// Qachon qayta urinish mumkin (sekund)
  final int? retryAfterSeconds;

  const RateLimitFailure({
    super.message = 'So\'rov limiti tugadi. Biroz kuting.',
    super.code = 'RATE_LIMIT',
    this.retryAfterSeconds,
  });

  @override
  List<Object?> get props => [message, code, retryAfterSeconds];
}

/// AI kvotasi tugadi (oylik limit).
///
/// Misol: Free plan ning oylik AI limiti tugadi
class QuotaExceededFailure extends Failure {
  const QuotaExceededFailure({
    super.message = 'AI kvotasi tugadi. Keyingi oyda yangilanadi.',
    super.code = 'QUOTA_EXCEEDED',
  });
}

// ═══════════════════════════════════════════
// 🔒 RUXSAT XATOLIKLARI
// ═══════════════════════════════════════════

/// Ruxsat yo'q (Firestore Security Rules rad etdi).
///
/// Misol: Student teacher sahifasiga kirishga urinish
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Ruxsat yo\'q',
    super.code = 'PERMISSION_DENIED',
  });
}

// ═══════════════════════════════════════════
// ❓ NOMA'LUM XATOLIKLAR
// ═══════════════════════════════════════════

/// Kutilmagan, noma'lum xatolik.
///
/// Bu HECH QACHON maxsus ishlatilmasligi kerak!
/// Faqat catch-all sifatida — agar aniq tur topilmasa.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Kutilmagan xatolik yuz berdi',
    super.code = 'UNKNOWN_ERROR',
  });
}
