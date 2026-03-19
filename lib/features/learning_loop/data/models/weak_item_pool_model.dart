// QO'YISH: lib/features/learning_loop/data/models/weak_item_pool_model.dart
// So'zona — WeakItem Firestore modeli

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/weak_item_pool.dart';

class WeakItemModel extends WeakItem {
  const WeakItemModel({
    required super.id,
    required super.userId,
    required super.sourceType,
    required super.sourceContentId,
    required super.itemType,
    required super.itemData,
    super.incorrectCount,
    super.correctStreak,
    super.masteryScore,
    required super.nextReviewAt,
    super.intervalDays,
    super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory WeakItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeakItemModel.fromMap(data, doc.id);
  }

  factory WeakItemModel.fromMap(Map<String, dynamic> map, String id) {
    final itemDataMap = map['itemData'] as Map<String, dynamic>? ?? {};

    return WeakItemModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      sourceType: _parseSourceType(map['sourceType'] as String? ?? 'quiz'),
      sourceContentId: map['sourceContentId'] as String? ?? '',
      itemType: map['itemType'] as String? ?? 'question',
      itemData: WeakItemData(
        term: itemDataMap['term'] as String? ?? '',
        translation: itemDataMap['translation'] as String?,
        context: itemDataMap['context'] as String?,
        correctAnswer: itemDataMap['correctAnswer'] as String?,
      ),
      incorrectCount: map['incorrectCount'] as int? ?? 1,
      correctStreak: map['correctStreak'] as int? ?? 0,
      masteryScore: map['masteryScore'] as int? ?? 0,
      nextReviewAt: (map['nextReviewAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 1)),
      intervalDays: map['intervalDays'] as int? ?? 1,
      status: _parseStatus(map['status'] as String? ?? 'active'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'sourceType': sourceType.name,
      'sourceContentId': sourceContentId,
      'itemType': itemType,
      'itemData': {
        'term': itemData.term,
        'translation': itemData.translation,
        'context': itemData.context,
        'correctAnswer': itemData.correctAnswer,
      },
      'incorrectCount': incorrectCount,
      'correctStreak': correctStreak,
      'masteryScore': masteryScore,
      'nextReviewAt': Timestamp.fromDate(nextReviewAt),
      'intervalDays': intervalDays,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static WeakItemSource _parseSourceType(String value) {
    switch (value) {
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

  static WeakItemStatus _parseStatus(String value) {
    switch (value) {
      case 'mastered':
        return WeakItemStatus.mastered;
      case 'dismissed':
        return WeakItemStatus.dismissed;
      default:
        return WeakItemStatus.active;
    }
  }

  /// Entity dan Model ga o'tkazish
  factory WeakItemModel.fromEntity(WeakItem entity) {
    return WeakItemModel(
      id: entity.id,
      userId: entity.userId,
      sourceType: entity.sourceType,
      sourceContentId: entity.sourceContentId,
      itemType: entity.itemType,
      itemData: entity.itemData,
      incorrectCount: entity.incorrectCount,
      correctStreak: entity.correctStreak,
      masteryScore: entity.masteryScore,
      nextReviewAt: entity.nextReviewAt,
      intervalDays: entity.intervalDays,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
