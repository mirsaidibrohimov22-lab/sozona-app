// QO'YISH: lib/core/services/logger_service.dart
// So'zona — Logging servisi (Crashlytics bilan integratsiya)

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:my_first_app/core/utils/logger.dart';

class LoggerService {
  LoggerService._();

  static void debug(String message, [dynamic data]) {
    if (kDebugMode) appLogger.d('$message ${data ?? ''}');
  }

  static void info(String message, [dynamic data]) {
    appLogger.i('$message ${data ?? ''}');
  }

  static void warning(String message, [dynamic data]) {
    appLogger.w('$message ${data ?? ''}');
  }

  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    bool fatal = false,
  }) {
    appLogger.e(message, error: error, stackTrace: stackTrace);
    // Crashlytics ga yuborish (faqat release modeda)
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error ?? message,
        stackTrace,
        reason: message,
        fatal: fatal,
      );
    }
  }

  static void setUserId(String userId) {
    FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  static void log(String key, String value) {
    FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}
