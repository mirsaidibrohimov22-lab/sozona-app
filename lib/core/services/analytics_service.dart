// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Analytics Service
// ═══════════════════════════════════════════════════════════════

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/services/logger_service.dart';

/// Firebase Analytics orqali foydalanuvchi harakatlarini kuzatish.
///
/// Bolaga tushuntirish:
/// Maktabda davomatni belgilashadi — kim keldi, kim kelmadi.
/// Analytics ham shunday — ilova ichida kim nima qilganini yozadi.
/// Bu ma'lumot ilovani yaxshilash uchun ishlatiladi.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// Analytics observer — GoRouter bilan ishlaydi.
  FirebaseAnalyticsObserver get observer {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // ═══════════════════════════════════
  // 👤 USER PROPERTIES
  // ═══════════════════════════════════

  /// Foydalanuvchi xususiyatlarini o'rnatish (login/signup da).
  Future<void> setUserProperties({
    required String userId,
    required String role,
    required String language,
    required String level,
    required String uiLanguage,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'role', value: role);
    await _analytics.setUserProperty(
      name: 'learning_language',
      value: language,
    );
    await _analytics.setUserProperty(name: 'level', value: level);
    await _analytics.setUserProperty(name: 'ui_language', value: uiLanguage);
    LoggerService.debug('Analytics: user properties set for $userId');
  }

  /// Logout da user properties tozalash.
  Future<void> clearUserProperties() async {
    await _analytics.setUserId(id: null);
  }

  // ═══════════════════════════════════
  // 📱 SCREEN VIEWS
  // ═══════════════════════════════════

  /// Ekran ko'rishni qayd qilish.
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
    LoggerService.debug('Analytics: screen_view → $screenName');
  }

  // ═══════════════════════════════════
  // 🔐 AUTH EVENTS
  // ═══════════════════════════════════

  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogout() async {
    await _log('logout');
  }

  // ═══════════════════════════════════
  // 📊 QUIZ EVENTS
  // ═══════════════════════════════════

  Future<void> logQuizStarted({
    required String quizId,
    required String topic,
    required String level,
  }) async {
    await _log('quiz_started', {
      'quiz_id': quizId,
      'topic': topic,
      'level': level,
    });
  }

  Future<void> logQuizCompleted({
    required String quizId,
    required int score,
    required int maxScore,
    required bool passed,
    required int timeSpent,
  }) async {
    await _log('quiz_completed', {
      'quiz_id': quizId,
      'score': score,
      'max_score': maxScore,
      'passed': passed,
      'time_spent': timeSpent,
      'percentage': maxScore > 0 ? (score / maxScore * 100).round() : 0,
    });
  }

  // ═══════════════════════════════════
  // 🃏 FLASHCARD EVENTS
  // ═══════════════════════════════════

  Future<void> logFlashcardReviewed({
    required String setId,
    required int cardsReviewed,
    required int cardsMastered,
  }) async {
    await _log('flashcard_reviewed', {
      'set_id': setId,
      'cards_reviewed': cardsReviewed,
      'cards_mastered': cardsMastered,
    });
  }

  // ═══════════════════════════════════
  // 🎧 LISTENING EVENTS
  // ═══════════════════════════════════

  Future<void> logListeningCompleted({
    required String exerciseId,
    required int score,
    required int maxScore,
  }) async {
    await _log('listening_completed', {
      'exercise_id': exerciseId,
      'score': score,
      'max_score': maxScore,
    });
  }

  // ═══════════════════════════════════
  // 🗣️ SPEAKING EVENTS
  // ═══════════════════════════════════

  Future<void> logSpeakingCompleted({
    required String exerciseId,
    required int fluencyScore,
    required int grammarScore,
    required int turns,
  }) async {
    await _log('speaking_completed', {
      'exercise_id': exerciseId,
      'fluency_score': fluencyScore,
      'grammar_score': grammarScore,
      'turns': turns,
    });
  }

  // ═══════════════════════════════════
  // 🤖 AI EVENTS
  // ═══════════════════════════════════

  Future<void> logAiRequest({
    required String promptType,
    required String provider,
    required int latencyMs,
    required bool success,
  }) async {
    await _log('ai_request', {
      'prompt_type': promptType,
      'provider': provider,
      'latency_ms': latencyMs,
      'success': success,
    });
  }

  Future<void> logAiChatMessage() async {
    await _log('ai_chat_message');
  }

  // ═══════════════════════════════════
  // 🔥 STREAK & PROGRESS EVENTS
  // ═══════════════════════════════════

  Future<void> logStreakUpdated({required int streakDays}) async {
    await _log('streak_updated', {'streak_days': streakDays});
  }

  Future<void> logLevelChanged({
    required String oldLevel,
    required String newLevel,
  }) async {
    await _log('level_changed', {
      'old_level': oldLevel,
      'new_level': newLevel,
    });
  }

  Future<void> logXpEarned({
    required int amount,
    required String source,
  }) async {
    await _log('xp_earned', {'amount': amount, 'source': source});
  }

  // ═══════════════════════════════════
  // ⏰ MICRO SESSION EVENTS
  // ═══════════════════════════════════

  Future<void> logMicroSessionStarted({required String sessionType}) async {
    await _log('micro_session_started', {'session_type': sessionType});
  }

  Future<void> logMicroSessionCompleted({
    required String sessionType,
    required int durationSeconds,
  }) async {
    await _log('micro_session_completed', {
      'session_type': sessionType,
      'duration_seconds': durationSeconds,
    });
  }

  // ═══════════════════════════════════
  // 👨‍🏫 TEACHER EVENTS
  // ═══════════════════════════════════

  Future<void> logContentGenerated({
    required String contentType,
    required String level,
  }) async {
    await _log('content_generated', {
      'content_type': contentType,
      'level': level,
    });
  }

  Future<void> logContentPublished({
    required String contentType,
    required String classId,
  }) async {
    await _log('content_published', {
      'content_type': contentType,
      'class_id': classId,
    });
  }

  Future<void> logClassCreated() async {
    await _log('class_created');
  }

  // ═══════════════════════════════════
  // 🏷️ ARTIKEL EVENTS (German only)
  // ═══════════════════════════════════

  Future<void> logArtikelPracticed({
    required int correct,
    required int total,
  }) async {
    await _log('artikel_practiced', {'correct': correct, 'total': total});
  }

  // ═══════════════════════════════════
  // 📦 PRIVATE HELPER
  // ═══════════════════════════════════

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    if (kDebugMode) {
      LoggerService.debug('Analytics: $name ${params ?? ""}');
    }
    await _analytics.logEvent(name: name, parameters: params);
  }
}

// ═══════════════════════════════════
// RIVERPOD PROVIDER
// ═══════════════════════════════════

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
