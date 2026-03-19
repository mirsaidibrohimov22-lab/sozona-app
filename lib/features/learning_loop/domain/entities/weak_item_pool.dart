// QO'YISH: lib/features/learning_loop/domain/entities/weak_item_pool.dart
// So'zona — Zaif elementlar to'plami entity
// Student xato qilgan narsalar shu yerda saqlanadi

import 'package:equatable/equatable.dart';

/// Zaif element turi — qaysi moduldan kelgani
enum WeakItemSource {
  flashcard,
  quiz,
  listening,
  speaking,
  artikel,
}

/// Zaif element holati
enum WeakItemStatus {
  active, // Hali o'zlashtirilmagan
  mastered, // 3 marta ketma-ket to'g'ri → o'zlashtirildi
  dismissed, // Foydalanuvchi o'chirgan
}

/// Bitta zaif element — student xato qilgan so'z yoki qoida
class WeakItem extends Equatable {
  final String id;
  final String userId;

  /// Qaysi moduldan kelgani
  final WeakItemSource sourceType;

  /// Qaysi kontentdan (contentId)
  final String sourceContentId;

  /// Element turi: "word", "grammar_rule", "question", "artikel_word"
  final String itemType;

  /// Element ma'lumotlari
  final WeakItemData itemData;

  /// Necha marta xato qildi
  final int incorrectCount;

  /// Ketma-ket to'g'ri javoblar soni (3 bo'lsa → mastered)
  final int correctStreak;

  /// O'zlashtirish darajasi (0-100)
  final int masteryScore;

  /// Keyingi qayta ko'rib chiqish vaqti (spaced repetition)
  final DateTime nextReviewAt;

  /// Hozirgi interval (kun)
  /// 0→1, 1→3, 2→7, 3→mastered
  final int intervalDays;

  /// Holat
  final WeakItemStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  const WeakItem({
    required this.id,
    required this.userId,
    required this.sourceType,
    required this.sourceContentId,
    required this.itemType,
    required this.itemData,
    this.incorrectCount = 1,
    this.correctStreak = 0,
    this.masteryScore = 0,
    required this.nextReviewAt,
    this.intervalDays = 1,
    this.status = WeakItemStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Hozir ko'rib chiqish vaqti kelganmi?
  bool get isDueForReview =>
      status == WeakItemStatus.active && DateTime.now().isAfter(nextReviewAt);

  /// To'g'ri javob berilganda yangilash
  WeakItem markCorrect() {
    final newStreak = correctStreak + 1;
    final newMastery = (masteryScore + 25).clamp(0, 100);

    // 3 marta ketma-ket to'g'ri → mastered
    if (newStreak >= 3) {
      return copyWith(
        correctStreak: newStreak,
        masteryScore: 100,
        status: WeakItemStatus.mastered,
        updatedAt: DateTime.now(),
      );
    }

    // Spaced repetition intervalini oshirish
    final newInterval = _nextInterval(newStreak);
    final nextReview = DateTime.now().add(Duration(days: newInterval));

    return copyWith(
      correctStreak: newStreak,
      masteryScore: newMastery,
      intervalDays: newInterval,
      nextReviewAt: nextReview,
      updatedAt: DateTime.now(),
    );
  }

  /// Xato javob berilganda yangilash
  WeakItem markIncorrect() {
    final newMastery = (masteryScore - 15).clamp(0, 100);
    // Xato bo'lsa — ertaga qayta ko'rib chiqish
    final nextReview = DateTime.now().add(const Duration(days: 1));

    return copyWith(
      incorrectCount: incorrectCount + 1,
      correctStreak: 0, // Streak nolga tushadi
      masteryScore: newMastery,
      intervalDays: 1,
      nextReviewAt: nextReview,
      updatedAt: DateTime.now(),
    );
  }

  /// Spaced repetition: streak ga qarab keyingi interval
  int _nextInterval(int streak) {
    switch (streak) {
      case 1:
        return 3; // 3 kun
      case 2:
        return 7; // 7 kun
      default:
        return 14; // 14 kun
    }
  }

  WeakItem copyWith({
    String? id,
    String? userId,
    WeakItemSource? sourceType,
    String? sourceContentId,
    String? itemType,
    WeakItemData? itemData,
    int? incorrectCount,
    int? correctStreak,
    int? masteryScore,
    DateTime? nextReviewAt,
    int? intervalDays,
    WeakItemStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeakItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sourceType: sourceType ?? this.sourceType,
      sourceContentId: sourceContentId ?? this.sourceContentId,
      itemType: itemType ?? this.itemType,
      itemData: itemData ?? this.itemData,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      correctStreak: correctStreak ?? this.correctStreak,
      masteryScore: masteryScore ?? this.masteryScore,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      intervalDays: intervalDays ?? this.intervalDays,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        sourceType,
        sourceContentId,
        itemType,
        incorrectCount,
        correctStreak,
        masteryScore,
        status,
      ];
}

/// Zaif element ma'lumotlari
class WeakItemData extends Equatable {
  /// So'z yoki qoida matni
  final String term;

  /// Tarjimasi (ixtiyoriy)
  final String? translation;

  /// Misol gap (ixtiyoriy)
  final String? context;

  /// To'g'ri javob
  final String? correctAnswer;

  const WeakItemData({
    required this.term,
    this.translation,
    this.context,
    this.correctAnswer,
  });

  @override
  List<Object?> get props => [term, translation, context, correctAnswer];
}

/// Zaif elementlar to'plami (pool)
class WeakItemPool extends Equatable {
  final String userId;
  final List<WeakItem> items;

  const WeakItemPool({
    required this.userId,
    required this.items,
  });

  /// Hozir ko'rib chiqish kerak bo'lgan elementlar
  List<WeakItem> get dueItems =>
      items.where((item) => item.isDueForReview).toList();

  /// Faol elementlar soni
  int get activeCount =>
      items.where((e) => e.status == WeakItemStatus.active).length;

  /// O'zlashtirilgan elementlar soni
  int get masteredCount =>
      items.where((e) => e.status == WeakItemStatus.mastered).length;

  /// Pool bo'shmi
  bool get isEmpty => dueItems.isEmpty;

  @override
  List<Object?> get props => [userId, items];
}
