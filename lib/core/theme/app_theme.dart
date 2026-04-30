// ═══════════════════════════════════════════════════════════════
// SO'ZONA — App Theme (PROFESSIONAL)
// QO'YISH: lib/core/theme/app_theme.dart
// ✅ YANGILANDI: Yangi chiroyli ranglar bilan
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
  static const Color _primaryColor = Color(0xFF6C63FF); // Violet-Blue
  static const Color _secondaryColor = Color(0xFF2DD4BF); // Teal
  static const Color _tertiaryColor = Color(0xFFA78BFA); // Violet light
  static const Color _errorColor = Color(0xFFFF5252); // Red

  // Yumshoq fon ranglari — ko'zni charchatmaydi
  static const Color _bgLight = Color(0xFFF5F6FF); // Subtle violet tint
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

      // ═══════════════════════════════════
      // 📱 APP BAR — Shaffof, zamonaviy
      // ═══════════════════════════════════
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: _bgLight,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1D2E),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1D2E),
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF6B7280),
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
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
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
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
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
        fillColor: const Color(0xFFF0F0FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDDBFF), width: 1.5),
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
        prefixIconColor: const Color(0xFF9D97FF),
        suffixIconColor: const Color(0xFF9CA3AF),
      ),

      // ═══════════════════════════════════
      // 🃏 CARD — Yumshoq soya, yumaloq
      // ═══════════════════════════════════
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFFEEEDFF),
            width: 1.5,
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
        shadowColor: _primaryColor.withValues(alpha: 0.08),
        indicatorColor: _primaryColor.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6C63FF),
              letterSpacing: 0.1,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: Color(0xFF6C63FF),
              size: 24,
            );
          }
          return const IconThemeData(
            color: Color(0xFF9CA3AF),
            size: 22,
          );
        }),
      ),

      // ═══════════════════════════════════
      // ☑️ CHIP — Zamonaviy, yumshoq
      // ═══════════════════════════════════
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F0FF),
        selectedColor: _primaryColor.withValues(alpha: 0.15),
        disabledColor: const Color(0xFFF0F0FF),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFDDDBFF)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ═══════════════════════════════════
      // 💬 DIALOG — Yumaloq burchakli
      // ═══════════════════════════════════
      dialogTheme: DialogThemeData(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: _surfaceLight,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1D2E),
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
            top: Radius.circular(28),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFFDDDBFF),
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
        backgroundColor: const Color(0xFF1A1D2E),
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
        color: Color(0xFFEEEDFF),
        thickness: 1,
        space: 1,
      ),

      // ═══════════════════════════════════
      // 📊 PROGRESS INDICATOR
      // ═══════════════════════════════════
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryColor,
        linearTrackColor: Color(0xFFEEEDFF),
        circularTrackColor: Color(0xFFEEEDFF),
      ),

      // ═══════════════════════════════════
      // 🔲 FLOATING ACTION BUTTON
      // ═══════════════════════════════════
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
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
          color: Color(0xFF1A1D2E),
        ),
        subtitleTextStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
        ),
        leadingAndTrailingTextStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
        ),
        iconColor: const Color(0xFF9D97FF),
      ),

      // ═══════════════════════════════════
      // 📑 TAB BAR
      // ═══════════════════════════════════
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: _primaryColor,
        unselectedLabelColor: const Color(0xFF9CA3AF),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: _primaryColor,
        dividerColor: const Color(0xFFEEEDFF),
      ),

      // ═══════════════════════════════════
      // 📌 TOOLTIP
      // ═══════════════════════════════════
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
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
    const bgDark = Color(0xFF0F0E1A);
    const surfaceDark = Color(0xFF1A1929);
    const cardDark = Color(0xFF1E1D30);

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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFF2A2845),
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
          borderRadius: BorderRadius.circular(14),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9D97FF),
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
              color: Color(0xFF9D97FF),
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
        fillColor: const Color(0xFF252440),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3A3760)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIconColor: const Color(0xFF9D97FF),
        suffixIconColor: const Color(0xFF64748B),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2845),
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFF3A3760),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: const Color(0xFF252440),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF1F5F9),
        ),
        subtitleTextStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFF64748B),
        ),
        iconColor: const Color(0xFF9D97FF),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: const Color(0xFF9D97FF),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: const Color(0xFF9D97FF),
        dividerColor: const Color(0xFF2A2845),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFF64748B);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryColor;
          return const Color(0xFF334155);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF9D97FF),
        linearTrackColor: Color(0xFF2A2845),
        circularTrackColor: Color(0xFF2A2845),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF252440),
        selectedColor: _primaryColor.withValues(alpha: 0.25),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFFF1F5F9),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF3A3760)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: surfaceDark,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF1F5F9),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF252440),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: _errorColor,
        textColor: Colors.white,
        textStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
