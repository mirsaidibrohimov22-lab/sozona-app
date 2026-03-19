// lib/features/flashcard/data/models/flashcard_model.dart
// So'zona — Flashcard data modeli
// Firestore va SQLite bilan ishlash uchun serializatsiya

import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';

/// Flashcard data modeli — Entity'dan meros oladi
class FlashcardModel extends FlashcardEntity {
  const FlashcardModel({
    required super.id,
    required super.folderId,
    required super.userId,
    required super.front,
    required super.back,
    super.example,
    super.pronunciation,
    super.imageUrl,
    super.audioUrl,
    super.difficulty,
    super.intervalHours,
    required super.nextReviewAt,
    super.reviewCount,
    super.correctCount,
    super.incorrectCount,
    super.easeFactor,
    required super.createdAt,
    required super.updatedAt,
    super.lastReviewedAt,
    super.isDeleted,
    super.cefrLevel,
    super.wordType,
    super.artikel,
  });

  /// Firestore hujjatidan yaratish
  factory FlashcardModel.fromFirestore(
    Map<String, dynamic> map,
    String docId,
  ) {
    return FlashcardModel(
      id: docId,
      folderId: map['folderId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      front: map['front'] as String? ?? '',
      back: map['back'] as String? ?? '',
      example: map['example'] as String?,
      pronunciation: map['pronunciation'] as String?,
      imageUrl: map['imageUrl'] as String?,
      audioUrl: map['audioUrl'] as String?,
      difficulty: _parseDifficulty(map['difficulty'] as String?),
      intervalHours: map['intervalHours'] as int? ?? 0,
      nextReviewAt: _parseDateTime(map['nextReviewAt']),
      reviewCount: map['reviewCount'] as int? ?? 0,
      correctCount: map['correctCount'] as int? ?? 0,
      incorrectCount: map['incorrectCount'] as int? ?? 0,
      easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      lastReviewedAt: map['lastReviewedAt'] != null
          ? _parseDateTime(map['lastReviewedAt'])
          : null,
      isDeleted: map['isDeleted'] as bool? ?? false,
      cefrLevel: map['cefrLevel'] as String?,
      wordType: map['wordType'] as String?,
      artikel: map['artikel'] as String?,
    );
  }

  /// Firestore'ga yozish uchun Map
  Map<String, dynamic> toFirestore() {
    return {
      'folderId': folderId,
      'userId': userId,
      'front': front,
      'back': back,
      'example': example,
      'pronunciation': pronunciation,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'difficulty': difficulty.name,
      'intervalHours': intervalHours,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'reviewCount': reviewCount,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'easeFactor': easeFactor,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'cefrLevel': cefrLevel,
      'wordType': wordType,
      'artikel': artikel,
    };
  }

  /// SQLite'dan o'qish
  factory FlashcardModel.fromSqlite(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as String,
      folderId: map['folderId'] as String,
      userId: map['userId'] as String,
      front: map['front'] as String,
      back: map['back'] as String,
      example: map['example'] as String?,
      pronunciation: map['pronunciation'] as String?,
      imageUrl: map['imageUrl'] as String?,
      audioUrl: map['audioUrl'] as String?,
      difficulty: _parseDifficulty(map['difficulty'] as String?),
      intervalHours: map['intervalHours'] as int? ?? 0,
      nextReviewAt: DateTime.parse(map['nextReviewAt'] as String),
      reviewCount: map['reviewCount'] as int? ?? 0,
      correctCount: map['correctCount'] as int? ?? 0,
      incorrectCount: map['incorrectCount'] as int? ?? 0,
      easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      lastReviewedAt: map['lastReviewedAt'] != null
          ? DateTime.parse(map['lastReviewedAt'] as String)
          : null,
      isDeleted: (map['isDeleted'] as int?) == 1,
      cefrLevel: map['cefrLevel'] as String?,
      wordType: map['wordType'] as String?,
      artikel: map['artikel'] as String?,
    );
  }

  /// SQLite'ga yozish uchun Map
  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'folderId': folderId,
      'userId': userId,
      'front': front,
      'back': back,
      'example': example,
      'pronunciation': pronunciation,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'difficulty': difficulty.name,
      'intervalHours': intervalHours,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'reviewCount': reviewCount,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'easeFactor': easeFactor,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'cefrLevel': cefrLevel,
      'wordType': wordType,
      'artikel': artikel,
    };
  }

  /// Entity'dan model yaratish
  factory FlashcardModel.fromEntity(FlashcardEntity entity) {
    return FlashcardModel(
      id: entity.id,
      folderId: entity.folderId,
      userId: entity.userId,
      front: entity.front,
      back: entity.back,
      example: entity.example,
      pronunciation: entity.pronunciation,
      imageUrl: entity.imageUrl,
      audioUrl: entity.audioUrl,
      difficulty: entity.difficulty,
      intervalHours: entity.intervalHours,
      nextReviewAt: entity.nextReviewAt,
      reviewCount: entity.reviewCount,
      correctCount: entity.correctCount,
      incorrectCount: entity.incorrectCount,
      easeFactor: entity.easeFactor,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastReviewedAt: entity.lastReviewedAt,
      isDeleted: entity.isDeleted,
      cefrLevel: entity.cefrLevel,
      wordType: entity.wordType,
      artikel: entity.artikel,
    );
  }

  /// Qiyinlik darajasini parse qilish
  static CardDifficulty _parseDifficulty(String? value) {
    switch (value) {
      case 'hard':
        return CardDifficulty.hard;
      case 'medium':
        return CardDifficulty.medium;
      case 'easy':
        return CardDifficulty.easy;
      case 'mastered':
        return CardDifficulty.mastered;
      default:
        return CardDifficulty.newCard;
    }
  }

  /// DateTime parse qilish — Firestore Timestamp yoki String
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    // Firestore Timestamp uchun
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }
}
