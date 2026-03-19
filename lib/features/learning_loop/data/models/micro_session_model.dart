// QO'YISH: lib/features/learning_loop/data/models/micro_session_model.dart
// So'zona — MicroSession Firestore modeli

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/micro_session.dart';

class MicroSessionModel extends MicroSession {
  const MicroSessionModel({
    required super.id,
    required super.userId,
    required super.sessionType,
    super.status,
    super.durationMinutes,
    super.actualDurationMinutes,
    super.activities,
    super.overallScore,
    super.weakItemsReviewed,
    super.newWeakItems,
    super.xpEarned,
    super.motivationMessage,
    required super.scheduledAt,
    super.startedAt,
    super.completedAt,
    required super.createdAt,
  });

  factory MicroSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MicroSessionModel.fromMap(data, doc.id);
  }

  factory MicroSessionModel.fromMap(Map<String, dynamic> map, String id) {
    final activitiesRaw = map['activities'] as List<dynamic>? ?? [];
    final activities = activitiesRaw
        .map(
          (a) => SessionActivity(
            type: a['type'] as String? ?? '',
            contentId: a['contentId'] as String? ?? '',
            score: a['score'] as int?,
            timeSpentSeconds: a['timeSpentSeconds'] as int?,
          ),
        )
        .toList();

    return MicroSessionModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      sessionType:
          _parseSessionType(map['sessionType'] as String? ?? 'flashcardQuiz'),
      status: _parseStatus(map['status'] as String? ?? 'scheduled'),
      durationMinutes: map['durationMinutes'] as int? ?? 10,
      actualDurationMinutes: map['actualDurationMinutes'] as int?,
      activities: activities,
      overallScore: map['overallScore'] as int?,
      weakItemsReviewed: map['weakItemsReviewed'] as int? ?? 0,
      newWeakItems: map['newWeakItems'] as int? ?? 0,
      xpEarned: map['xpEarned'] as int? ?? 0,
      motivationMessage: map['motivationMessage'] as String?,
      scheduledAt:
          (map['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'sessionType': sessionType.name,
      'status': status.name,
      'durationMinutes': durationMinutes,
      'actualDurationMinutes': actualDurationMinutes,
      'activities': activities
          .map(
            (a) => {
              'type': a.type,
              'contentId': a.contentId,
              'score': a.score,
              'timeSpentSeconds': a.timeSpentSeconds,
            },
          )
          .toList(),
      'overallScore': overallScore,
      'weakItemsReviewed': weakItemsReviewed,
      'newWeakItems': newWeakItems,
      'xpEarned': xpEarned,
      'motivationMessage': motivationMessage,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static SessionType _parseSessionType(String value) {
    switch (value) {
      case 'listeningSpeaking':
        return SessionType.listeningSpeaking;
      default:
        return SessionType.flashcardQuiz;
    }
  }

  static SessionStatus _parseStatus(String value) {
    switch (value) {
      case 'inProgress':
        return SessionStatus.inProgress;
      case 'completed':
        return SessionStatus.completed;
      case 'skipped':
        return SessionStatus.skipped;
      default:
        return SessionStatus.scheduled;
    }
  }

  factory MicroSessionModel.fromEntity(MicroSession entity) {
    return MicroSessionModel(
      id: entity.id,
      userId: entity.userId,
      sessionType: entity.sessionType,
      status: entity.status,
      durationMinutes: entity.durationMinutes,
      actualDurationMinutes: entity.actualDurationMinutes,
      activities: entity.activities,
      overallScore: entity.overallScore,
      weakItemsReviewed: entity.weakItemsReviewed,
      newWeakItems: entity.newWeakItems,
      xpEarned: entity.xpEarned,
      motivationMessage: entity.motivationMessage,
      scheduledAt: entity.scheduledAt,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
    );
  }
}
