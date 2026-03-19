// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web Firebase hali sozlanmagan. Firebase Console\'da Web App qo\'shing va '
        'flutterfire configure ni android + web bilan qayta ishga tushiring.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Bu platforma uchun Firebase config yo\'q. '
          'Qo\'llab-quvvatlanadigan platforma: Android.',
        );
    }
  }

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBsKSJTmNKCjknfkm7mwgn53a0f5yHKR0g',
    appId: '1:747601471487:android:3621d664a7d240e0e9e9ca',
    messagingSenderId: '747601471487',
    projectId: 'so-zona',
    storageBucket: 'so-zona.firebasestorage.app',
  );
}
