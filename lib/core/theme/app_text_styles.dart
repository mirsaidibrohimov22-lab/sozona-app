// lib/core/theme/app_text_styles.dart
// So'zona — App Text Styles
// ✅ RESPONSIVE FIX: .clamp(min, max) qo'shildi
//
// Muammo: kichik telefon (360px keng) da font juda katta ko'rinadi,
//         katta telefon (428px) da ba'zi joylar sig'maydi.
// Yechim: har bir font o'lchamiga min va max chegaralar qo'yildi.
//
// MUHIM: Dart 3 da double.clamp(double, double) → double qaytaradi. ✓
// flutter_screenutil .sp → double qaytaradi. ✓

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyles {
  AppTextStyles._();

  // ═══════════════════════════════════
  // 📰 SARLAVHALAR (Headings)
  // ═══════════════════════════════════

  /// Eng katta sarlavha — splash, onboarding (asl: 32sp)
  static TextStyle get heading1 => TextStyle(
        fontSize: 32.sp.clamp(24.0, 36.0),
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
      );

  /// Katta sarlavha — ekran sarlavhasi (asl: 28sp)
  static TextStyle get heading2 => TextStyle(
        fontSize: 28.sp.clamp(22.0, 32.0),
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
      );

  /// O'rta sarlavha — bo'lim sarlavhasi (asl: 24sp)
  static TextStyle get heading3 => TextStyle(
        fontSize: 24.sp.clamp(18.0, 28.0),
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  /// Kichik sarlavha — karta sarlavhasi (asl: 20sp)
  static TextStyle get heading4 => TextStyle(
        fontSize: 20.sp.clamp(16.0, 24.0),
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ═══════════════════════════════════
  // 🏷️ TITLE LAR
  // ═══════════════════════════════════

  /// Katta title — list item sarlavhasi (asl: 18sp)
  static TextStyle get titleLarge => TextStyle(
        fontSize: 18.sp.clamp(14.0, 20.0),
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// O'rta title — card ichidagi sarlavha (asl: 16sp)
  static TextStyle get titleMedium => TextStyle(
        fontSize: 16.sp.clamp(13.0, 18.0),
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// Kichik title — kichik card sarlavhasi (asl: 14sp)
  static TextStyle get titleSmall => TextStyle(
        fontSize: 14.sp.clamp(12.0, 16.0),
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ═══════════════════════════════════
  // 📝 BODY (Asosiy matn)
  // ═══════════════════════════════════

  /// Katta body — asosiy matn (asl: 16sp)
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16.sp.clamp(13.0, 18.0),
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// O'rta body — ko'p ishlatiladigan matn (asl: 14sp)
  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14.sp.clamp(12.0, 16.0),
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Kichik body — qo'shimcha matn (asl: 12sp)
  static TextStyle get bodySmall => TextStyle(
        fontSize: 12.sp.clamp(10.0, 14.0),
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ═══════════════════════════════════
  // 🏷️ LABEL (Tugma, yorliq)
  // ═══════════════════════════════════

  /// Katta label — asosiy tugma matni (asl: 16sp)
  static TextStyle get labelLarge => TextStyle(
        fontSize: 16.sp.clamp(13.0, 18.0),
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
      );

  /// O'rta label — ikkinchi darajali tugma (asl: 14sp)
  static TextStyle get labelMedium => TextStyle(
        fontSize: 14.sp.clamp(12.0, 16.0),
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      );

  /// Kichik label — chip, badge matnlari (asl: 12sp)
  static TextStyle get labelSmall => TextStyle(
        fontSize: 12.sp.clamp(10.0, 14.0),
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
      );

  // ═══════════════════════════════════
  // 📌 CAPTION (Izoh)
  // ═══════════════════════════════════

  /// Caption — kichik izoh, vaqt, status (asl: 11sp)
  static TextStyle get caption => TextStyle(
        fontSize: 11.sp.clamp(10.0, 13.0),
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.2,
      );

  // ═══════════════════════════════════
  // 🔢 MAXSUS STILLAR
  // ═══════════════════════════════════

  /// Katta raqam — progress, XP, ball (asl: 40sp)
  static TextStyle get displayNumber => TextStyle(
        fontSize: 40.sp.clamp(30.0, 46.0),
        fontWeight: FontWeight.w700,
        height: 1.1,
      );

  /// O'rta raqam — statistika (asl: 28sp)
  static TextStyle get statNumber => TextStyle(
        fontSize: 28.sp.clamp(22.0, 32.0),
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  /// Timer raqami (asl: 24sp)
  static TextStyle get timer => TextStyle(
        fontSize: 24.sp.clamp(18.0, 28.0),
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
        height: 1.2,
      );

  /// Streak raqami (asl: 36sp)
  static TextStyle get streakNumber => TextStyle(
        fontSize: 36.sp.clamp(28.0, 42.0),
        fontWeight: FontWeight.w800,
        height: 1.1,
      );

  /// Quiz savol matni (asl: 18sp)
  static TextStyle get quizQuestion => TextStyle(
        fontSize: 18.sp.clamp(14.0, 22.0),
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  /// Flashcard old tomon (asl: 28sp)
  static TextStyle get flashcardFront => TextStyle(
        fontSize: 28.sp.clamp(20.0, 34.0),
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  /// Flashcard orqa tomon (asl: 22sp)
  static TextStyle get flashcardBack => TextStyle(
        fontSize: 22.sp.clamp(16.0, 26.0),
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  /// Artikel tugma matni (asl: 20sp)
  static TextStyle get artikelButton => TextStyle(
        fontSize: 20.sp.clamp(16.0, 24.0),
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  // Alias getterlar (muvofiqlash uchun — eski kodlar ishlashi uchun)
  static TextStyle get title1 => titleLarge;
  static TextStyle get title2 => titleMedium;
  static TextStyle get title3 => titleSmall;
  static TextStyle get body1 => bodyLarge;
  static TextStyle get body2 => bodyMedium;
  static TextStyle get label => labelMedium;
}
