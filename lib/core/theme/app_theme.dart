// ═══════════════════════════════════════════════════════════════
// SO'ZONA — App Theme (PROFESSIONAL)
// QO'YISH: lib/core/theme/app_theme.dart
// ✅ TUZATILDI: To'liq chiroyli tema — ko'zni charchatmaydigan,
//    zamonaviy, bolalar uchun jalb qiluvchi dizayn
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ilovaning vizual ko'rinishi — ranglar, shriftlar, stillar.
///
/// Material 3 dizayn tizimi asosida qurilgan.
/// Ko'zni charchatmaydigan yumshoq ranglar, lekin jalb qiluvchi.
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════
  // So'zona Brand Ranglari
  // ═══════════════════════════════════
  static const Color _primaryColor = Color(0xFF4F46E5); // Indigo
  static const Color _secondaryColor = Color(0xFF06B6D4); // Cyan
  static const Color _tertiaryColor = Color(0xFF8B5CF6); // Violet
  static const Color _errorColor = Color(0xFFEF4444); // Red

  // Yumshoq fon ranglari — ko'zni charchatmaydi
  static const Color _bgLight = Color(0xFFF8FAFC); // Juda yumshoq kulrang-oq
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _cardLight = Color(0xFFFFFFFF);

  // ═══════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _tertiaryColor,
      error: _errorColor,
      brightness: Brightness.light,
      surface: _surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgLight,

      // ── Umumiy font ──
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Roboto', 'sans-serif'],

      // ── Status bar ──
      // (AppBar ichida ham override qilinadi)

      // ═══════════════════════════════════
      // 📱 APP BAR — Shaffof, zamonaviy
      // ═══════════════════════════════════
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: _bgLight,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF1E293B),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF475569),
          size: 24,
        ),
      ),

      // ═══════════════════════════════════
      // 🔘 ELEVATED BUTTON — Gradient effektli
      // ═══════════════════════════════════
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          disabledForegroundColor: const Color(0xFF94A3B8),
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shadowColor: _primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // ═══════════════════════════════════
      // ⭕ OUTLINED BUTTON
      // ═══════════════════════════════════
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // ═══════════════════════════════════
      // TEXT BUTTON
      // ═══════════════════════════════════
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // ═══════════════════════════════════
      // 📝 INPUT DECORATION — Zamonaviy, yumshoq
      // ═══════════════════════════════════
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _errorColor, width: 2),
        ),
        errorStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: const Color(0xFF94A3B8),
        suffixIconColor: const Color(0xFF94A3B8),
      ),

      // ═══════════════════════════════════
      // 🃏 CARD — Yumshoq soya, yumaloq
      // ═══════════════════════════════════
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
        color: _cardLight,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // ═══════════════════════════════════
      // 🧭 NAVIGATION BAR — Modern, chiroyli
      // ═══════════════════════════════════
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: _surfaceLight,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        indicatorColor: _primaryColor.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
              letterSpacing: 0.1,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: _primaryColor,
              size: 24,
            );
          }
          return const IconThemeData(
            color: Color(0xFF94A3B8),
            size: 22,
          );
        }),
      ),

      // ═══════════════════════════════════
      // ☑️ CHIP — Zamonaviy, yumshoq
      // ═══════════════════════════════════
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: _primaryColor.withValues(alpha: 0.12),
        disabledColor: const Color(0xFFF1F5F9),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ═══════════════════════════════════
      // 💬 DIALOG — Yumaloq burchakli
      // ═══════════════════════════════════
      dialogTheme: DialogThemeData(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: _surfaceLight,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
      ),

      // ═══════════════════════════════════
      // 📋 BOTTOM SHEET — Zamonaviy
      // ═══════════════════════════════════
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: _surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFFCBD5E1),
        dragHandleSize: Size(40, 4),
      ),

      // ═══════════════════════════════════
      // 🔔 SNACKBAR — Zamonaviy
      // ═══════════════════════════════════
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // ═══════════════════════════════════
      // ➗ DIVIDER
      // ═══════════════════════════════════
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF1F5F9),
        thickness: 1,
        space: 1,
      ),

      // ═══════════════════════════════════
      // 📊 PROGRESS INDICATOR
      // ═══════════════════════════════════
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryColor,
        linearTrackColor: Color(0xFFF1F5F9),
        circularTrackColor: Color(0xFFF1F5F9),
      ),

      // ═══════════════════════════════════
      // 🔲 FLOATING ACTION BUTTON
      // ═══════════════════════════════════
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ═══════════════════════════════════
      // 🎚️ SWITCH, SLIDER
      // ═══════════════════════════════════
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFFCBD5E1);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryColor;
          return const Color(0xFFE2E8F0);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ═══════════════════════════════════
      // 📜 LIST TILE
      // ═══════════════════════════════════
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        subtitleTextStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFF64748B),
        ),
        leadingAndTrailingTextStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
        ),
        iconColor: const Color(0xFF64748B),
      ),

      // ═══════════════════════════════════
      // 📑 TAB BAR
      // ═══════════════════════════════════
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: _primaryColor,
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: _primaryColor,
        dividerColor: const Color(0xFFF1F5F9),
      ),

      // ═══════════════════════════════════
      // 📌 TOOLTIP
      // ═══════════════════════════════════
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ═══════════════════════════════════
      // ⭐ BADGE
      // ═══════════════════════════════════
      badgeTheme: const BadgeThemeData(
        backgroundColor: _errorColor,
        textColor: Colors.white,
        textStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ═══════════════════════════════════
      // PAGE TRANSITION — Yumshoq
      // ═══════════════════════════════════
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // ═══════════════════════════════════
      // VISUAL DENSITY
      // ═══════════════════════════════════
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );
  }

  // ═══════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════
  static ThemeData get darkTheme {
    const bgDark = Color(0xFF0F172A);
    const surfaceDark = Color(0xFF1E293B);
    const cardDark = Color(0xFF1E293B);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _tertiaryColor,
      error: _errorColor,
      brightness: Brightness.dark,
      surface: surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgDark,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Roboto', 'sans-serif'],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: bgDark,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFFF1F5F9),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF1F5F9),
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: Color(0xFF334155),
            width: 1,
          ),
        ),
        color: cardDark,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _primaryColor.withValues(alpha: 0.2),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF818CF8),
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: Color(0xFF818CF8),
              size: 24,
            );
          }
          return const IconThemeData(
            color: Color(0xFF64748B),
            size: 22,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFF475569),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: const Color(0xFF334155),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
