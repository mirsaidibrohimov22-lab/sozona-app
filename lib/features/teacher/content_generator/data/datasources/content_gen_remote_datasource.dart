// lib/features/teacher/content_generator/data/datasources/content_gen_remote_datasource.dart
// ✅ FIX 1: catch blokida xatoni yashirib qo'ymay, exception throw qilinadi
// ✅ FIX 2: Xato logi konsolga chiqariladi (debug uchun)
// ✅ FIX 3: Mock data olib tashlandi — haqiqiy AI ishlatiladi

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:my_first_app/features/teacher/content_generator/data/models/generated_content_model.dart';

abstract class ContentGeneratorRemoteDataSource {
  Future<GeneratedContentModel> generateQuiz({
    required String language,
    required String level,
    required String topic,
    required int questionCount,
    required String difficulty,
    String grammar = '',
  });

  Future<GeneratedContentModel> generateFlashcards({
    required String language,
    required String level,
    required String topic,
    required int cardCount,
    required bool includeExamples,
    required bool includePronunciation,
  });

  Future<GeneratedContentModel> generateListening({
    required String language,
    required String level,
    required String topic,
    required int duration,
    required int questionCount,
  });
}

class ContentGeneratorRemoteDataSourceImpl
    implements ContentGeneratorRemoteDataSource {
  final FirebaseFunctions functions;

  ContentGeneratorRemoteDataSourceImpl({required this.functions});

  // ─────────────────────────────────────────────
  // QUIZ
  // ─────────────────────────────────────────────

  @override
  Future<GeneratedContentModel> generateQuiz({
    required String language,
    required String level,
    required String topic,
    required int questionCount,
    required String difficulty,
    String grammar = '',
  }) async {
    try {
      debugPrint('🚀 generateQuiz chaqirilmoqda: $topic | $level | $language');
      final callable = functions.httpsCallable(
        'generateQuiz',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
      );
      final result = await callable.call({
        'language': language,
        'level': level,
        'topic': topic,
        'questionCount': questionCount,
        'difficulty': difficulty,
        'grammar': grammar,
        'save': false,
      });
      final data = result.data as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error']);
      debugPrint(
          '✅ generateQuiz muvaffaqiyatli: ${(data['questions'] as List?)?.length ?? 0} savol');
      return GeneratedContentModel.fromJson({...data, 'aiModel': 'gemini'});
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ generateQuiz [${e.code}]: ${e.message}');
      throw Exception('Quiz yaratishda xatolik [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('❌ generateQuiz kutilmagan xato: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // FLASHCARDS
  // ─────────────────────────────────────────────

  @override
  Future<GeneratedContentModel> generateFlashcards({
    required String language,
    required String level,
    required String topic,
    required int cardCount,
    required bool includeExamples,
    required bool includePronunciation,
  }) async {
    try {
      debugPrint('🚀 generateFlashcards chaqirilmoqda: $topic | $level');
      final callable = functions.httpsCallable(
        'generateFlashcards',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
      );
      final result = await callable.call({
        'language': language,
        'level': level,
        'topic': topic,
        'cardCount': cardCount,
        'includeExamples': includeExamples,
        'includePronunciation': includePronunciation,
      });
      final data = result.data as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error']);
      debugPrint('✅ generateFlashcards muvaffaqiyatli');
      return GeneratedContentModel.fromJson({...data, 'aiModel': 'gemini'});
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ generateFlashcards [${e.code}]: ${e.message}');
      throw Exception('Flashcard yaratishda xatolik [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('❌ generateFlashcards kutilmagan xato: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // LISTENING
  // ─────────────────────────────────────────────

  @override
  Future<GeneratedContentModel> generateListening({
    required String language,
    required String level,
    required String topic,
    required int duration,
    required int questionCount,
  }) async {
    try {
      debugPrint(
          '🚀 generateListening chaqirilmoqda: $topic | $level | ${duration}s');
      final callable = functions.httpsCallable(
        'generateListening',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
      );
      final result = await callable.call({
        'language': language,
        'level': level,
        'topic': topic,
        'duration': duration,
        'questionCount': questionCount,
      });
      final data = result.data as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error']);
      debugPrint('✅ generateListening muvaffaqiyatli, '
          'transcript: ${(data['transcript'] as String?)?.length ?? 0} belgi, '
          'savollar: ${(data['questions'] as List?)?.length ?? 0} ta');
      return GeneratedContentModel.fromJson({...data, 'aiModel': 'gemini'});
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ generateListening [${e.code}]: ${e.message}');
      throw Exception('Listening yaratishda xatolik [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('❌ generateListening kutilmagan xato: $e');
      rethrow;
    }
  }
}
