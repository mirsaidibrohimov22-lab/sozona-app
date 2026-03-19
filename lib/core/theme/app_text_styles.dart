// ═══════════════════════════════════════════════════════════════
// SO'ZONA — App Text Styles
// ═══════════════════════════════════════════════════════════════
//
// Ilovaning BARCHA matn stillari shu yerda.
// Kodda hech qachon TextStyle(...) deb yozmang — shu fayldan oling!
//
// Bolaga tushuntirish:
// Maktabda doskaga KATTA harflar bilan sarlavha yoziladi,
// daftarga KICHIK harflar bilan matn. Har birining o'z o'lchami bor.
// TextStyles ham shunday — har bir matn turi uchun tayyor o'lcham.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Ilovaning matn stillari tizimi.
///
/// Naming convention:
/// - `heading` — sarlavhalar (katta, qalin)
/// - `title` — kichik sarlavhalar
/// - `body` — asosiy matn
/// - `label` — yorliqlar, tugma matnlari
/// - `caption` — kichik izoh matnlari
class AppTextStyles {
  AppTextStyles._();

  // ═══════════════════════════════════
  // 📰 SARLAVHALAR (Headings)
  // ═══════════════════════════════════

  /// Eng katta sarlavha — splash, onboarding
  /// 32sp, Bold
  static TextStyle get heading1 => TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
      );

  /// Katta sarlavha — ekran sarlavhasi
  /// 28sp, Bold
  static TextStyle get heading2 => TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
      );

  /// O'rta sarlavha — bo'lim sarlavhasi
  /// 24sp, SemiBold
  static TextStyle get heading3 => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  /// Kichik sarlavha — karta sarlavhasi
  /// 20sp, SemiBold
  static TextStyle get heading4 => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ═══════════════════════════════════
  // 🏷️ TITLE LAR
  // ═══════════════════════════════════

  /// Katta title — list item sarlavhasi
  /// 18sp, SemiBold
  static TextStyle get titleLarge => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// O'rta title — card ichidagi sarlavha
  /// 16sp, SemiBold
  static TextStyle get titleMedium => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// Kichik title — kichik card sarlavhasi
  /// 14sp, SemiBold
  static TextStyle get titleSmall => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ═══════════════════════════════════
  // 📝 BODY (Asosiy matn)
  // ═══════════════════════════════════

  /// Katta body — asosiy matn, tushuntirish
  /// 16sp, Regular
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// O'rta body — ko'p ishlatiladigan matn
  /// 14sp, Regular
  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Kichik body — qo'shimcha matn
  /// 12sp, Regular
  static TextStyle get bodySmall => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ═══════════════════════════════════
  // 🏷️ LABEL (Tugma, yorliq)
  // ═══════════════════════════════════

  /// Katta label — asosiy tugma matni
  /// 16sp, SemiBold
  static TextStyle get labelLarge => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
      );

  /// O'rta label — ikkinchi darajali tugma
  /// 14sp, Medium
  static TextStyle get labelMedium => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      );

  /// Kichik label — chip, badge matnlari
  /// 12sp, Medium
  static TextStyle get labelSmall => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
      );

  // ═══════════════════════════════════
  // 📌 CAPTION (Izoh)
  // ═══════════════════════════════════

  /// Caption — kichik izoh, vaqt, status
  /// 11sp, Regular
  static TextStyle get caption => TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.2,
      );

  // ═══════════════════════════════════
  // 🔢 MAXSUS STILLAR
  // ═══════════════════════════════════

  /// Katta raqam — progress, XP, ball
  /// 40sp, Bold
  static TextStyle get displayNumber => TextStyle(
        fontSize: 40.sp,
        fontWeight: FontWeight.w700,
        height: 1.1,
      );

  /// O'rta raqam — statistika
  /// 28sp, Bold
  static TextStyle get statNumber => TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  /// Timer raqami
  /// 24sp, Mono, Bold
  static TextStyle get timer => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
        height: 1.2,
      );

  /// Streak raqami
  /// 36sp, Bold
  static TextStyle get streakNumber => TextStyle(
        fontSize: 36.sp,
        fontWeight: FontWeight.w800,
        height: 1.1,
      );

  /// Quiz savol matni
  /// 18sp, Medium
  static TextStyle get quizQuestion => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  /// Flashcard old tomon (so'z)
  /// 28sp, Bold
  static TextStyle get flashcardFront => TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  /// Flashcard orqa tomon (tarjima)
  /// 22sp, Medium
  static TextStyle get flashcardBack => TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  /// Artikel tugma matni (der/die/das)
  /// 20sp, Bold
  static TextStyle get artikelButton => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  // Alias getterlar (muvofiqlash uchun)
  static TextStyle get title1 => titleLarge;
  static TextStyle get title2 => titleMedium;
  static TextStyle get title3 => titleSmall;
  static TextStyle get body1 => bodyLarge;
  static TextStyle get body2 => bodyMedium;
  static TextStyle get label => labelMedium;
}
