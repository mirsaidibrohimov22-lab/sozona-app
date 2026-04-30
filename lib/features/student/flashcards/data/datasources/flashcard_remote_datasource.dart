// lib/features/student/flashcards/data/datasources/flashcard_remote_datasource.dart
// So'zona — Flashcard remote ma'lumotlar manbai
// ✅ FIX: getCards va deleteFolder da userId filteri qo'shildi
//    Sabab: Firestore security rules userId == request.auth.uid talab qiladi.
//    Oldin faqat folderId bilan query qilinardi → PERMISSION_DENIED xatosi
//    va kartochkalar yo'qolib ketardi.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:my_first_app/core/constants/firestore_paths.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/student/flashcards/data/models/flashcard_model.dart';
import 'package:my_first_app/features/student/flashcards/data/models/folder_model.dart';

/// Flashcard remote datasource interfeysi
abstract class FlashcardRemoteDataSource {
  // ─── Papkalar ───
  Future<List<FolderModel>> getFolders(String userId);
  Future<FolderModel> getFolderById(String folderId);
  Future<FolderModel> createFolder(Map<String, dynamic> data);
  Future<FolderModel> updateFolder(String folderId, Map<String, dynamic> data);
  // ✅ FIX: userId qo'shildi
  Future<void> deleteFolder(String folderId, String userId);

  // ─── Kartochkalar ───
  // ✅ FIX: userId qo'shildi
  Future<List<FlashcardModel>> getCards(String folderId, String userId);
  Future<FlashcardModel> getCardById(String cardId);
  Future<FlashcardModel> createCard(Map<String, dynamic> data);
  Future<List<FlashcardModel>> createCards(List<Map<String, dynamic>> cards);
  Future<FlashcardModel> updateCard(String cardId, Map<String, dynamic> data);
  Future<void> deleteCard(String cardId);
  Future<List<FlashcardModel>> searchCards(String userId, String query);
}

/// Firestore implementatsiyasi
class FlashcardRemoteDataSourceImpl implements FlashcardRemoteDataSource {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  FlashcardRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Papkalar kolleksiyasi — FirestorePaths ishlatiladi
  CollectionReference get _foldersRef =>
      _firestore.collection(FirestorePaths.folders);

  /// Kartochkalar kolleksiyasi — FirestorePaths ishlatiladi
  CollectionReference get _cardsRef =>
      _firestore.collection(FirestorePaths.flashcards);

  // ─── PAPKALAR ───

