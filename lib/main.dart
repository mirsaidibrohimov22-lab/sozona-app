// lib/main.dart
// So'zona — App entry point
// ✅ FIX: firebase_app_check 0.4.1+5 da AndroidProvider → AndroidAppCheckProvider
//         type mismatch. Yechim: androidProvider/appleProvider (deprecated emas bu versiyada)
//         parametrlari ishlatiladi — AndroidProvider tipi bilan mos keladi.

import 'package:device_preview/device_preview.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_app/app.dart';
import 'package:my_first_app/core/services/crashlytics_service.dart';
import 'package:my_first_app/core/services/notification_service.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  bool firebaseOk = false;

  try {
    if (!DefaultFirebaseOptions.isSupportedPlatform) {
      debugPrint('⚠️ Firebase bu platforma uchun hali sozlanmagan.');
    } else {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      firebaseOk = true;
      debugPrint('✅ Firebase initialized');
    }
  } catch (e, stack) {
    debugPrint('❌ Firebase init xatosi: $e');
    debugPrint('$stack');
  }

  // ─── App Check ────────────────────────────────────────────
  // firebase_app_check: ^0.4.1+5
  // Bu versiyada AndroidProvider tipi AndroidAppCheckProvider bilan mos kelmaydi.
  // Shuning uchun androidProvider / appleProvider parametrlari ishlatiladi.
  if (firebaseOk) {
    try {
      await FirebaseAppCheck.instance.activate(
        // ignore: deprecated_member_use
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        // ignore: deprecated_member_use
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
      debugPrint(
          '✅ App Check initialized (${kDebugMode ? "debug" : "production"})');
    } catch (e) {
      debugPrint('⚠️ App Check init xatosi: $e');
    }
  }
  // ──────────────────────────────────────────────────────────

  if (firebaseOk && !kIsWeb) {
    try {
      await CrashlyticsService.init();
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      debugPrint('✅ Crashlytics initialized');
    } catch (e) {
      debugPrint('⚠️ Crashlytics xatosi: $e');
    }
  }

  // ✅ YANGI: FCM & Notifications
  if (firebaseOk && !kIsWeb) {
    try {
      await NotificationService.init();
      final token = await NotificationService.getToken();
      if (token != null) {
        await NotificationService.saveTokenToFirestore(token);
      }
      NotificationService.listenTokenRefresh(
        NotificationService.saveTokenToFirestore,
      );
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('⚠️ Notification xatosi: $e');
    }
  }

  try {
    await Hive.initFlutter();
    debugPrint('✅ Hive initialized');
  } catch (e) {
    debugPrint('⚠️ Hive xatosi: $e');
  }

  SharedPreferences? sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance();
    debugPrint('✅ SharedPreferences initialized');
  } catch (e) {
    debugPrint('⚠️ SharedPreferences xatosi: $e');
  }

  debugPrint('🚀 App starting... (Firebase: ${firebaseOk ? "✅" : "❌"})');

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => ProviderScope(
        overrides: [
          if (sharedPreferences != null)
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: SozonaApp(firebaseReady: firebaseOk),
      ),
    ),
  );
}
