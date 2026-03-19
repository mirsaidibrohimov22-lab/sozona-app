// QO'YISH: lib/features/teacher/content_generator/domain/usecases/generate_listening.dart
// Generate Listening UseCase — Listening mashqi yaratish biznes logikasi

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/repositories/content_generator_repository.dart';

/// Listening mashqi yaratish UseCase
///
/// Bolaga: Bu — listening yaratish uchun maxsus buyruq.
/// AI matn yaratadi, biz keyinchalik TTS orqali audio'ga aylantiramiz.
class GenerateListening
    implements UseCase<GeneratedContent, GenerateListeningParams> {
  final ContentGeneratorRepository repository;

  GenerateListening(this.repository);

  @override
  Future<Either<Failure, GeneratedContent>> call(
    GenerateListeningParams params,
  ) async {
    // 1. Input validatsiya
    final validationError = _validateParams(params);
    if (validationError != null) {
      return Left(ValidationFailure(message: validationError));
    }

    // 2. Repository orqali listening yaratish
    return await repository.generateListening(
      language: params.language,
      level: params.level,
      topic: params.topic,
      duration: params.duration,
      questionCount: params.questionCount,
    );
  }

  /// Parametrlarni tekshirish
  String? _validateParams(GenerateListeningParams params) {
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

    // Duration tekshiruvi
    if (params.duration < 30) {
      return 'Davomiylik kamida 30 soniya bo\'lishi kerak';
    }
    if (params.duration > 600) {
      return 'Davomiylik maksimal 10 daqiqa (600 soniya) bo\'lishi mumkin';
    }

    // Question count tekshiruvi
    if (params.questionCount < 1) {
      return 'Kamida 1 ta savol bo\'lishi kerak';
    }
    if (params.questionCount > 20) {
      return 'Maksimal 20 ta savol yaratish mumkin';
    }

    return null; // Hamma narsa to'g'ri
  }
}

/// Generate Listening parametrlari
class GenerateListeningParams {
  final String language; // en | de
  final String level; // A1, A2, B1, B2, C1
  final String topic; // Mavzu
  final int duration; // Taxminiy audio davomiyligi (soniyalarda)
  final int questionCount; // Savol soni

  const GenerateListeningParams({
    required this.language,
    required this.level,
    required this.topic,
    this.duration = 120, // Default: 2 daqiqa
    this.questionCount = 5, // Default: 5 ta savol
  });

  /// Copy with
  GenerateListeningParams copyWith({
    String? language,
    String? level,
    String? topic,
    int? duration,
    int? questionCount,
  }) {
    return GenerateListeningParams(
      language: language ?? this.language,
      level: level ?? this.level,
      topic: topic ?? this.topic,
      duration: duration ?? this.duration,
      questionCount: questionCount ?? this.questionCount,
    );
  }

  /// Daraja bo'yicha tavsiya etiladigan davomiylik (soniyalarda)
  static int recommendedDuration(String level) {
    switch (level) {
      case 'A1':
        return 60; // 1 daqiqa — qisqa va sodda
      case 'A2':
        return 90; // 1.5 daqiqa
      case 'B1':
        return 120; // 2 daqiqa
      case 'B2':
        return 180; // 3 daqiqa
      case 'C1':
        return 240; // 4 daqiqa — uzunroq va murakkab
      default:
        return 120;
    }
  }

  /// Daraja bo'yicha tavsiya etiladigan savol soni
  static int recommendedQuestionCount(String level) {
    switch (level) {
      case 'A1':
      case 'A2':
        return 3; // Boshlang'ichlar uchun kam savol
      case 'B1':
        return 5;
      case 'B2':
        return 7;
      case 'C1':
        return 10; // Ilg'or uchun ko'proq savol
      default:
        return 5;
    }
  }

  /// Qisqa versiya (tez mashq uchun)
  GenerateListeningParams toShortMode() {
    return copyWith(
      duration: 60,
      questionCount: 3,
    );
  }

  /// Uzun versiya (chuqur mashq uchun)
  GenerateListeningParams toLongMode() {
    return copyWith(
      duration: duration * 2,
      questionCount: questionCount * 2,
    );
  }
}
