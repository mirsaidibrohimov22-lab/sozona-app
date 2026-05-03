// QO'YISH: lib/features/teacher/content_generator/domain/repositories/content_generator_repository.dart
// Content Generator Repository Interface — Domain layer

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';

/// Content Generator Repository Interface
///
/// Bolaga: Bu — "shartnoma". Repository'ning qanday bo'lishi kerakligini yozadi.
/// Haqiqiy kod Data layer'da yoziladi, bu yerda faqat qoidalar.
abstract class ContentGeneratorRepository {
  /// Quiz yaratish
  ///
  /// Params:
  /// - language: en | de
  /// - level: A1 | A2 | B1 | B2 | C1
  /// - topic: Mavzu (masalan: "Daily Routine")
  /// - questionCount: Savol soni
  /// - difficulty: easy | medium | hard (ixtiyoriy)
  ///
  /// Returns:
  /// - Right(GeneratedContent): Muvaffaqiyatli yaratilgan quiz
  /// - Left(Failure): Xatolik (NetworkFailure, ServerFailure, AIFailure)
  Future<Either<Failure, GeneratedContent>> generateQuiz({
    required String language,
    required String level,
    required String topic,
    required int questionCount,
    String difficulty = 'medium',
    String grammar = '',
  });

  /// Flashcard to'plami yaratish
  ///
  /// Params:
  /// - language: en | de
  /// - level: A1 | A2 | B1 | B2 | C1
  /// - topic: Mavzu
  /// - cardCount: Kartochka soni
  /// - includeExamples: Misol gaplar qo'shilsinmi? (default: true)
  /// - includePronunciation: Talaffuz qo'shilsinmi? (default: true)
  ///
  /// Returns:
  /// - Right(GeneratedContent): Muvaffaqiyatli yaratilgan flashcard set
  /// - Left(Failure): Xatolik
  Future<Either<Failure, GeneratedContent>> generateFlashcards({
    required String language,
    required String level,
    required String topic,
    required int cardCount,
    bool includeExamples = true,
    bool includePronunciation = true,
  });

  /// Listening mashqi yaratish
  ///
  /// Params:
  /// - language: en | de
  /// - level: A1 | A2 | B1 | B2 | C1
  /// - topic: Mavzu
  /// - duration: Taxminiy audio davomiyligi (soniyalarda, default: 120)
  /// - questionCount: Savol soni (default: 5)
  /// - grammar: Grammatika mavzusi (ixtiyoriy, masalan: "present perfect")
  ///
  /// Returns:
  /// - Right(GeneratedContent): Muvaffaqiyatli yaratilgan listening
  /// - Left(Failure): Xatolik
  ///
  /// Note: Audio fayllar TTS orqali keyinroq yaratiladi
  Future<Either<Failure, GeneratedContent>> generateListening({
    required String language,
    required String level,
    required String topic,
    int duration = 120,
    int questionCount = 5,
    String grammar = '',
  });

  /// Yaratilgan kontentni preview qilish uchun olish
  ///
  /// Bu method'ni ishlatish kerakligi:
  /// Agar kontent vaqtinchalik saqlangan bo'lsa (masalan, cache'da yoki
  /// local database'da), uni olish uchun ishlatiladi.
  ///
  /// Returns:
  /// - Right(GeneratedContent): Topilgan kontent
  /// - Left(Failure): Topilmadi yoki xatolik
  Future<Either<Failure, GeneratedContent>> getGeneratedContent({
    required String contentId,
  });

  /// Yaratilgan kontentni tahrirlash
  ///
  /// Teacher AI yaratgan kontentni ko'rib chiqib, o'zgartirishi mumkin.
  /// Masalan: savol matnini tuzatish, javobni o'zgartirish, etc.
  ///
  /// Params:
  /// - contentId: Kontent ID
  /// - updatedData: Yangilangan data (faqat o'zgargan qismlar)
  ///
  /// Returns:
  /// - Right(GeneratedContent): Yangilangan kontent
  /// - Left(Failure): Xatolik
  Future<Either<Failure, GeneratedContent>> updateGeneratedContent({
    required String contentId,
    required Map<String, dynamic> updatedData,
  });

  /// Yaratilgan kontentni o'chirish (agar kerak bo'lmasa)
  ///
  /// Params:
  /// - contentId: Kontent ID
  ///
  /// Returns:
  /// - Right(void): Muvaffaqiyatli o'chirildi
  /// - Left(Failure): Xatolik
  Future<Either<Failure, void>> deleteGeneratedContent({
    required String contentId,
  });
}
