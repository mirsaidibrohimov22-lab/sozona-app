// lib/features/flashcard/domain/entities/flashcard_entity.dart
// So'zona — Flashcard domain entity
// Ebbinghaus unutish egri chizig'i asosida takrorlash tizimi

import 'package:equatable/equatable.dart';

/// Flashcard bilish darajasi (Spaced Repetition)
enum CardDifficulty {
  /// Yangi — hali ko'rilmagan
  newCard,

  /// Qiyin — tez-tez takrorlash kerak
  hard,

  /// O'rtacha — normal takrorlash
  medium,

  /// Oson — kam takrorlash
  easy,

  /// O'zlashtirilgan — juda kam takrorlash
  mastered,
}

/// Flashcard entity
class FlashcardEntity extends Equatable {
  /// Yagona identifikator
  final String id;

  /// Papka identifikatori
  final String folderId;

  /// Foydalanuvchi identifikatori
  final String userId;

  /// Old tomon — o'rganiladigan so'z (inglizcha/nemischa)
  final String front;

  /// Orqa tomon — tarjima (o'zbekcha)
  final String back;

  /// Qo'shimcha misol gap (ixtiyoriy)
  final String? example;

  /// Talaffuz (phonetic/IPA)
  final String? pronunciation;

  /// Rasm URL (ixtiyoriy)
  final String? imageUrl;

  /// Audio URL (ixtiyoriy — TTS uchun)
  final String? audioUrl;

  /// Qiyinlik darajasi (spaced repetition)
  final CardDifficulty difficulty;

  /// Takrorlash intervali (soatlarda)
  final int intervalHours;

  /// Keyingi takrorlash sanasi
  final DateTime nextReviewAt;

  /// Necha marta ko'rilgan
  final int reviewCount;

  /// Necha marta to'g'ri javob berilgan
  final int correctCount;

  /// Necha marta noto'g'ri javob berilgan
  final int incorrectCount;

  /// Ebbinghaus "easiness factor" (2.5 default)
  final double easeFactor;

  /// Yaratilgan sana
  final DateTime createdAt;

  /// Yangilangan sana
  final DateTime updatedAt;

  /// Oxirgi takrorlash sanasi
  final DateTime? lastReviewedAt;

  /// O'chirilganmi (soft delete)
  final bool isDeleted;

  /// CEFR darajasi (A1-C1)
  final String? cefrLevel;

  /// So'z turi (noun, verb, adjective va h.k.)
  final String? wordType;

  /// Nemis tili uchun artikel (der/die/das)
  final String? artikel;

  const FlashcardEntity({
    required this.id,
    required this.folderId,
    required this.userId,
    required this.front,
    required this.back,
    this.example,
    this.pronunciation,
    this.imageUrl,
    this.audioUrl,
    this.difficulty = CardDifficulty.newCard,
    this.intervalHours = 0,
    required this.nextReviewAt,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.easeFactor = 2.5,
    required this.createdAt,
    required this.updatedAt,
    this.lastReviewedAt,
    this.isDeleted = false,
    this.cefrLevel,
    this.wordType,
    this.artikel,
  });

  /// Takrorlash vaqti keldimi?
  bool get isDueForReview => DateTime.now().isAfter(nextReviewAt);

  /// To'g'ri javob foizi
  double get accuracy {
    if (reviewCount == 0) return 0;
    return correctCount / reviewCount;
  }

  /// O'zlashtirilganmi?
  bool get isMastered => difficulty == CardDifficulty.mastered;

  /// Yangi kartochkami?
  bool get isNew => difficulty == CardDifficulty.newCard;

  /// Zaif kartochkami? (accuracy < 50%)
  bool get isWeak => reviewCount >= 3 && accuracy < 0.5;

  /// Nemis tili artikeli bormi?
  bool get hasArtikel => artikel != null && artikel!.isNotEmpty;

  /// Nusxa yaratish
  FlashcardEntity copyWith({
    String? id,
    String? folderId,
    String? userId,
    String? front,
    String? back,
    String? example,
    String? pronunciation,
    String? imageUrl,
    String? audioUrl,
    CardDifficulty? difficulty,
    int? intervalHours,
    DateTime? nextReviewAt,
    int? reviewCount,
    int? correctCount,
    int? incorrectCount,
    double? easeFactor,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastReviewedAt,
    bool? isDeleted,
    String? cefrLevel,
    String? wordType,
    String? artikel,
  }) {
    return FlashcardEntity(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      userId: userId ?? this.userId,
      front: front ?? this.front,
      back: back ?? this.back,
      example: example ?? this.example,
      pronunciation: pronunciation ?? this.pronunciation,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      difficulty: difficulty ?? this.difficulty,
      intervalHours: intervalHours ?? this.intervalHours,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      easeFactor: easeFactor ?? this.easeFactor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      wordType: wordType ?? this.wordType,
      artikel: artikel ?? this.artikel,
    );
  }

  @override
  List<Object?> get props => [
        id,
        folderId,
        userId,
        front,
        back,
        example,
        pronunciation,
        imageUrl,
        audioUrl,
        difficulty,
        intervalHours,
        nextReviewAt,
        reviewCount,
        correctCount,
        incorrectCount,
        easeFactor,
        createdAt,
        updatedAt,
        lastReviewedAt,
        isDeleted,
        cefrLevel,
        wordType,
        artikel,
      ];
}
