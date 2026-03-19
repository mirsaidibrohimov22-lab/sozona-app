// lib/features/student/artikel/data/datasources/artikel_remote_datasource.dart
// So'zona — Artikel remote datasource

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_first_app/core/constants/firestore_paths.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/student/artikel/data/models/artikel_model.dart';
import 'package:my_first_app/features/student/artikel/domain/entities/artikel_word.dart';

abstract class ArtikelRemoteDataSource {
  Future<List<ArtikelWord>> getArtikelWords(
    String userId, {
    String? topic,
    String? level,
  });

  Future<bool> submitAnswer({
    required String userId,
    required String wordId,
    required String selectedArtikel,
  });
}

class ArtikelRemoteDataSourceImpl implements ArtikelRemoteDataSource {
  final FirebaseFirestore _db;

  ArtikelRemoteDataSourceImpl(this._db);

  // ─── Collection referencelar — FirestorePaths ishlatiladi ───

  CollectionReference get _artikelWordsRef =>
      _db.collection(FirestorePaths.artikelWords);

  CollectionReference _artikelProgressRef(String userId) => _db
      .collection(FirestorePaths.users)
      .doc(userId)
      .collection('artikel_progress');

  // ─── SO'ZLARNI OLISH ───

  @override
  Future<List<ArtikelWord>> getArtikelWords(
    String userId, {
    String? topic,
    String? level,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _artikelWordsRef as Query<Map<String, dynamic>>;

      if (topic != null) query = query.where('topic', isEqualTo: topic);
      if (level != null) query = query.where('cefrLevel', isEqualTo: level);

      final snap = await query.limit(50).get();
      return snap.docs
          .map((d) => ArtikelWordModel.fromFirestore(d.data(), d.id))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Artikel so\'zlar yuklanmadi: $e');
    }
  }

  // ─── JAVOB YUBORISH ───

  @override
  Future<bool> submitAnswer({
    required String userId,
    required String wordId,
    required String selectedArtikel,
  }) async {
    try {
      // So'zni tekshirish — FirestorePaths.artikelWords
      final wordDoc = await _artikelWordsRef.doc(wordId).get();
      if (!wordDoc.exists) return false;

      final correct =
          (wordDoc.data() as Map<String, dynamic>?)?['artikel'] as String? ??
              '';
      final isCorrect = correct == selectedArtikel;

      // Progress yozish — FirestorePaths.users + artikel_progress subcollection
      await _artikelProgressRef(userId).doc(wordId).set(
        {
          'wordId': wordId,
          'lastAnswer': selectedArtikel,
          'isCorrect': isCorrect,
          'attemptCount': FieldValue.increment(1),
          'correctCount':
              isCorrect ? FieldValue.increment(1) : FieldValue.increment(0),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return isCorrect;
    } catch (e) {
      throw ServerException(message: 'Javob yuborilmadi: $e');
    }
  }
}
