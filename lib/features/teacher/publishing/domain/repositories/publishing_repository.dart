// QO'YISH: lib/features/teacher/publishing/domain/repositories/publishing_repository.dart
// Publishing Repository Interface

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';

/// Publishing Repository Interface
abstract class PublishingRepository {
  /// Kontentni darhol sinfga yuborish
  Future<Either<Failure, void>> publishContent({
    required GeneratedContent content,
    required String classId,
    required String title,
    String? description,
    bool sendNotification = true,
  });

  /// Kontentni kelajakda yuborish uchun rejalashtirish
  Future<Either<Failure, void>> scheduleContent({
    required GeneratedContent content,
    required String classId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    bool sendNotification = true,
  });
}
