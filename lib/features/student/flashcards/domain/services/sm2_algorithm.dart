// lib/features/flashcard/domain/services/sm2_algorithm.dart
// So'zona — SM-2 Spaced Repetition algoritmi
// SuperMemo 2 — Ebbinghaus unutish egri chizig'i asosida
// https://www.supermemo.com/en/archives1990-2015/english/ol/sm2

/// SM-2 algoritmi natijasi
class SM2Result {
  /// Yangi interval (kunlarda)
  final int intervalDays;

  /// Yangi "easiness factor" (qiyinlik koeffitsiyenti)
  final double easeFactor;

  /// Yangi takrorlash soni
  final int repetition;

  /// Keyingi takrorlash sanasi
  final DateTime nextReviewAt;

  const SM2Result({
    required this.intervalDays,
    required this.easeFactor,
    required this.repetition,
    required this.nextReviewAt,
  });
}

/// SM-2 Spaced Repetition algoritmi
///
/// Qoidalar:
/// - quality 0-2: Qaytadan boshlash (interval = 0)
/// - quality 3-5: Interval oshadi
/// - EF (Easiness Factor): 1.3 dan kam bo'lmaydi
///
/// Formulalar:
/// EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
/// interval(1) = 1 kun
/// interval(2) = 6 kun
/// interval(n) = interval(n-1) * EF
class SM2Algorithm {
  /// Kartochkani baholash va yangi parametrlarni hisoblash
  ///
  /// [quality] — 0 dan 5 gacha baholash:
  ///   0: To'liq unutilgan
  ///   1: Noto'g'ri — lekin ko'rganda esladi
  ///   2: Noto'g'ri — lekin oson eslash mumkin edi
  ///   3: To'g'ri — lekin qiyin edi
  ///   4: To'g'ri — biroz o'ylanish kerak bo'ldi
  ///   5: To'g'ri — mukammal, darhol esladi
  ///
  /// [repetition] — necha marta ketma-ket to'g'ri javob bergan
  /// [easeFactor] — hozirgi EF (default: 2.5)
  /// [previousInterval] — oldingi interval (kunlarda)
  static SM2Result calculate({
    required int quality,
    required int repetition,
    required double easeFactor,
    required int previousInterval,
  }) {
    assert(
      quality >= 0 && quality <= 5,
      'Quality 0-5 oralig\'ida bo\'lishi kerak',
    );

    int newRepetition;
    int newInterval;
    double newEaseFactor;

    // Noto'g'ri javob (quality < 3) — qaytadan boshlash
    if (quality < 3) {
      newRepetition = 0;
      newInterval = 0; // Darhol takrorlash
      newEaseFactor = easeFactor; // EF o'zgarmaydi
    } else {
      // To'g'ri javob
      newRepetition = repetition + 1;

      // Interval hisoblash
      if (newRepetition == 1) {
        newInterval = 1; // Birinchi marta — 1 kun
      } else if (newRepetition == 2) {
        newInterval = 6; // Ikkinchi marta — 6 kun
      } else {
        // Uchinchi marta va undan keyin
        newInterval = (previousInterval * easeFactor).round();
      }

      // EF yangilash
      newEaseFactor =
          easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

      // EF minimum 1.3
      if (newEaseFactor < 1.3) {
        newEaseFactor = 1.3;
      }
    }

    // Keyingi takrorlash sanasini hisoblash
    final now = DateTime.now();
    final nextReview = newInterval == 0
        ? now.add(const Duration(minutes: 10)) // 10 daqiqadan keyin
        : now.add(Duration(days: newInterval));

    return SM2Result(
      intervalDays: newInterval,
      easeFactor: newEaseFactor,
      repetition: newRepetition,
      nextReviewAt: nextReview,
    );
  }

  /// Qisqa SM-2 — faqat 4 ta tugma (Bilmadim, Qiyin, Oson, Mukammal)
  ///
  /// Foydalanuvchiga qulay mapping:
  /// Bilmadim → quality 1
  /// Qiyin    → quality 3
  /// Oson     → quality 4
  /// Mukammal → quality 5
  static SM2Result calculateSimple({
    required int quality,
    required int repetition,
    required double easeFactor,
    required int previousIntervalDays,
  }) {
    return calculate(
      quality: quality,
      repetition: repetition,
      easeFactor: easeFactor,
      previousInterval: previousIntervalDays,
    );
  }

  /// Interval vaqtini inson uchun tushunarli matnga aylantirish
  static String intervalToText(int days) {
    if (days == 0) return '10 daqiqa';
    if (days == 1) return '1 kun';
    if (days < 7) return '$days kun';
    if (days < 30) return '${(days / 7).round()} hafta';
    if (days < 365) return '${(days / 30).round()} oy';
    return '${(days / 365).round()} yil';
  }
}
