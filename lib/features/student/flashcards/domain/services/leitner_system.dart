// lib/features/flashcard/domain/services/leitner_system.dart
// So'zona — Leitner quti tizimi
// SM-2 ga muqobil — oddiyroq takrorlash tizimi
// 5 ta quti: quti raqami oshgan sari takrorlash intervali uzayadi

/// Leitner qutilari intervallari (soatlarda)
///
/// Quti 1: Har kuni (24 soat)
/// Quti 2: 3 kunda bir (72 soat)
/// Quti 3: Haftada bir (168 soat)
/// Quti 4: 2 haftada bir (336 soat)
/// Quti 5: Oyda bir (720 soat)
class LeitnerSystem {
  /// Quti intervallari (soatlarda)
  static const Map<int, int> boxIntervals = {
    1: 24, // 1 kun
    2: 72, // 3 kun
    3: 168, // 7 kun
    4: 336, // 14 kun
    5: 720, // 30 kun
  };

  /// To'g'ri javob — keyingi qutiga o'tish
  ///
  /// [currentBox] — hozirgi quti (1-5)
  /// Returns: yangi quti raqami va interval
  static LeitnerResult onCorrect(int currentBox) {
    final newBox = (currentBox + 1).clamp(1, 5);
    final intervalHours = boxIntervals[newBox] ?? 24;
    final nextReview = DateTime.now().add(Duration(hours: intervalHours));

    return LeitnerResult(
      box: newBox,
      intervalHours: intervalHours,
      nextReviewAt: nextReview,
    );
  }

  /// Noto'g'ri javob — birinchi qutiga qaytarish
  ///
  /// [currentBox] — hozirgi quti (1-5)
  /// Returns: quti 1 va 24 soat interval
  static LeitnerResult onIncorrect(int currentBox) {
    const newBox = 1;
    const intervalHours = 24;
    final nextReview = DateTime.now().add(
      const Duration(hours: intervalHours),
    );

    return LeitnerResult(
      box: newBox,
      intervalHours: intervalHours,
      nextReviewAt: nextReview,
    );
  }

  /// Quti raqamini interval soatlardan hisoblash
  static int getBoxFromInterval(int intervalHours) {
    if (intervalHours <= 24) return 1;
    if (intervalHours <= 72) return 2;
    if (intervalHours <= 168) return 3;
    if (intervalHours <= 336) return 4;
    return 5;
  }

  /// Quti nomini olish (UI uchun)
  static String getBoxLabel(int box) {
    switch (box) {
      case 1:
        return 'Yangi / Qiyin';
      case 2:
        return 'O\'rganilmoqda';
      case 3:
        return 'Yaxshi';
      case 4:
        return 'Oson';
      case 5:
        return 'O\'zlashtirilgan';
      default:
        return 'Noma\'lum';
    }
  }

  /// Quti rangini olish (UI uchun)
  static String getBoxEmoji(int box) {
    switch (box) {
      case 1:
        return '🔴';
      case 2:
        return '🟠';
      case 3:
        return '🟡';
      case 4:
        return '🟢';
      case 5:
        return '⭐';
      default:
        return '⚪';
    }
  }

  /// Interval vaqtini matn sifatida olish
  static String getIntervalText(int box) {
    switch (box) {
      case 1:
        return 'Har kuni';
      case 2:
        return '3 kunda bir';
      case 3:
        return 'Haftada bir';
      case 4:
        return '2 haftada bir';
      case 5:
        return 'Oyda bir';
      default:
        return 'Noma\'lum';
    }
  }
}

/// Leitner natijasi
class LeitnerResult {
  /// Yangi quti raqami (1-5)
  final int box;

  /// Interval (soatlarda)
  final int intervalHours;

  /// Keyingi takrorlash sanasi
  final DateTime nextReviewAt;

  const LeitnerResult({
    required this.box,
    required this.intervalHours,
    required this.nextReviewAt,
  });
}
