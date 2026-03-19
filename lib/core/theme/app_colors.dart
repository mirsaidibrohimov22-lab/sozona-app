// ═══════════════════════════════════════════════════════════════
// SO'ZONA — App Colors (YAGONA FAYL)
// QO'YISH: lib/core/theme/app_colors.dart
// ✅ TUZATILDI: constants/ va theme/ birlashtirildi
// ═══════════════════════════════════════════════════════════════
//
// Ilovaning BARCHA ranglari shu yerda.
// Kodda hech qachon Color(0xFF...) deb yozmang — shu fayldan oling!
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Ilovaning rang palitrasi.
///
/// Material 3 Color System asosida tuzilgan.
/// Barcha ranglar semantic (ma'noli) nomlangan.
class AppColors {
  AppColors._();

  // ═══════════════════════════════════
  // 🎨 BRAND RANGLARI (So'zona)
  // ═══════════════════════════════════

  /// Asosiy rang — Indigo (ishonch, bilim)
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryContainer = Color(0xFFE0E7FF);

  /// Ikkilamchi rang — Cyan (kreativlik, til)
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF67E8F9);
  static const Color secondaryDark = Color(0xFF0891B2);
  static const Color secondaryContainer = Color(0xFFCFFAFE);

  /// Urg'u rang — Amber (e'tibor, muhim)
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFCD34D);
  static const Color accentDark = Color(0xFFD97706);

  // ═══════════════════════════════════
  // ✅ HOLAT RANGLARI
  // ═══════════════════════════════════

  /// Muvaffaqiyat — yashil
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF16A34A);

  /// Xatolik — qizil
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);

  /// Ogohlantirish — sariq
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);

  /// Ma'lumot — ko'k
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF2563EB);

  // ═══════════════════════════════════
  // 📊 DARAJA RANGLARI (CEFR)
  // ═══════════════════════════════════

  /// A1 — Boshlang'ich (yashil)
  static const Color levelA1 = Color(0xFF22C55E);

  /// A2 — Elementar (ko'k-yashil)
  static const Color levelA2 = Color(0xFF14B8A6);

  /// B1 — O'rta (ko'k)
  static const Color levelB1 = Color(0xFF3B82F6);

  /// B2 — O'rta-yuqori (indigo)
  static const Color levelB2 = Color(0xFF6366F1);

  /// C1 — Yuqori (binafsha)
  static const Color levelC1 = Color(0xFF8B5CF6);

  /// Darajaga qarab rang qaytaradi.
  static Color getLevelColor(String level) {
    switch (level) {
      case 'A1':
        return levelA1;
      case 'A2':
        return levelA2;
      case 'B1':
        return levelB1;
      case 'B2':
        return levelB2;
      case 'C1':
        return levelC1;
      default:
        return levelA1;
    }
  }

  // ═══════════════════════════════════
  // 🃏 MODUL RANGLARI
  // ═══════════════════════════════════

  /// Flashcards — sariq-to'q
  static const Color moduleFlashcard = Color(0xFFF59E0B);

  /// Quiz — ko'k
  static const Color moduleQuiz = Color(0xFF3B82F6);

  /// Listening — binafsha
  static const Color moduleListening = Color(0xFF8B5CF6);

  /// Speaking — yashil
  static const Color moduleSpeaking = Color(0xFF22C55E);

  /// Artikel — pushti
  static const Color moduleArtikel = Color(0xFFEC4899);

  /// AI Chat — gradient boshi
  static const Color moduleAiChat = Color(0xFF6366F1);

  // ═══════════════════════════════════
  // 🏷️ ARTIKEL RANGLARI (der/die/das)
  // ═══════════════════════════════════

  /// der — ko'k (erkak)
  static const Color artikelDer = Color(0xFF3B82F6);

  /// die — qizil (ayol)
  static const Color artikelDie = Color(0xFFEF4444);

  /// das — yashil (neuter)
  static const Color artikelDas = Color(0xFF22C55E);

  // ═══════════════════════════════════
  // 🌑 NEUTRAL RANGLAR
  // ═══════════════════════════════════

  /// Matn ranglari
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);

  /// Fon ranglari
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF9FAFB);
  static const Color bgTertiary = Color(0xFFF3F4F6);

  /// Chegara ranglari
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);

  /// Divider
  static const Color divider = Color(0xFFE5E7EB);

  // ═══════════════════════════════════
  // 🌟 STREAK / XP / STAR RANGLARI
  // ═══════════════════════════════════

  /// Streak aktiv kun — olov rangi
  static const Color streakActive = Color(0xFFF97316);

  /// Streak o'tkazib yuborilgan kun
  static const Color streakMissed = Color(0xFFE5E7EB);

  /// Streak bugungi kun
  static const Color streakToday = Color(0xFFEF4444);

  // ✅ constants/app_colors dan ko'chirildi — eski kodda ishlatiladi
  /// Streak umumiy rang (alias)
  static const Color streak = Color(0xFFFF6B35);

  /// XP ko'rsatkich rangi — binafsha
  static const Color xp = Color(0xFF8B5CF6);

  /// Yulduzcha rangi — sariq
  static const Color star = Color(0xFFFBBF24);

  // ═══════════════════════════════════
  // 🔀 GRADIENT LAR
  // ═══════════════════════════════════

  /// Primary gradient (tugmalar, headerlar uchun)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// AI gradient (AI Chat header uchun)
  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Streak gradient (streak card uchun)
  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════
  // 🔗 ALIAS (eski import lar uchun)
  // ═══════════════════════════════════
  static const Color surface = bgPrimary;
  static const Color background = bgSecondary;
  static const Color surfaceVariant = bgTertiary;
}
