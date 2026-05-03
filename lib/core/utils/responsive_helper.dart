// lib/core/utils/responsive_helper.dart
// So'zona — Responsive yordamchi (Yangi fayl)
// ✅ Barcha ekran o'lchamlarida overflow oldini olish uchun

import 'package:flutter/material.dart';

/// Responsive o'lchamlarni hisoblash uchun yordamchi klass.
///
/// FOYDALANISH:
/// ```dart
/// final r = ResponsiveHelper(context);
/// Container(height: r.cardHeight)
/// SizedBox(height: r.spacingXl)
/// ```
class ResponsiveHelper {
  final double screenWidth;
  final double screenHeight;
  final double safeTop;
  final double safeBottom;

  ResponsiveHelper(BuildContext context)
      : screenWidth = MediaQuery.of(context).size.width,
        screenHeight = MediaQuery.of(context).size.height,
        safeTop = MediaQuery.of(context).padding.top,
        safeBottom = MediaQuery.of(context).padding.bottom;

  // ── Telefon kategoriyasi ──
  /// iPhone SE, Redmi A seriyasi kabi kichik telefonlar (balandlik < 700px)
  bool get isSmallPhone => screenHeight < 700;

  /// Odatiy telefonlar (700–850px)
  bool get isMediumPhone => screenHeight >= 700 && screenHeight < 850;

  /// Katta ekranli telefonlar (850px+)
  bool get isLargePhone => screenHeight >= 850;

  // ── Adaptive o'lchamlar ──

  /// Login/Register header balandligi
  /// SE (667px): 186px | Odatiy (852px): 238px | Katta: 270px
  double get headerHeight => (screenHeight * 0.28).clamp(180.0, 270.0);

  /// Flashcard, quiz card balandligi
  /// SE: 200px | Odatiy: 255px | Katta: 300px
  double get cardHeight => (screenHeight * 0.30).clamp(200.0, 300.0);

  /// Onboarding, join-class ikonka doirasi
  /// SE: 100px | Odatiy: 135px | Katta: 150px
  double get iconCircleSize => (screenHeight * 0.16).clamp(100.0, 150.0);

  /// Tugma balandligi
  double get buttonHeight => isSmallPhone ? 48.0 : 52.0;

  /// Bottom navigation uchun pastki bo'sh joy
  double get bottomPadding => safeBottom + 16.0;

  // ── Adaptive spacing ──
  double get spacingXs => isSmallPhone ? 2.0 : 4.0;
  double get spacingSm => isSmallPhone ? 6.0 : 8.0;
  double get spacingMd => isSmallPhone ? 10.0 : 12.0;
  double get spacingLg => isSmallPhone ? 12.0 : 16.0;
  double get spacingXl => isSmallPhone ? 16.0 : 24.0;
  double get spacingXxl => isSmallPhone ? 20.0 : 32.0;

  /// Istalgan o'lchamni ekran kengligiga moslash
  /// [base] — 393px (dizayn) uchun mo'ljallangan qiymat
  double scale(double base) {
    return base * (screenWidth / 393.0);
  }

  /// O'lchamni chegaralangan holda moslash
  double scaleClamp(double base, double minVal, double maxVal) {
    return scale(base).clamp(minVal, maxVal);
  }
}
