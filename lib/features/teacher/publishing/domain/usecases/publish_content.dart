// QO'YISH: lib/features/teacher/publishing/domain/usecases/publish_content.dart
// Publish Content UseCase — Kontentni darhol sinfga yuborish

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';
import 'package:my_first_app/features/teacher/publishing/domain/repositories/publishing_repository.dart';

/// Publish Content UseCase
///
/// Bolaga: Bu — kontentni darhol sinfga yuborish buyrug'i.
/// Teacher "yuborish" tugmasini bosadi — bu UseCase ishga tushadi.
class PublishContent implements UseCase<void, PublishContentParams> {
  final PublishingRepository repository;

  PublishContent(this.repository);

  @override
  Future<Either<Failure, void>> call(PublishContentParams params) async {
    // 1. Input validatsiya
    final validationError = _validateParams(params);
    if (validationError != null) {
      return Left(ValidationFailure(message: validationError));
    }

    // 2. Repository orqali publish qilish
    return await repository.publishContent(
      content: params.content,
      classId: params.classId,
      title: params.title,
      description: params.description,
      sendNotification: params.sendNotification,
    );
  }

  /// Parametrlarni tekshirish
  String? _validateParams(PublishContentParams params) {
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
    if (params.title.length > 200) {
      return 'Sarlavha 200 ta belgidan oshmasligi kerak';
    }

    // Description tekshiruvi (ixtiyoriy, lekin agar bor bo'lsa)
    if (params.description != null && params.description!.length > 1000) {
      return 'Tavsif 1000 ta belgidan oshmasligi kerak';
    }

    return null; // Hamma narsa to'g'ri
  }
}

/// Publish Content parametrlari
class PublishContentParams {
  final GeneratedContent content; // Yaratilgan kontent
  final String classId; // Qaysi sinfga yuboriladi
  final String title; // Sarlavha (o'quvchilar ko'radigan)
  final String? description; // Tavsif (ixtiyoriy)
  final bool sendNotification; // Notification yuborilsinmi?

  const PublishContentParams({
    required this.content,
    required this.classId,
    required this.title,
    this.description,
    this.sendNotification = true,
  });

  /// Copy with
  PublishContentParams copyWith({
    GeneratedContent? content,
    String? classId,
    String? title,
    String? description,
    bool? sendNotification,
  }) {
    return PublishContentParams(
      content: content ?? this.content,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      sendNotification: sendNotification ?? this.sendNotification,
    );
  }
}
