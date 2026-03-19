// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Exception Types
// ═══════════════════════════════════════════════════════════════
//
// Bu exceptionlar DATA LAYER da ishlatiladi (DataSource'larda).
// Repository ularni ushlab, Failure ga aylantiradi.
//
// Bolaga tushuntirish:
// Exception — bu "YORDAM!" deb baqirish. Muammo yuz berganda
// DataSource "YORDAM!" deb baqiradi, Repository eshitadi va
// muammoni hal qiladi (Failure ga aylantiradi).
//
// Oqim:
// DataSource → Exception tashlaydi → Repository ushlaydi → Failure qaytaradi
// ═══════════════════════════════════════════════════════════════

/// Barcha exceptionlarning ota-onasi.
///
/// Data layer da (DataSource) xatolik yuz berganda tashlanadi.
/// Repository bu exceptionni ushlaydi va [Failure] ga aylantiradi.
abstract class AppException implements Exception {
  /// Xatolik xabari
  final String message;

  /// Xatolik kodi
  final String? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

// ═══════════════════════════════════════════
// 🌐 SERVER
// ═══════════════════════════════════════════

/// Firebase yoki Cloud Functions server xatosi.
///
/// Firestore, Auth, Storage operatsiyalari muvaffaqiyatsiz bo'lganda.
///
/// Misol:
/// ```dart
/// try {
///   await firestore.collection('users').doc(id).get();
/// } on FirebaseException catch (e) {
///   throw ServerException(message: e.message ?? 'Server xatosi');
/// }
/// ```
class ServerException extends AppException {
  /// HTTP status kodi
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code,
    this.statusCode,
  });
}

/// Internet aloqasi yo'q.
///
/// API chaqirilishidan OLDIN connectivity tekshiriladi.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Internetga ulanish yo\'q',
    super.code = 'NETWORK_ERROR',
  });
}

// ═══════════════════════════════════════════
// 💾 CACHE
// ═══════════════════════════════════════════

/// Local cache xatosi (Hive).
///
/// Cache'dan o'qish yoki yozish muvaffaqiyatsiz bo'lganda.
class CacheException extends AppException {
  const CacheException({
    super.message = 'Local cache xatosi',
    super.code = 'CACHE_ERROR',
  });
}

// ═══════════════════════════════════════════
// 🔐 AUTH
// ═══════════════════════════════════════════

/// Auth xatosi.
///
/// Firebase Auth operatsiyalari muvaffaqiyatsiz bo'lganda.
/// [firebaseCode] — Firebase'ning o'z xato kodi.
class AuthException extends AppException {
  /// Firebase Auth xato kodi (masalan: 'wrong-password')
  final String? firebaseCode;

  const AuthException({
    required super.message,
    super.code,
    this.firebaseCode,
  });

  /// Firebase Auth xato kodidan mos AuthException yaratadi.
  ///
  /// Bu factory method Firebase xato kodlarini o'qilishi oson
  /// xabarlarga aylantiradi.
  factory AuthException.fromFirebaseCode(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException(
          message: 'Email yoki parol noto\'g\'ri',
          code: 'INVALID_CREDENTIALS',
          firebaseCode: 'wrong-password',
        );
      case 'user-not-found':
        return const AuthException(
          message: 'Bu email bilan hisob topilmadi',
          code: 'USER_NOT_FOUND',
          firebaseCode: 'user-not-found',
        );
      case 'email-already-in-use':
        return const AuthException(
          message: 'Bu email allaqachon ro\'yxatdan o\'tgan',
          code: 'EMAIL_EXISTS',
          firebaseCode: 'email-already-in-use',
        );
      case 'weak-password':
        return const AuthException(
          message: 'Parol juda oddiy. Kamida 8 belgi bo\'lsin.',
          code: 'WEAK_PASSWORD',
          firebaseCode: 'weak-password',
        );
      case 'invalid-email':
        return const AuthException(
          message: 'Email formati noto\'g\'ri',
          code: 'INVALID_EMAIL',
          firebaseCode: 'invalid-email',
        );
      case 'user-disabled':
        return const AuthException(
          message: 'Bu hisob bloklangan',
          code: 'USER_DISABLED',
          firebaseCode: 'user-disabled',
        );
      case 'too-many-requests':
        return const AuthException(
          message: 'Juda ko\'p urinish. Biroz kuting.',
          code: 'TOO_MANY_ATTEMPTS',
          firebaseCode: 'too-many-requests',
        );
      case 'invalid-verification-code':
        return const AuthException(
          message: 'Tasdiqlash kodi noto\'g\'ri',
          code: 'INVALID_OTP',
          firebaseCode: 'invalid-verification-code',
        );
      case 'session-expired':
        return const AuthException(
          message: 'Tasdiqlash muddati o\'tdi. Qayta yuboring.',
          code: 'OTP_EXPIRED',
          firebaseCode: 'session-expired',
        );
      default:
        return AuthException(
          message: 'Autentifikatsiya xatosi: $code',
          code: 'AUTH_ERROR',
          firebaseCode: code,
        );
    }
  }
}

// ═══════════════════════════════════════════
// 🤖 AI
// ═══════════════════════════════════════════

/// AI provayder xatosi.
///
/// OpenAI yoki Gemini dan javob olish muvaffaqiyatsiz bo'lganda.
class AiException extends AppException {
  /// Qaysi provayder xato berdi
  final String? provider;

  const AiException({
    required super.message,
    super.code,
    this.provider,
  });
}

/// AI javob JSON xatosi.
///
/// AI to'g'ri formatda javob qaytarmadi.
class AiJsonException extends AppException {
  /// JSON validation xatoliklari ro'yxati
  final List<String>? validationErrors;

  const AiJsonException({
    super.message = 'AI javob formati noto\'g\'ri',
    super.code = 'AI_JSON_INVALID',
    this.validationErrors,
  });
}

// ═══════════════════════════════════════════
// ⏱️ RATE LIMIT
// ═══════════════════════════════════════════

/// Rate limit xatosi.
///
/// Foydalanuvchi juda ko'p so'rov yubordi.
class RateLimitException extends AppException {
  /// Qachon qayta urinish mumkin (sekund)
  final int? retryAfterSeconds;

  const RateLimitException({
    super.message = 'So\'rov limiti tugadi. Biroz kuting.',
    super.code = 'RATE_LIMIT',
    this.retryAfterSeconds,
  });
}

// ═══════════════════════════════════════════
// 🗂️ INDEX MISSING (Firestore composite index)
// ═══════════════════════════════════════════

/// Firestore composite index mavjud emas.
///
/// [failed-precondition] xatosi kelganda ishlatiladi.
/// Index deploy qilingandan keyin (1-5 daqiqa) avtomatik hal bo'ladi.
class IndexMissingException extends AppException {
  /// Foydalanuvchiga ko'rsatiladigan xabar
  final String userMessage;

  const IndexMissingException({
    super.message = 'Firestore index yo\'q — deploy qiling',
    super.code = 'INDEX_MISSING',
    this.userMessage = 'Yuklanmoqda... Iltimos, keyinroq urinib ko\'ring.',
  });
}
