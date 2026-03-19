// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Extension Methods
// ═══════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════
// STRING EXTENSIONS
// ═══════════════════════════════════

extension StringExtension on String {
  /// Birinchi harfni katta qilish: "hello" → "Hello"
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Har bir so'zni katta harfda boshlash: "hello world" → "Hello World"
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Bo'sh emasmi? (null va whitespace tekshiradi)
  bool get isNotBlank => trim().isNotEmpty;

  /// Bo'shmi?
  bool get isBlank => trim().isEmpty;

  /// Matnni qisqartirish: "Hello World Test" → "Hello World..."
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

// ═══════════════════════════════════
// NULLABLE STRING EXTENSIONS
// ═══════════════════════════════════

extension NullableStringExtension on String? {
  /// null yoki bo'sh string tekshirish.
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  /// null yoki bo'sh EMAS tekshirish.
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}

// ═══════════════════════════════════
// DATETIME EXTENSIONS
// ═══════════════════════════════════

extension DateTimeExtension on DateTime {
  /// DateTime → Firestore Timestamp.
  Timestamp get toTimestamp => Timestamp.fromDate(this);

  /// Faqat sana (vaqtsiz): DateTime(2026, 2, 13).
  DateTime get dateOnly => DateTime(year, month, day);

  /// Bugungi kunmi?
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Kechagi kunmi?
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}

// ═══════════════════════════════════
// TIMESTAMP EXTENSIONS
// ═══════════════════════════════════

extension TimestampExtension on Timestamp {
  /// Firestore Timestamp → DateTime.
  DateTime get toDateTime => toDate();
}

// ═══════════════════════════════════
// BUILD CONTEXT EXTENSIONS
// ═══════════════════════════════════

extension BuildContextExtension on BuildContext {
  /// Ekran kengligi.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Ekran balandligi.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Theme olish.
  ThemeData get theme => Theme.of(this);

  /// Color scheme olish.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Text theme olish.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// SnackBar ko'rsatish.
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  /// Success SnackBar.
  void showSuccess(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Error SnackBar.
  void showError(String message) {
    showSnackBar(message, isError: true);
  }
}

// ═══════════════════════════════════
// NUM EXTENSIONS
// ═══════════════════════════════════

extension NumExtension on num {
  /// Foizga aylantirish: 0.756 → "75.6%"
  String toPercentString({int decimals = 1}) {
    return '${(this * 100).toStringAsFixed(decimals)}%';
  }

  /// Kompakt formatda: 1500 → "1.5K", 1000000 → "1M"
  String toCompact() {
    if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}K';
    return toString();
  }
}

// ═══════════════════════════════════
// LIST EXTENSIONS
// ═══════════════════════════════════

extension ListExtension<T> on List<T> {
  /// Xavfsiz indeks bilan olish (IndexError bo'lmaydi).
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
