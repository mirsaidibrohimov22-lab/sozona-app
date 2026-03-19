// lib/core/services/crashlytics_service.dart
// So'zona — Firebase Crashlytics servisi

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  CrashlyticsService._();

  static Future<void> init() async {
    // ✅ TUZATISH: FlutterError.onError va PlatformDispatcher.instance.onError
    // bu yerda O'RNATILMAYDI — main.dart da bir marta o'rnatiladi.
    // Bu yerda faqat Crashlytics yoqiladi/o'chiriladi.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  static Future<void> setUser(String userId) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  static Future<void> clearUser() async {
    await FirebaseCrashlytics.instance.setUserIdentifier('');
  }

  static Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  static Future<void> log(String message) async {
    await FirebaseCrashlytics.instance.log(message);
  }
}
