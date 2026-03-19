// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Date Utilities
// ═══════════════════════════════════════════════════════════════

import 'package:intl/intl.dart';

/// Sana va vaqt bilan ishlash uchun yordamchi funksiyalar.
class AppDateUtils {
  AppDateUtils._();

  // ═══════════════════════════════════
  // FORMATTERS
  // ═══════════════════════════════════

  /// "13-fevral, 2026" → to'liq sana.
  static String formatFull(DateTime date) {
    return DateFormat('d-MMMM, yyyy').format(date);
  }

  /// "13 fev" → qisqa sana.
  static String formatShort(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  /// "14:30" → vaqt.
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// "2026-02-13" → Firestore uchun string.
  static String formatForFirestore(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Firestore string dan DateTime ga.
  static DateTime parseFirestoreDate(String date) {
    return DateFormat('yyyy-MM-dd').parse(date);
  }

  // ═══════════════════════════════════
  // TIME AGO
  // ═══════════════════════════════════

  /// "5 daqiqa oldin", "2 soat oldin", "kecha" formatida.
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Hozirgina';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} daqiqa oldin';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} soat oldin';
    } else if (difference.inDays == 1) {
      return 'Kecha';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} kun oldin';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} hafta oldin';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} oy oldin';
    } else {
      return formatFull(dateTime);
    }
  }

  // ═══════════════════════════════════
  // COMPARISONS
  // ═══════════════════════════════════

  /// Bugun mi?
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Kecha mi?
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Ikki sana orasidagi kunlar.
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  /// Bugunning boshi (00:00:00).
  static DateTime get todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Bugunning oxiri (23:59:59).
  static DateTime get todayEnd {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  /// Oxirgi 30 kunlik sana ro'yxati (streak calendar uchun).
  static List<DateTime> getLast30Days() {
    final now = DateTime.now();
    return List.generate(
      30,
      (index) => DateTime(now.year, now.month, now.day - (29 - index)),
    );
  }

  // ═══════════════════════════════════
  // DURATION FORMATTING
  // ═══════════════════════════════════

  /// Sekundni "5:30" yoki "1:05:30" formatiga.
  static String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Daqiqani inson tushunadigan shaklga.
  /// 90 → "1 soat 30 daqiqa"
  static String formatMinutesHuman(int totalMinutes) {
    if (totalMinutes < 60) return '$totalMinutes daqiqa';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '$hours soat';
    return '$hours soat $minutes daqiqa';
  }
}
