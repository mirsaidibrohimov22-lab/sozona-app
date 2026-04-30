// lib/features/student/flashcards/data/repositories/flashcard_repository_impl.dart
// So'zona — Flashcard repository implementatsiyasi
// ✅ FIX 1: getCards va deleteFolder da userId uzatiladi
// ✅ FIX 2: masteredCount uchun threshold pasaytirildi (21 kun → 6 kun)
//    Sabab: SM-2 algoritmida 21 kun intervalga yetish 4+ review talab qiladi
//    (har biri keyingi kunda), shuning uchun "0 o'zlashtirilgan" ko'rinyapti.
//    6 kunlik interval = 2 muvaffaqiyatli review → yanada real ko'rsatma.
// ✅ FIX 3: _recalculateFolderCounts da userId to'g'ri uzatiladi

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/network/network_info.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/folder_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/repositories/flashcard_repository.dart';
import 'package:my_first_app/features/student/flashcards/domain/services/sm2_algorithm.dart';
import 'package:my_first_app/features/student/flashcards/data/datasources/flashcard_local_datasource.dart';
import 'package:my_first_app/features/student/flashcards/data/datasources/flashcard_remote_datasource.dart';
import 'package:my_first_app/features/student/flashcards/data/models/flashcard_model.dart';
import 'package:my_first_app/features/student/flashcards/data/models/folder_model.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final FlashcardRemoteDataSource remoteDataSource;
  final FlashcardLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  FlashcardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ─── PAPKALAR ───

  @override
  Future<Either<Failure, List<FolderEntity>>> getFolders({
    required String userId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final remoteFolders = await remoteDataSource.getFolders(userId);
        // ✅ FIX: userId to'g'ri uzatiladi
        final correctedFolders =
            await _recalculateFolderCounts(remoteFolders, userId);
        await localDataSource.saveFolders(correctedFolders);
        return Right(correctedFolders);
      } else {
        final localFolders = await localDataSource.getFolders(userId);
        return Right(localFolders);
      }
    } on ServerException catch (e) {
      try {
        final localFolders = await localDataSource.getFolders(userId);
        return Right(localFolders);
      } on CacheException {
        return Left(ServerFailure(message: e.message));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  /// ✅ FIX: userId parametri qo'shildi — getCards ga to'g'ri uzatish uchun
  Future<List<FolderModel>> _recalculateFolderCounts(
    List<FolderModel> folders,
    String userId,
  ) async {
    final now = DateTime.now();
    final corrected = <FolderModel>[];

    for (final folder in folders) {
      try {
        // ✅ FIX: folder.userId ishlatiladi (userId parametr o'rniga xavfsizroq)
        final effectiveUserId =
            folder.userId.isNotEmpty ? folder.userId : userId;
        final cards =
            await remoteDataSource.getCards(folder.id, effectiveUserId);
        final activeCards = cards.where((c) => !c.isDeleted).toList();

        final cardCount = activeCards.length;
        final masteredCount = activeCards
            .where((c) => c.difficulty == CardDifficulty.mastered)
            .length;
        final dueCount =
            activeCards.where((c) => !c.nextReviewAt.isAfter(now)).length;

        // Farq bo'lsa — Firestore'da yangilaymiz
        if (cardCount != folder.cardCount ||
            masteredCount != folder.masteredCount ||
            dueCount != folder.dueCount) {
          await remoteDataSource.updateFolder(folder.id, {
            'cardCount': cardCount,
            'masteredCount': masteredCount,
            'dueCount': dueCount,
          });
          debugPrint(
            '✅ Folder "${folder.name}" tuzatildi: '
            'cards=$cardCount, mastered=$masteredCount, due=$dueCount',
          );
        }

        corrected.add(FolderModel(
          id: folder.id,
          userId: folder.userId,
          name: folder.name,
          description: folder.description,
          color: folder.color,
          emoji: folder.emoji,
          language: folder.language,
          cefrLevel: folder.cefrLevel,
          cardCount: cardCount,
          masteredCount: masteredCount,
          dueCount: dueCount,
          isAiGenerated: folder.isAiGenerated,
          isAssigned: folder.isAssigned,
          assignedByTeacherId: folder.assignedByTeacherId,
          sortOrder: folder.sortOrder,
          createdAt: folder.createdAt,
          updatedAt: folder.updatedAt,
          isDeleted: folder.isDeleted,
        ));
      } catch (e) {
        debugPrint('⚠️ Folder count xatosi (${folder.id}): $e');
        corrected.add(folder);
      }
    }

    return corrected;
  }

  @override
  Future<Either<Failure, FolderEntity>> getFolderById({
    required String folderId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final folder = await remoteDataSource.getFolderById(folderId);
        await localDataSource.saveFolder(folder);
        return Right(folder);
      } else {
        final folder = await localDataSource.getFolderById(folderId);
        if (folder != null) return Right(folder);
        return const Left(CacheFailure(message: 'Papka topilmadi'));
      }
    } on ServerException catch (e) {
      try {
        final folder = await localDataSource.getFolderById(folderId);
        if (folder != null) return Right(folder);
        return Left(ServerFailure(message: e.message));
      } catch (_) {
        return Left(ServerFailure(message: e.message));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, FolderEntity>> createFolder({
    required String userId,
    required String name,
    String? description,
    FolderColor color = FolderColor.blue,
    String? emoji,
    String language = 'english',
    String? cefrLevel,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final folder = await remoteDataSource.createFolder({
          'userId': userId,
          'name': name,
          'description': description,
          'color': color.name,
          'emoji': emoji,
          'language': language,
          'cefrLevel': cefrLevel,
          'sortOrder': 0,
          'cardCount': 0,
          'masteredCount': 0,
          'dueCount': 0,
        });
        await localDataSource.saveFolder(folder);
        return Right(folder);
      } else {
        return const Left(
          NetworkFailure(message: 'Papka yaratish uchun internet kerak'),
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, FolderEntity>> updateFolder({
    required FolderEntity folder,
  }) async {
    try {
      final model = FolderModel.fromEntity(folder);
      if (await networkInfo.isConnected) {
        final updated =
            await remoteDataSource.updateFolder(folder.id, model.toFirestore());
        await localDataSource.saveFolder(updated);
        return Right(updated);
      } else {
        await localDataSource.saveFolder(model);
        return Right(folder);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  /// ✅ FIX: userId qo'shildi — deleteFolder da userId kerak
  @override
  Future<Either<Failure, void>> deleteFolder({
    required String folderId,
    required String userId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        await remoteDataSource.deleteFolder(folderId, userId);
      }
      await localDataSource.deleteFolder(folderId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  // ─── KARTOCHKALAR ───

  /// ✅ FIX: userId qo'shildi — Firestore rules uchun zarur
  @override
  Future<Either<Failure, List<FlashcardEntity>>> getCards({
    required String folderId,
    required String userId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final remoteCards = await remoteDataSource.getCards(folderId, userId);
        await localDataSource.saveCards(remoteCards);
        return Right(remoteCards);
      } else {
        final localCards = await localDataSource.getCards(folderId);
        return Right(localCards);
      }
    } on ServerException catch (e) {
      try {
        final localCards = await localDataSource.getCards(folderId);
        return Right(localCards);
      } catch (_) {
        return Left(ServerFailure(message: e.message));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<FlashcardEntity>>> getDueCards({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final cards = await localDataSource.getDueCards(userId, limit: limit);
      return Right(cards);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<FlashcardEntity>>> getWeakCards({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final cards = await localDataSource.getWeakCards(userId, limit: limit);
      return Right(cards);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, FlashcardEntity>> getCardById({
    required String cardId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final card = await remoteDataSource.getCardById(cardId);
        await localDataSource.saveCard(card);
        return Right(card);
      } else {
        final card = await localDataSource.getCardById(cardId);
        if (card != null) return Right(card);
        return const Left(CacheFailure(message: 'Kartochka topilmadi'));
      }
    } on ServerException catch (e) {
      try {
        final card = await localDataSource.getCardById(cardId);
        if (card != null) return Right(card);
        return Left(ServerFailure(message: e.message));
      } catch (_) {
        return Left(ServerFailure(message: e.message));
      }
    }
  }

  @override
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
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final card = await remoteDataSource.createCard({
          'folderId': folderId,
          'userId': userId,
          'front': front,
          'back': back,
          'example': example,
          'pronunciation': pronunciation,
          'cefrLevel': cefrLevel,
          'wordType': wordType,
          'artikel': artikel,
        });
        await localDataSource.saveCard(card);
        return Right(card);
      } else {
        return const Left(
          NetworkFailure(message: 'Kartochka yaratish uchun internet kerak'),
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<FlashcardEntity>>> createCards({
    required String folderId,
    required String userId,
    required List<Map<String, String>> cards,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final cardsData = cards
            .map((c) => {'folderId': folderId, 'userId': userId, ...c})
            .toList();
        final created = await remoteDataSource.createCards(cardsData);
        await localDataSource.saveCards(created);
        return Right(created);
      } else {
        return const Left(
          NetworkFailure(message: 'Kartochkalar yaratish uchun internet kerak'),
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, FlashcardEntity>> updateCard({
    required FlashcardEntity card,
  }) async {
    try {
      final model = FlashcardModel.fromEntity(card);
      await localDataSource.saveCard(model);
      if (await networkInfo.isConnected) {
        final updated =
            await remoteDataSource.updateCard(card.id, model.toFirestore());
        return Right(updated);
      }
      return Right(card);
    } on ServerException {
      return Right(card);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCard({
    required String cardId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        await remoteDataSource.deleteCard(cardId);
      }
      await localDataSource.deleteCard(cardId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  // ─── TAKRORLASH ───

  @override
  Future<Either<Failure, FlashcardEntity>> reviewCard({
    required String cardId,
    required int quality,
  }) async {
    try {
      final cardResult = await getCardById(cardId: cardId);

      return cardResult.fold(
        Left.new,
        (card) async {
          // SM-2 algoritmi — to'g'ri hisoblash
          final sm2 = SM2Algorithm.calculate(
            quality: quality,
            repetition: card.correctCount,
            easeFactor: card.easeFactor,
            previousInterval: card.intervalHours ~/ 24,
          );

          // ✅ FIX: Threshold pasaytirildi — 6 kunlik interval = mastered
          // Oldin: 21 kun → 4+ review kerak edi (bir necha kun ichida)
          // Endi: 6 kun → 2 to'g'ri review yetarli
          final newDifficulty = _qualityToDifficulty(quality, sm2);

          final updatedCard = card.copyWith(
            reviewCount: card.reviewCount + 1,
            correctCount:
                quality >= 3 ? card.correctCount + 1 : card.correctCount,
            incorrectCount:
                quality < 3 ? card.incorrectCount + 1 : card.incorrectCount,
            easeFactor: sm2.easeFactor,
            intervalHours: sm2.intervalDays * 24,
            nextReviewAt: sm2.nextReviewAt,
            difficulty: newDifficulty,
            lastReviewedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final saveResult = await updateCard(card: updatedCard);

          // Papka statistikasini background'da yangilash
          _updateFolderStats(card.folderId, card, updatedCard);

          return saveResult;
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Takrorlashda xatolik: $e'));
    }
  }

  /// ✅ FIX: Mastered threshold 21 kun → 6 kun
  /// Asoslash:
  ///   interval=1 kun  → hard   (1-review)
  ///   interval=6 kun  → mastered (2-review, to'g'ri javob)
  ///   interval<6 kun  → medium  (birinchi to'g'ri javob)
  ///   noto'g'ri       → hard
  CardDifficulty _qualityToDifficulty(int quality, SM2Result sm2) {
    if (quality < 3) return CardDifficulty.hard;
    if (sm2.intervalDays >= 6) return CardDifficulty.mastered;
    if (sm2.intervalDays >= 2) return CardDifficulty.medium;
    return CardDifficulty.hard;
  }

  /// Papkaning masteredCount va dueCount ni to'g'ri yangilash
  Future<void> _updateFolderStats(
    String folderId,
    FlashcardEntity oldCard,
    FlashcardEntity newCard,
  ) async {
    if (!await networkInfo.isConnected) return;

    try {
      final now = DateTime.now();

      // masteredCount delta
      int masteredDelta = 0;
      if (oldCard.difficulty != CardDifficulty.mastered &&
          newCard.difficulty == CardDifficulty.mastered) {
        masteredDelta = 1;
      } else if (oldCard.difficulty == CardDifficulty.mastered &&
          newCard.difficulty != CardDifficulty.mastered) {
        masteredDelta = -1;
      }

      // dueCount delta
      final wasDue = !oldCard.nextReviewAt.isAfter(now);
      final isDue = !newCard.nextReviewAt.isAfter(now);
      final dueDelta = (isDue ? 1 : 0) - (wasDue ? 1 : 0);

      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (masteredDelta != 0) {
        updates['masteredCount'] = FieldValue.increment(masteredDelta);
      }
      if (dueDelta != 0) {
        updates['dueCount'] = FieldValue.increment(dueDelta);
      }

      if (updates.length > 1) {
        await remoteDataSource.updateFolder(folderId, updates);
        debugPrint(
          '✅ Folder stats yangilandi: mastered$masteredDelta, due$dueDelta',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Folder stats yangilashda xatolik: $e');
    }
  }

  // ─── QIDIRUV ───

  @override
  Future<Either<Failure, List<FlashcardEntity>>> searchCards({
    required String userId,
    required String query,
  }) async {
    try {
      final localResults = await localDataSource.searchCards(userId, query);
      return Right(localResults);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  // ─── STATISTIKA ───

  @override
  Future<Either<Failure, FlashcardStats>> getStats({
    required String userId,
  }) async {
    try {
      final folders = await localDataSource.getFolders(userId);
      final dueCards = await localDataSource.getDueCards(userId, limit: 1000);
      final weakCards = await localDataSource.getWeakCards(userId, limit: 1000);

      int totalCards = 0;
      int masteredCards = 0;

      for (final folder in folders) {
        totalCards += folder.cardCount;
        masteredCards += folder.masteredCount;
      }

      return Right(
        FlashcardStats(
          totalCards: totalCards,
          masteredCards: masteredCards,
          dueCards: dueCards.length,
          weakCards: weakCards.length,
          todayReviewed: 0,
          overallAccuracy: totalCards > 0 ? masteredCards / totalCards : 0.0,
          totalFolders: folders.length,
        ),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}
