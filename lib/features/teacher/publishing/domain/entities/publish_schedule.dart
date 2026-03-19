// lib/features/teacher/publishing/domain/entities/publish_schedule.dart
import 'package:equatable/equatable.dart';

class PublishSchedule extends Equatable {
  final String id;
  final String contentId;
  final String contentType;
  final List<String> classIds;
  final DateTime? scheduledAt;
  final bool isPublishedNow;
  final String status; // 'pending' | 'published' | 'scheduled'
  final DateTime createdAt;

  const PublishSchedule({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.classIds,
    this.scheduledAt,
    this.isPublishedNow = false,
    this.status = 'pending',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
