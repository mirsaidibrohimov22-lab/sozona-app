// lib/l10n/l10n.dart
// Lokalizatsiya konfiguratsiyasi
// pubspec.yaml ga qo'shing:
//   flutter:
//     generate: true
//   flutter_localizations:
//     sdk: flutter

import 'package:flutter/material.dart';

class AppL10n {
  static const supportedLocales = [
    Locale('uz'),
    Locale('ru'),
    Locale('en'),
  ];

  static const localizationsDelegates = [
    // GeneratedLocalizationsDelegate(), // flutter gen-l10n dan keyin
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ];
}
