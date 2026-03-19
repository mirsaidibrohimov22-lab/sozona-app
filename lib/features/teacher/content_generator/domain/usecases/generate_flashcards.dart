// QO'YISH: lib/features/teacher/content_generator/domain/usecases/generate_flashcards.dart
// Generate Flashcards UseCase — Flashcard to'plami yaratish biznes logikasi

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/repositories/content_generator_repository.dart';

/// Flashcard to'plami yaratish UseCase
///
/// Bolaga: Bu — flashcard yaratish uchun maxsus buyruq.
/// Barcha kerakli tekshiruvlarni o'tkazib, AI'ga so'rov yuboradi.
class GenerateFlashcards
    implements UseCase<GeneratedContent, GenerateFlashcardsParams> {
  final ContentGeneratorRepository repository;

  GenerateFlashcards(this.repository);

  @override
  Future<Either<Failure, GeneratedContent>> call(
    GenerateFlashcardsParams params,
  ) async {
    // 1. Input validatsiya
    final validationError = _validateParams(params);
    if (validationError != null) {
      return Left(ValidationFailure(message: validationError));
    }

    // 2. Repository orqali flashcard yaratish
    return await repository.generateFlashcards(
      language: params.language,
      level: params.level,
      topic: params.topic,
      cardCount: params.cardCount,
      includeExamples: params.includeExamples,
      includePronunciation: params.includePronunciation,
    );
  }

  /// Parametrlarni tekshirish
  String? _validateParams(GenerateFlashcardsParams params) {
    // Language tekshiruvi
    if (params.language != 'en' && params.language != 'de') {
      return 'Til faqat "en" yoki "de" bo\'lishi mumkin';
    }

    // Level tekshiruvi
    const validLevels = ['A1', 'A2', 'B1', 'B2', 'C1'];
    if (!validLevels.contains(params.level)) {
      return 'Daraja faqat A1, A2, B1, B2, C1 bo\'lishi mumkin';
    }

    // Topic tekshiruvi
    if (params.topic.trim().isEmpty) {
      return 'Mavzu bo\'sh bo\'lishi mumkin emas';
    }
    if (params.topic.length < 3) {
      return 'Mavzu kamida 3 ta belgi bo\'lishi kerak';
    }
    if (params.topic.length > 100) {
      return 'Mavzu 100 ta belgidan oshmasligi kerak';
    }

    // Card count tekshiruvi
    if (params.cardCount < 1) {
      return 'Kamida 1 ta kartochka bo\'lishi kerak';
    }
    if (params.cardCount > 100) {
      return 'Maksimal 100 ta kartochka yaratish mumkin';
    }

    return null; // Hamma narsa to'g'ri
  }
}

/// Generate Flashcards parametrlari
class GenerateFlashcardsParams {
  final String language; // en | de
  final String level; // A1, A2, B1, B2, C1
  final String topic; // Mavzu
  final int cardCount; // Kartochka soni
  final bool includeExamples; // Misol gaplar qo'shilsinmi?
  final bool includePronunciation; // Talaffuz qo'shilsinmi?

  const GenerateFlashcardsParams({
    required this.language,
    required this.level,
    required this.topic,
    required this.cardCount,
    this.includeExamples = true,
    this.includePronunciation = true,
  });

  /// Copy with
  GenerateFlashcardsParams copyWith({
    String? language,
    String? level,
    String? topic,
    int? cardCount,
    bool? includeExamples,
    bool? includePronunciation,
  }) {
    return GenerateFlashcardsParams(
      language: language ?? this.language,
      level: level ?? this.level,
      topic: topic ?? this.topic,
      cardCount: cardCount ?? this.cardCount,
      includeExamples: includeExamples ?? this.includeExamples,
      includePronunciation: includePronunciation ?? this.includePronunciation,
    );
  }

  /// Daraja bo'yicha tavsiya etiladigan kartochka soni
  static int recommendedCardCount(String level) {
    switch (level) {
      case 'A1':
        return 10;
      case 'A2':
        return 15;
      case 'B1':
        return 20;
      case 'B2':
        return 25;
      case 'C1':
        return 30;
      default:
        return 20;
    }
  }
}
