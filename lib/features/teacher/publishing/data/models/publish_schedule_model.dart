// lib/features/teacher/publishing/data/models/publish_schedule_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/teacher/publishing/domain/entities/publish_schedule.dart';

class PublishScheduleModel extends PublishSchedule {
  const PublishScheduleModel({
    required super.id,
    required super.contentId,
    required super.contentType,
    required super.classIds,
    super.scheduledAt,
    super.isPublishedNow,
    super.status,
    required super.createdAt,
  });

  factory PublishScheduleModel.fromFirestore(
    Map<String, dynamic> d,
    String id,
  ) =>
      PublishScheduleModel(
        id: id,
        contentId: d['contentId'] ?? '',
        contentType: d['contentType'] ?? 'quiz',
        classIds: List<String>.from(d['classIds'] ?? []),
        scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate(),
        isPublishedNow: d['isPublishedNow'] as bool? ?? false,
        status: d['status'] ?? 'pending',
        createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestore() => {
        'contentId': contentId,
        'contentType': contentType,
        'classIds': classIds,
        'scheduledAt':
            scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
        'isPublishedNow': isPublishedNow,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
