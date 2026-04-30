// ═══════════════════════════════════════════════════════════════
// SO'ZONA — App Colors (YAGONA FAYL)
// QO'YISH: lib/core/theme/app_colors.dart
// ✅ TUZATILDI: constants/ va theme/ birlashtirildi
// ✅ YANGILANDI: Yangi chiroyli rang palitrasi
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

  /// Asosiy rang — Violet-Blue (ishonch, bilim)
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42D6);
  static const Color primaryContainer = Color(0xFFEEEDFF);

  /// Ikkilamchi rang — Teal (kreativlik, til)
  static const Color secondary = Color(0xFF2DD4BF);
  static const Color secondaryLight = Color(0xFF7EF0E3);
  static const Color secondaryDark = Color(0xFF0EA5A0);
  static const Color secondaryContainer = Color(0xFFD0FBF5);

  /// Urg'u rang — Warm Orange (e'tibor, muhim)
  static const Color accent = Color(0xFFFF7043);
  static const Color accentLight = Color(0xFFFF9A7A);
  static const Color accentDark = Color(0xFFD84315);

  // ═══════════════════════════════════
  // ✅ HOLAT RANGLARI
  // ═══════════════════════════════════

  /// Muvaffaqiyat — yashil
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF16A34A);

  /// Xatolik — qizil
  static const Color error = Color(0xFFFF5252);
  static const Color errorLight = Color(0xFFFFEBEB);
  static const Color errorDark = Color(0xFFD32F2F);

  /// Ogohlantirish — sariq
  static const Color warning = Color(0xFFFFB347);
  static const Color warningLight = Color(0xFFFFF3CD);
  static const Color warningDark = Color(0xFFF57C00);

  /// Ma'lumot — ko'k
  static const Color info = Color(0xFF4FC3F7);
  static const Color infoLight = Color(0xFFE1F5FE);
  static const Color infoDark = Color(0xFF0288D1);

  // ═══════════════════════════════════
  // 📊 DARAJA RANGLARI (CEFR)
  // ═══════════════════════════════════

  /// A1 — Boshlang'ich (yashil)
  static const Color levelA1 = Color(0xFF4CAF50);

  /// A2 — Elementar (cyan)
  static const Color levelA2 = Color(0xFF26C6DA);

  /// B1 — O'rta (ko'k)
  static const Color levelB1 = Color(0xFF42A5F5);

  /// B2 — O'rta-yuqori (deep purple)
  static const Color levelB2 = Color(0xFF7E57C2);

  /// C1 — Yuqori (pink)
  static const Color levelC1 = Color(0xFFEC407A);

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

  /// Flashcards — amber
  static const Color moduleFlashcard = Color(0xFFFFB347);

  /// Quiz — sky blue
  static const Color moduleQuiz = Color(0xFF4FC3F7);

  /// Listening — lavender
  static const Color moduleListening = Color(0xFFCE93D8);

  /// Speaking — mint
  static const Color moduleSpeaking = Color(0xFF80CBC4);

  /// Artikel — pink
  static const Color moduleArtikel = Color(0xFFF48FB1);

  /// AI Chat — violet
  static const Color moduleAiChat = Color(0xFFA78BFA);

  // ═══════════════════════════════════
  // 🏷️ ARTIKEL RANGLARI (der/die/das)
  // ═══════════════════════════════════

  /// der — ko'k (erkak)
  static const Color artikelDer = Color(0xFF42A5F5);

  /// die — qizil (ayol)
  static const Color artikelDie = Color(0xFFEF5350);

  /// das — yashil (neuter)
  static const Color artikelDas = Color(0xFF66BB6A);

  // ═══════════════════════════════════
  // 🌑 NEUTRAL RANGLAR
  // ═══════════════════════════════════

  /// Matn ranglari
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);

  /// Fon ranglari
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF5F6FF);
  static const Color bgTertiary = Color(0xFFEEEDFF);

  /// Chegara ranglari
  static const Color border = Color(0xFFE8E8F0);
  static const Color borderLight = Color(0xFFF0F0F8);
  static const Color borderDark = Color(0xFFD0D0E0);

  /// Divider
  static const Color divider = Color(0xFFEEEEF8);

  // ═══════════════════════════════════
  // 🌟 STREAK / XP / STAR RANGLARI
  // ═══════════════════════════════════

  /// Streak aktiv kun — olov rangi
  static const Color streakActive = Color(0xFFFF7043);

  /// Streak o'tkazib yuborilgan kun
  static const Color streakMissed = Color(0xFFE8E8F0);

  /// Streak bugungi kun
  static const Color streakToday = Color(0xFFFF5252);

  // ✅ constants/app_colors dan ko'chirildi — eski kodda ishlatiladi
  /// Streak umumiy rang (alias)
  static const Color streak = Color(0xFFFF7043);

  /// XP ko'rsatkich rangi — violet
  static const Color xp = Color(0xFF6C63FF);

  /// Yulduzcha rangi — amber
  static const Color star = Color(0xFFFFB347);

  // ═══════════════════════════════════
  // 🔀 GRADIENTLAR
  // ═══════════════════════════════════

  /// Primary gradient (tugmalar, headerlar uchun)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4A42D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hero gradient (login header uchun)
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4A42D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// AI gradient (AI Chat header uchun)
  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Streak gradient (streak card uchun)
  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFFFF7043), Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Teal gradient (register, secondary actions uchun)
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF2DD4BF), Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════
  // 🔗 ALIAS (eski importlar uchun — o'zgartirma!)
  // ═══════════════════════════════════
  static const Color surface = bgPrimary;
  static const Color background = bgSecondary;
  static const Color surfaceVariant = bgTertiary;
}
