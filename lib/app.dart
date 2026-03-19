// lib/app.dart
// So'zona — Asosiy Ilova Widgeti
// ✅ SAFE BOOT: Firebase init bo'lmasa router yuklanmaydi → crash yo'q

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/router/app_router.dart';
import 'package:my_first_app/core/theme/app_theme.dart';
import 'package:my_first_app/l10n/l10n.dart';

class SozonaApp extends ConsumerWidget {
  final bool firebaseReady;

  const SozonaApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!firebaseReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 80, color: Colors.orange),
                  const SizedBox(height: 24),
                  const Text(
                    'Firebase ulanmadi',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Web Firebase hali sozlanmagan. Firebase Console'da Web App qo'shing va flutterfire configure ni android + web bilan qayta ishga tushiring.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      kIsWeb
                          ? 'Web Firebase ni sozlang'
                          : 'Ilovani yoping va qayta oching',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final GoRouter router;
    try {
      router = ref.watch(appRouterProvider);
    } catch (e) {
      debugPrint('❌ Router yaratishda xato: $e');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Ilova ishga tushishda xatolik',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GestureDetector(
          // Tashqariga bosilganda klaviatura yopiladi
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MaterialApp.router(
            title: 'So\'zona',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            themeMode: ThemeMode.light,
            routerConfig: router,
            locale: DevicePreview.locale(context),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              ErrorWidget.builder = (FlutterErrorDetails details) {
                debugPrint('❌ Widget xatosi: ${details.exception}');
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 48,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Xatolik yuz berdi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${details.exception}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              };

              final appChild = child ?? const SizedBox.shrink();
              return DevicePreview.appBuilder(context, appChild);
            },
          ), // MaterialApp.router
        ); // GestureDetector
      },
    );
  }
}
