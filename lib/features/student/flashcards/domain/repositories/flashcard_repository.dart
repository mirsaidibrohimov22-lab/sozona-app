// lib/features/flashcard/domain/repositories/flashcard_repository.dart
// So'zona — Flashcard repository interfeysi
// Domain qatlami — Data qatlamiga bog'liq emas

import 'package:dartz/dartz.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/folder_entity.dart';

/// Flashcard repository shartnomasi
abstract class FlashcardRepository {
  // ─── PAPKA (Folder) operatsiyalari ───

  /// Foydalanuvchi papkalarini olish
  Future<Either<Failure, List<FolderEntity>>> getFolders({
    required String userId,
  });

  /// Bitta papka olish
  Future<Either<Failure, FolderEntity>> getFolderById({
    required String folderId,
  });

  /// Yangi papka yaratish
  Future<Either<Failure, FolderEntity>> createFolder({
    required String userId,
    required String name,
    String? description,
    FolderColor color,
    String? emoji,
    String language,
    String? cefrLevel,
  });

  /// Papka yangilash
  Future<Either<Failure, FolderEntity>> updateFolder({
    required FolderEntity folder,
  });

  /// Papka o'chirish (soft delete)
  Future<Either<Failure, void>> deleteFolder({
    required String folderId,
  });

  // ─── KARTOCHKA (Flashcard) operatsiyalari ───

  /// Papkadagi kartochkalarni olish
  Future<Either<Failure, List<FlashcardEntity>>> getCards({
    required String folderId,
  });

  /// Takrorlashga tayyor kartochkalarni olish
  Future<Either<Failure, List<FlashcardEntity>>> getDueCards({
    required String userId,
    int limit,
  });

  /// Zaif kartochkalarni olish (accuracy < 50%)
  Future<Either<Failure, List<FlashcardEntity>>> getWeakCards({
    required String userId,
    int limit,
  });

  /// Bitta kartochka olish
  Future<Either<Failure, FlashcardEntity>> getCardById({
    required String cardId,
  });

  /// Yangi kartochka yaratish
  Future<Either<Failure, FlashcardEntity>> createCard({
    required String folderId,
    required String userId,
    required String front,
    required String back,
    String? example,
    String? pronunciation,
    String? cefrLevel,
    String? wordType,
    String? artikel,
  });

  /// Bir nechta kartochka yaratish (AI generatsiya uchun)
  Future<Either<Failure, List<FlashcardEntity>>> createCards({
    required String folderId,
    required String userId,
    required List<Map<String, String>> cards,
  });

  /// Kartochka yangilash
  Future<Either<Failure, FlashcardEntity>> updateCard({
    required FlashcardEntity card,
  });

  /// Kartochka o'chirish (soft delete)
  Future<Either<Failure, void>> deleteCard({
    required String cardId,
  });

  // ─── TAKRORLASH (Review) operatsiyalari ───

  /// Kartochka takrorlash natijasini saqlash
  /// [quality] — 0 (umuman bilmadi) dan 5 (mukammal) gacha
  Future<Either<Failure, FlashcardEntity>> reviewCard({
    required String cardId,
    required int quality,
  });

  // ─── QIDIRUV ───

  /// Kartochkalarni qidirish
  Future<Either<Failure, List<FlashcardEntity>>> searchCards({
    required String userId,
    required String query,
  });

  // ─── STATISTIKA ───

  /// Foydalanuvchi flashcard statistikasi
  Future<Either<Failure, FlashcardStats>> getStats({
    required String userId,
  });
}

/// Flashcard statistikasi
class FlashcardStats {
  /// Jami kartochkalar soni
  final int totalCards;

  /// O'zlashtirilgan kartochkalar
  final int masteredCards;

  /// Takrorlashga tayyor
  final int dueCards;

  /// Zaif kartochkalar
  final int weakCards;

  /// Bugungi takrorlashlar
  final int todayReviewed;

  /// Umumiy to'g'ri javoblar foizi
  final double overallAccuracy;

  /// Papkalar soni
  final int totalFolders;

  const FlashcardStats({
    this.totalCards = 0,
    this.masteredCards = 0,
    this.dueCards = 0,
    this.weakCards = 0,
    this.todayReviewed = 0,
    this.overallAccuracy = 0,
    this.totalFolders = 0,
  });
}
