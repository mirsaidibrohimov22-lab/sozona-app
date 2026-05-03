// lib/main.dart
// So'zona — App entry point
// ✅ FIX v2: Qora ekran muammosi hal qilindi.
// ✅ FIX v3: flutter_foreground_task initCommunicationPort qo'shildi
// ✅ FIX v4: StorageService singleton — faqat bitta instance, provider bilan mos

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_app/app.dart';
import 'package:my_first_app/core/services/crashlytics_service.dart';
import 'package:my_first_app/core/services/deep_link_service.dart';
import 'package:my_first_app/core/services/local_storage_service.dart';
import 'package:my_first_app/core/services/notification_service.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ flutter_foreground_task — runApp dan OLDIN chaqirilishi shart
  FlutterForegroundTask.initCommunicationPort();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // 1. Firebase — zarur, await kerak
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
    debugPrint('❌ Firebase init xatosi: $e\n$stack');
  }

  // 2. Hive + StorageService
  // ✅ FIX v4: storageInstance — bitta instance, provider ham shu instanceni ishlatadi.
  // Avvalgi: StorageService() yangi instance → storageServiceProvider boshqa instance.
  // Yangi:   ProviderScope override orqali ikkalasi ham bir xil object.
  final StorageService storageInstance = StorageService();
  try {
    await Hive.initFlutter();
    await storageInstance.init();
    debugPrint('✅ Hive initialized');
  } catch (e) {
    debugPrint('⚠️ Hive xatosi: $e');
  }

  // 3. SharedPreferences — lokal, tez, kerak
  SharedPreferences? sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance();
    debugPrint('✅ SharedPreferences initialized');
  } catch (e) {
    debugPrint('❌ SharedPreferences xatolik: $e');
  }

  // SharedPreferences olmasa ilova ishlay olmaydi — xato ekranini ko'rsatamiz
  if (sharedPreferences == null) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Ilova xotira xatosi tufayli ishga tushmadi.\n'
                'Qurilmangizni qayta ishga tushiring.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  debugPrint('🚀 App starting...');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        // ✅ FIX v4: provider ham xuddi shu init qilingan instanceni ishlatadi
        storageServiceProvider.overrideWithValue(storageInstance),
      ],
      child: SozonaApp(firebaseReady: firebaseOk),
    ),
  );

  // 4. Sekin/network servislar — runApp() dan KEYIN, fonda
  if (firebaseOk && !kIsWeb) {
    _initBackgroundServices();
  }
}

/// Fonda bajariladigan — birinchi kadrni kechiktirmaydi
Future<void> _initBackgroundServices() async {
  await Future.delayed(const Duration(milliseconds: 300));

  // App Check
  try {
    await FirebaseAppCheck.instance.activate(
      // ignore: deprecated_member_use
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      // ignore: deprecated_member_use
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
    debugPrint('✅ App Check initialized');
  } catch (e) {
    debugPrint('⚠️ App Check xatosi: $e');
  }

  // Crashlytics
  try {
    await CrashlyticsService.init();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    debugPrint('✅ Crashlytics initialized');
  } catch (e) {
    debugPrint('⚠️ Crashlytics xatosi: $e');
  }

  // Notifications
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

  // Deep Link
  try {
    await DeepLinkService.init();
    debugPrint('✅ DeepLinkService initialized');
  } catch (e) {
    debugPrint('⚠️ DeepLink xatosi: $e');
  }
}
