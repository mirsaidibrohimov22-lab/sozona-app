// QO'YISH: lib/features/teacher/publishing/domain/usecases/schedule_content.dart
// Schedule Content UseCase — Kontentni kelajakda yuborish uchun rejalashtirish

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';
import 'package:my_first_app/features/teacher/publishing/domain/repositories/publishing_repository.dart';

/// Schedule Content UseCase
///
/// Bolaga: Bu — kontentni kelajakda yuborish uchun rejalashtirish.
/// Masalan: "2 fevralda soat 10:00 da yuborilsin" degan buyruq.
class ScheduleContent implements UseCase<void, ScheduleContentParams> {
  final PublishingRepository repository;

  ScheduleContent(this.repository);

  @override
  Future<Either<Failure, void>> call(ScheduleContentParams params) async {
    // 1. Input validatsiya
    final validationError = _validateParams(params);
    if (validationError != null) {
      return Left(ValidationFailure(message: validationError));
    }

    // 2. Repository orqali schedule qilish
    return await repository.scheduleContent(
      content: params.content,
      classId: params.classId,
      title: params.title,
      description: params.description,
      scheduledAt: params.scheduledAt,
      sendNotification: params.sendNotification,
    );
  }

  /// Parametrlarni tekshirish
  String? _validateParams(ScheduleContentParams params) {
    // Content tekshiruvi
    if (!params.content.isCompleted) {
      return 'Kontent hali tayyor emas. Avval yaratishni yakunlang.';
    }

    // ClassId tekshiruvi
    if (params.classId.trim().isEmpty) {
      return 'Sinf tanlanmagan';
    }

    // Title tekshiruvi
    if (params.title.trim().isEmpty) {
      return 'Sarlavha bo\'sh bo\'lmasligi kerak';
    }
    if (params.title.length < 3) {
      return 'Sarlavha kamida 3 ta belgi bo\'lishi kerak';
    }

    // ScheduledAt tekshiruvi
    final now = DateTime.now();
    if (params.scheduledAt.isBefore(now)) {
      return 'Rejalashtirilgan vaqt o\'tmishda bo\'lishi mumkin emas';
    }

    // Juda uzoq kelajakda emas (1 yildan ko'p)
    final oneYearLater = now.add(const Duration(days: 365));
    if (params.scheduledAt.isAfter(oneYearLater)) {
      return 'Rejalashtirilgan vaqt 1 yildan ko\'p bo\'lmasligi kerak';
    }

    // Description tekshiruvi (ixtiyoriy)
    if (params.description != null && params.description!.length > 1000) {
      return 'Tavsif 1000 ta belgidan oshmasligi kerak';
    }

    return null; // Hamma narsa to'g'ri
  }
}

/// Schedule Content parametrlari
class ScheduleContentParams {
  final GeneratedContent content; // Yaratilgan kontent
  final String classId; // Qaysi sinfga yuboriladi
  final String title; // Sarlavha
  final String? description; // Tavsif (ixtiyoriy)
  final DateTime scheduledAt; // Qachon yuboriladi
  final bool sendNotification; // Notification yuborilsinmi?

  const ScheduleContentParams({
    required this.content,
    required this.classId,
    required this.title,
    this.description,
    required this.scheduledAt,
    this.sendNotification = true,
  });

  /// Copy with
  ScheduleContentParams copyWith({
    GeneratedContent? content,
    String? classId,
    String? title,
    String? description,
    DateTime? scheduledAt,
    bool? sendNotification,
  }) {
    return ScheduleContentParams(
      content: content ?? this.content,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sendNotification: sendNotification ?? this.sendNotification,
    );
  }

  /// Qachon yuborilishini human-readable formatda
  String get scheduledTimeFormatted {
    final now = DateTime.now();
    final difference = scheduledAt.difference(now);

    if (difference.inDays == 0) {
      return 'Bugun, ${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ertaga, ${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} kundan keyin';
    } else {
      return '${scheduledAt.day}.${scheduledAt.month}.${scheduledAt.year}';
    }
  }
}