  @override
  Future<List<FolderModel>> getFolders(String userId) async {
    try {
      final snapshot = await _foldersRef
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('sortOrder')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return FolderModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Papkalarni yuklashda xatolik: ${e.message}',
      );
    }
  }

  @override
  Future<FolderModel> getFolderById(String folderId) async {
    try {
      final doc = await _foldersRef.doc(folderId).get();

      if (!doc.exists) {
        throw const ServerException(message: 'Papka topilmadi');
      }

      return FolderModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Papkani yuklashda xatolik: ${e.message}',
      );
    }
  }

  @override
  Future<FolderModel> createFolder(Map<String, dynamic> data) async {
    try {
      final docId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final folderData = {
        ...data,
        'createdAt': now,
        'updatedAt': now,
        'cardCount': 0,
        'masteredCount': 0,
        'dueCount': 0,
        'isDeleted': false,
      };

      await _foldersRef.doc(docId).set(folderData);
      return FolderModel.fromFirestore(folderData, docId);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Papka yaratishda xatolik: ${e.message}',
      );
    }
  }

  @override
  Future<FolderModel> updateFolder(
    String folderId,
    Map<String, dynamic> data,
  ) async {
    try {
      final updateData = {
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _foldersRef.doc(folderId).update(updateData);
      return getFolderById(folderId);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Papkani yangilashda xatolik: ${e.message}',
      );
    }
  }

  /// ✅ FIX: userId qo'shildi — Firestore security rules talab qiladi
  @override
  Future<void> deleteFolder(String folderId, String userId) async {
    try {
      // Soft delete — papka
      await _foldersRef.doc(folderId).update({
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // ✅ FIX: userId filteri qo'shildi — oldin bu query PERMISSION_DENIED berardi
      final cards = await _cardsRef
          .where('folderId', isEqualTo: folderId)
          .where('userId', isEqualTo: userId)
          .get();

      if (cards.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in cards.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Papkani o\'chirishda xatolik: ${e.message}',
      );
    }
  }

  // ─── KARTOCHKALAR ───

  /// ✅ FIX: userId qo'shildi — Firestore security rules talab qiladi
  /// Oldin faqat folderId bilan query → PERMISSION_DENIED → kartochkalar yo'qolardi
  @override
  Future<List<FlashcardModel>> getCards(String folderId, String userId) async {
    try {
      final snapshot = await _cardsRef
          .where('folderId', isEqualTo: folderId)
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return FlashcardModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Kartochkalarni yuklashda xatolik: ${e.message}',
      );
    }
  }

  @override
  Future<FlashcardModel> getCardById(String cardId) async {
    try {
      final doc = await _cardsRef.doc(cardId).get();

      if (!doc.exists) {
        throw const ServerException(message: 'Kartochka topilmadi');
      }

      return FlashcardModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Kartochkani yuklashda xatolik: ${e.message}',
      );
    }
  }

  @override
  Future<FlashcardModel> createCard(Map<String, dynamic> data) async {
    try {
      final docId = _uuid.v4();
      final now = DateTime.now();

      final cardData = {
        ...data,
        'difficulty': 'newCard',
        'intervalHours': 0,
        'nextReviewAt': now.toIso8601String(),
        'reviewCount': 0,
        'correctCount': 0,
        'incorrectCount': 0,
        'easeFactor': 2.5,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDeleted': false,
      };

      await _cardsRef.doc(docId).set(cardData);

      // Papka kartochka sonini yangilash
      await _foldersRef.doc(data['folderId']).update({
        'cardCount': FieldValue.increment(1),
        'dueCount': FieldValue.increment(1),
        'updatedAt': now.toIso8601String(),
      });

      return FlashcardModel.fromFirestore(cardData, docId);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Kartochka yaratishda xatolik: ${e.message}',
      );
    }
  }

  @override
  Future<List<FlashcardModel>> createCards(
    List<Map<String, dynamic>> cards,
  ) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();
      final createdModels = <FlashcardModel>[];
      String? folderId;

      for (final cardData in cards) {
        final docId = _uuid.v4();
        folderId = cardData['folderId'] as String?;

        final fullData = {
          ...cardData,
          'difficulty': 'newCard',
          'intervalHours': 0,
          'nextReviewAt': now.toIso8601String(),
          'reviewCount': 0,
          'correctCount': 0,
          'incorrectCount': 0,
          'easeFactor': 2.5,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'isDeleted': false,
        };

        batch.set(_cardsRef.doc(docId), fullData);
        createdModels.add(FlashcardModel.fromFirestore(fullData, docId));
      }

      // Papka sonini yangilash
      if (folderId != null) {
        batch.update(_foldersRef.doc(folderId), {
          'cardCount': FieldValue.increment(cards.length),
          'dueCount': FieldValue.increment(cards.length),
          'updatedAt': now.toIso8601String(),
        });
      }

      await batch.commit();
      return createdModels;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Kartochkalar yaratishda xatolik: ${e.message}',
      );
    }
  }

  @override
  Future<FlashcardModel> updateCard(
    String cardId,
    Map<String, dynamic> data,
  ) async {
    try {
      final updateData = {
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _cardsRef.doc(cardId).update(updateData);
      return getCardById(cardId);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Kartochkani yangilashda xatolik: ${e.message}',
      );
    }
  }

  @override
  Future<void> deleteCard(String cardId) async {
    try {
      // Avval kartochkani olish (papka id uchun)
      final card = await getCardById(cardId);

      // Soft delete
      await _cardsRef.doc(cardId).update({
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Papka sonini kamaytirish
      await _foldersRef.doc(card.folderId).update({
        'cardCount': FieldValue.increment(-1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Kartochkani o\'chirishda xatolik: ${e.message}',
      );
    }
  }

  @override
  Future<List<FlashcardModel>> searchCards(
    String userId,
    String query,
  ) async {
    try {
      // userId filterlangan query — Firestore rules uchun to'g'ri
      final snapshot = await _cardsRef
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();

      final lowerQuery = query.toLowerCase();

      return snapshot.docs
          .map(
            (doc) => FlashcardModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .where(
            (card) =>
                card.front.toLowerCase().contains(lowerQuery) ||
                card.back.toLowerCase().contains(lowerQuery),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Qidiruvda xatolik: ${e.message}',
      );
    }
  }
}
