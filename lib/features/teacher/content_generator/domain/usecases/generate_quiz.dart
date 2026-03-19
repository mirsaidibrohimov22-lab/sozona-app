// QO'YISH: lib/features/teacher/content_generator/domain/usecases/generate_quiz.dart
// Generate Quiz UseCase — Quiz yaratish biznes logikasi

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/repositories/content_generator_repository.dart';

/// Quiz yaratish UseCase
///
/// Bolaga: Bu — "buyruq ijrochisi". Foydalanuvchi "quiz yarat" desa,
/// bu UseCase ishga tushadi va barcha kerakli tekshiruvlarni o'tkazadi.
class GenerateQuiz implements UseCase<GeneratedContent, GenerateQuizParams> {
  final ContentGeneratorRepository repository;

  GenerateQuiz(this.repository);

  @override
  Future<Either<Failure, GeneratedContent>> call(
    GenerateQuizParams params,
  ) async {
    // 1. Input validatsiya
    final validationError = _validateParams(params);
    if (validationError != null) {
      return Left(ValidationFailure(message: validationError));
    }

    // 2. Repository orqali quiz yaratish
    return await repository.generateQuiz(
      language: params.language,
      level: params.level,
      topic: params.topic,
      questionCount: params.questionCount,
      difficulty: params.difficulty,
    );
  }

  /// Parametrlarni tekshirish
  String? _validateParams(GenerateQuizParams params) {
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

    // Question count tekshiruvi
    if (params.questionCount < 1) {
      return 'Kamida 1 ta savol bo\'lishi kerak';
    }
    if (params.questionCount > 50) {
      return 'Maksimal 50 ta savol yaratish mumkin';
    }

    // Difficulty tekshiruvi
    const validDifficulties = ['easy', 'medium', 'hard'];
    if (!validDifficulties.contains(params.difficulty)) {
      return 'Qiyinchilik darajasi faqat easy, medium, hard bo\'lishi mumkin';
    }

    return null; // Hamma narsa to'g'ri
  }
}

/// Generate Quiz parametrlari
class GenerateQuizParams {
  final String language; // en | de
  final String level; // A1, A2, B1, B2, C1
  final String topic; // Mavzu
  final int questionCount; // Savol soni
  final String difficulty; // easy, medium, hard

  const GenerateQuizParams({
    required this.language,
    required this.level,
    required this.topic,
    required this.questionCount,
    this.difficulty = 'medium',
  });

  /// Copy with
  GenerateQuizParams copyWith({
    String? language,
    String? level,
    String? topic,
    int? questionCount,
    String? difficulty,
  }) {
    return GenerateQuizParams(
      language: language ?? this.language,
      level: level ?? this.level,
      topic: topic ?? this.topic,
      questionCount: questionCount ?? this.questionCount,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  /// Daraja bo'yicha tavsiya etiladigan savol soni
  static int recommendedQuestionCount(String level) {
    switch (level) {
      case 'A1':
        return 5; // Boshlang'ichlar uchun kam
      case 'A2':
        return 8;
      case 'B1':
        return 10;
      case 'B2':
        return 12;
      case 'C1':
        return 15; // Ilg'or uchun ko'proq
      default:
        return 10;
    }
  }

  /// Daraja bo'yicha default qiyinchilik
  static String defaultDifficulty(String level) {
    switch (level) {
      case 'A1':
      case 'A2':
        return 'easy';
      case 'B1':
        return 'medium';
      case 'B2':
      case 'C1':
        return 'hard';
      default:
        return 'medium';
    }
  }
}
