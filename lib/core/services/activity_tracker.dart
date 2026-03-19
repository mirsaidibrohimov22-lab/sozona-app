// lib/core/services/activity_tracker.dart
// So'zona — Activity Tracker Utility
// ✅ Barcha modullar (quiz, flashcard, speaking, listening) shu orqali natija saqlaydi
// ✅ Natija saqlanadi → user profili avtomatik yangilanadi (backend da)

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/api_endpoints.dart';

/// Mashq natijasini backend ga yuborish uchun yordamchi klass.
///
/// Bu klass orqali saqlangan natijalar:
/// 1. Firestore `activities` kolleksiyasiga yoziladi
/// 2. Foydalanuvchi profili (vocabularyLevel, grammarLevel, ...) yangilanadi
/// 3. Zaif/kuchli mavzular aniqlanadi
/// 4. Adaptive tizim keyingi mashqlarni shunga qarab tanlaydi
class ActivityTracker {
  ActivityTracker._();

  static final _fn = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Quiz tugaganda chaqiring
  static Future<void> recordQuiz({
    required String topic,
    required String language,
    required String level,
    required int correctAnswers,
    required int wrongAnswers,
    required int responseTime,
    required double scorePercent,
    List<String> weakItems = const [],
    String? contentId,
  }) async {
    await _record(
      skillType: 'quiz',
      topic: topic,
      language: language,
      level: level,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      responseTime: responseTime,
      scorePercent: scorePercent,
      weakItems: weakItems,
      contentId: contentId,
    );
  }

  /// Flashcard sessiyasi tugaganda chaqiring
  static Future<void> recordFlashcard({
    required String topic,
    required String language,
    required String level,
    required int correctAnswers,
    required int wrongAnswers,
    required int responseTime,
    required double scorePercent,
    String? contentId,
  }) async {
    await _record(
      skillType: 'flashcard',
      topic: topic,
      language: language,
      level: level,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      responseTime: responseTime,
      scorePercent: scorePercent,
      contentId: contentId,
    );
  }

  /// Speaking baholash tugaganda chaqiring
  static Future<void> recordSpeaking({
    required String topic,
    required String language,
    required String level,
    required int overallScore,
    required int responseTime,
    List<String> grammarErrors = const [],
    String? contentId,
  }) async {
    await _record(
      skillType: 'speaking',
      topic: topic,
      language: language,
      level: level,
      correctAnswers: overallScore >= 60 ? 1 : 0,
      wrongAnswers: overallScore < 60 ? 1 : 0,
      responseTime: responseTime,
      scorePercent: overallScore.toDouble(),
      grammarErrors: grammarErrors,
      contentId: contentId,
    );
  }

  /// Listening tugaganda chaqiring
  static Future<void> recordListening({
    required String topic,
    required String language,
    required String level,
    required int correctAnswers,
    required int wrongAnswers,
    required int responseTime,
    required double scorePercent,
    List<String> weakItems = const [],
    String? contentId,
  }) async {
    await _record(
      skillType: 'listening',
      topic: topic,
      language: language,
      level: level,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      responseTime: responseTime,
      scorePercent: scorePercent,
      weakItems: weakItems,
      contentId: contentId,
    );
  }

  /// Ichki yordamchi — barcha modullar shu orqali saqlaydi
  static Future<void> _record({
    required String skillType,
    required String topic,
    required String language,
    required String level,
    required int correctAnswers,
    required int wrongAnswers,
    required int responseTime,
    required double scorePercent,
    List<String> vocabularyUsed = const [],
    List<String> grammarErrors = const [],
    List<String> weakItems = const [],
    String? contentId,
  }) async {
    try {
      final callable = _fn.httpsCallable(
        ApiEndpoints.recordActivity,
        options: HttpsCallableOptions(timeout: ApiEndpoints.defaultTimeout),
      );

      await callable.call({
        'skillType': skillType,
        'topic': topic,
        'difficulty': 'medium',
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
        'responseTime': responseTime,
        'vocabularyUsed': vocabularyUsed,
        'grammarErrors': grammarErrors,
        'language': language,
        'level': level,
        'scorePercent': scorePercent,
        'weakItems': weakItems,
        'strongItems': <String>[],
        if (contentId != null) 'contentId': contentId,
      });

      debugPrint(
        '📊 Activity saqlandi: $skillType | $topic | ${scorePercent.toStringAsFixed(0)}%',
      );
    } catch (e) {
      // Activity saqlash xatosi sessiyani HECH QACHON buzmaydi
      debugPrint('⚠️ Activity saqlash xatosi ($skillType): $e');
    }
  }
}

/// ActivityTracker provider (ixtiyoriy — static metodlar ham ishlaydi)
final activityTrackerProvider = Provider<ActivityTracker>((_) {
  return ActivityTracker._();
});
