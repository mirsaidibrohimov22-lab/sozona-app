// lib/features/student/progress/data/datasources/progress_remote_datasource.dart
// So'zona — Progress Remote DataSource

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/weak_item_pool.dart';
import 'package:my_first_app/features/student/progress/data/models/progress_model.dart';

abstract class ProgressRemoteDataSource {
  Future<UserProgressModel> getProgressStats(String userId);
  Future<List<WeakItem>> getWeakItems(String userId);
  Future<void> updateMasteryScore({
    required String userId,
    required String contentType,
    required String contentId,
    required double score,
  });
}

class ProgressRemoteDataSourceImpl implements ProgressRemoteDataSource {
  final FirebaseFirestore _db;
  ProgressRemoteDataSourceImpl(this._db);

  @override
  Future<UserProgressModel> getProgressStats(String userId) async {
    try {
      final doc = await _db.collection('progress').doc(userId).get();
      return UserProgressModel.fromFirestore(doc.data() ?? {}, userId);
    } catch (e) {
      throw ServerException(message: 'Progress yuklanmadi: $e');
    }
  }

  @override
  Future<List<WeakItem>> getWeakItems(String userId) async {
    try {
      final snap = await _db
          .collection('progress')
          .doc(userId)
          .collection('weakItems')
          .where('status', isEqualTo: 'active')
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .get();
      final now = DateTime.now();
      return snap.docs.map((doc) {
        final d = doc.data();
        return WeakItem(
          id: doc.id,
          userId: userId,
          sourceType: _parseSourceType(d['sourceType'] as String? ?? 'quiz'),
          sourceContentId: d['sourceContentId'] as String? ?? '',
          itemType: d['itemType'] as String? ?? 'word',
          itemData: WeakItemData(
            term: d['term'] as String? ?? '',
            translation: d['translation'] as String?,
            context: d['context'] as String?,
            correctAnswer: d['correctAnswer'] as String?,
          ),
          incorrectCount: d['incorrectCount'] as int? ?? 1,
          correctStreak: d['correctStreak'] as int? ?? 0,
          masteryScore: d['masteryScore'] as int? ?? 0,
          nextReviewAt: (d['nextReviewAt'] as Timestamp?)?.toDate() ?? now,
          intervalDays: d['intervalDays'] as int? ?? 1,
          status: _parseStatus(d['status'] as String? ?? 'active'),
          createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
          updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? now,
        );
      }).toList();
    } catch (e) {
      throw ServerException(message: 'Zaif joylar yuklanmadi: $e');
    }
  }

  @override
  Future<void> updateMasteryScore({
    required String userId,
    required String contentType,
    required String contentId,
    required double score,
  }) async {
    try {
      final batch = _db.batch();
      final ref = _db.collection('progress').doc(userId);
      batch.set(
        ref,
        {
          'lastActiveDate': FieldValue.serverTimestamp(),
          'skillScores.$contentType': score,
          'totalXp': FieldValue.increment((score * 10).round()),
        },
        SetOptions(merge: true),
      );
      final wRef = ref.collection('weakItems').doc('${contentType}_$contentId');
      if (score < 0.6) {
        batch.set(
          wRef,
          {
            'sourceType': contentType,
            'sourceContentId': contentId,
            'itemType': 'word',
            'status': 'active',
            'incorrectCount': FieldValue.increment(1),
            'correctStreak': 0,
            'masteryScore': ((1 - score) * 100).round(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.delete(wRef);
      }
      await batch.commit();
    } catch (e) {
      throw ServerException(message: 'Mastery yangilanmadi: $e');
    }
  }

  /// Source type stringdan enumga o'girish
  WeakItemSource _parseSourceType(String type) {
    switch (type) {
      case 'flashcard':
        return WeakItemSource.flashcard;
      case 'listening':
        return WeakItemSource.listening;
      case 'speaking':
        return WeakItemSource.speaking;
      case 'artikel':
        return WeakItemSource.artikel;
      default:
        return WeakItemSource.quiz;
    }
  }

  /// Status stringdan enumga o'girish
  WeakItemStatus _parseStatus(String status) {
    switch (status) {
      case 'mastered':
        return WeakItemStatus.mastered;
      case 'dismissed':
        return WeakItemStatus.dismissed;
      default:
        return WeakItemStatus.active;
    }
  }
}
