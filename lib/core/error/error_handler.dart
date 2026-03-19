// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Error Handler
// ═══════════════════════════════════════════════════════════════
//
// Exception → Failure ga aylantiradi.
// Har bir xatolikka mos foydalanuvchi xabarini beradi.
//
// Bolaga tushuntirish:
// Doktor kasallikni aniqlaydi va shu kasallikka mos dori beradi.
// ErrorHandler ham shunday — xatolikni aniqlaydi va mos xabar beradi.
//
// Oqim:
// DataSource → Exception → ErrorHandler → Failure → UI
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/services/crashlytics_service.dart';
import 'package:my_first_app/core/services/logger_service.dart';

/// Xatoliklarni boshqarish markazi.
///
/// Vazifasi:
/// 1. Xatolik turini aniqlash (Exception → Failure)
/// 2. Xatolikni log qilish (Logger + Crashlytics)
/// 3. Foydalanuvchiga tushunarli xabar qaytarish
class ErrorHandler {
  ErrorHandler._();

  /// Har qanday xatolikni [Failure] ga aylantiradi.
  ///
  /// Repository larda ishlatiladi:
  /// ```dart
  /// try {
  ///   final data = await remoteDataSource.getQuizzes();
  ///   return Right(data);
  /// } catch (e, s) {
  ///   return Left(ErrorHandler.handleException(e, s));
  /// }
  /// ```
  static Failure handleException(Object error, [StackTrace? stackTrace]) {
    // Xatolikni log qilish
    _logError(error, stackTrace);

    // ═══════════════════════════════════
    // Bizning custom exceptionlar
    // ═══════════════════════════════════
    if (error is ServerException) {
      return ServerFailure(
        message: error.message,
        code: error.code,
        statusCode: error.statusCode,
      );
    }

    if (error is NetworkException) {
      return const NetworkFailure();
    }

    if (error is CacheException) {
      return CacheFailure(message: error.message);
    }

    if (error is AuthException) {
      return AuthFailure(
        message: error.message,
        code: error.code,
      );
    }

    if (error is AiException) {
      return AiFailure(
        message: error.message,
        provider: error.provider,
      );
    }

    if (error is AiJsonException) {
      return AiJsonInvalidFailure(
        message: error.message,
        validationErrors: error.validationErrors,
      );
    }

    if (error is RateLimitException) {
      return RateLimitFailure(
        message: error.message,
        retryAfterSeconds: error.retryAfterSeconds,
      );
    }

    // ═══════════════════════════════════
    // Firebase Auth xatoliklari
    // ═══════════════════════════════════
    if (error is FirebaseAuthException) {
      final authException = AuthException.fromFirebaseCode(error.code);
      return AuthFailure(
        message: authException.message,
        code: authException.code,
      );
    }

    // ═══════════════════════════════════
    // Firebase Firestore xatoliklari
    // ═══════════════════════════════════
    if (error is FirebaseException) {
      return _handleFirebaseException(error);
    }

    // ═══════════════════════════════════
    // Dio (HTTP) xatoliklari
    // ═══════════════════════════════════
    if (error is DioException) {
      return _handleDioException(error);
    }

    // ═══════════════════════════════════
    // Internet xatoliklari
    // ═══════════════════════════════════
    if (error is SocketException || error is HandshakeException) {
      return const NetworkFailure();
    }

    // ═══════════════════════════════════
    // Format xatoliklari
    // ═══════════════════════════════════
    if (error is FormatException) {
      return const ServerFailure(
        message: 'Ma\'lumot formati noto\'g\'ri',
        code: 'FORMAT_ERROR',
      );
    }

    if (error is TypeError) {
      return ServerFailure(
        message: 'Ma\'lumot turi xatosi: ${error.toString()}',
        code: 'TYPE_ERROR',
      );
    }

    // ═══════════════════════════════════
    // Noma'lum xatolik
    // ═══════════════════════════════════
    return const UnknownFailure();
  }

  /// Firebase xatolarini Failure ga aylantiradi.
  static Failure _handleFirebaseException(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return const PermissionFailure();
      case 'unavailable':
        return const ServerFailure(
          message: 'Server vaqtincha ishlamayapti',
          code: 'SERVICE_UNAVAILABLE',
        );
      case 'not-found':
        return const ServerFailure(
          message: 'Ma\'lumot topilmadi',
          code: 'NOT_FOUND',
        );
      case 'already-exists':
        return const ServerFailure(
          message: 'Bu ma\'lumot allaqachon mavjud',
          code: 'ALREADY_EXISTS',
        );
      case 'deadline-exceeded':
        return const ServerFailure(
          message: 'So\'rov vaqti tugadi. Qayta urinib ko\'ring.',
          code: 'TIMEOUT',
        );
      case 'resource-exhausted':
        return const RateLimitFailure();
      default:
        return ServerFailure(
          message: error.message ?? 'Firebase xatosi',
          code: error.code,
        );
    }
  }

  /// Dio HTTP xatolarini Failure ga aylantiradi.
  static Failure _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerFailure(
          message: 'So\'rov vaqti tugadi. Qayta urinib ko\'ring.',
          code: 'TIMEOUT',
        );
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 429) {
          return const RateLimitFailure();
        }
        if (statusCode == 403) {
          return const PermissionFailure();
        }
        return ServerFailure(
          message: 'Server xatosi ($statusCode)',
          code: 'HTTP_$statusCode',
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return const ServerFailure(
          message: 'So\'rov bekor qilindi',
          code: 'CANCELLED',
        );
      default:
        return const ServerFailure();
    }
  }

  /// Xatolikni log qilish (Logger + Crashlytics).
  static void _logError(Object error, StackTrace? stackTrace) {
    LoggerService.error(
      'Error caught: ${error.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );

    CrashlyticsService.recordError(
      error,
      stackTrace,
      reason: 'ErrorHandler.handleException',
    );
  }
}
