// lib/core/constants/api_endpoints.dart
// So'zona — Cloud Functions endpoint nomlari
// ✅ YANGILANGAN: Adaptive Learning + Speaking Assessment + AI Chat v2

class ApiEndpoints {
  ApiEndpoints._();

  // ═══════════════════════════════════
  // MAVJUD Cloud Function nomlari
  // ═══════════════════════════════════

  static const String generateQuiz = 'generateQuiz';
  static const String generateFlashcards = 'generateFlashcards';
  static const String generateListening = 'generateListening';
  static const String generateSpeaking = 'createSpeakingDialog';
  static const String explainTopic = 'explainTopic';
  static const String motivationMessage = 'getMotivationMessage';
  static const String analyzeWeakness = 'analyzeWeakness';
  static const String proactiveSuggestion = 'getProactiveSuggestion';
  static const String teachingAdvice = 'getTeachingAdvice';

  // ═══════════════════════════════════
  // ✨ YANGI: Adaptive Learning Functions
  // ═══════════════════════════════════

  /// Adaptive Quiz (60% zaif, 20% review, 20% yangi)
  static const String createAdaptiveQuiz = 'createAdaptiveQuiz';

  /// Alias — quiz_provider.dart ishlatadi
  static const String adaptiveQuiz = 'createAdaptiveQuiz';

  /// AI Chat v2 — o'qituvchi kabi (suggestions, grammarTip)
  static const String chatWithAI = 'chatWithAI';

  /// Tezkor grammatik tushuntirish
  static const String quickGrammar = 'quickGrammar';

  /// Speaking vazifa yaratish
  static const String createSpeakingTask = 'createSpeakingTask';

  /// Speaking natijasini AI baholash (pronunciation/grammar/fluency)
  static const String assessSpeaking = 'assessSpeakingResult';

  /// Adaptive mashq rejasi olish
  static const String getAdaptivePlan = 'getAdaptivePlan';

  /// Mashq natijasini saqlash (activity tracker)
  static const String recordActivity = 'recordActivity';

  /// Foydalanuvchi AI profilini olish
  static const String fetchUserProfile = 'fetchUserProfile';

  // ═══════════════════════════════════
  // Timeout
  // ═══════════════════════════════════

  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration longTimeout = Duration(seconds: 60);
  static const Duration assessmentTimeout = Duration(seconds: 90);
  static const Duration shortTimeout = Duration(seconds: 10);
  // ═══════════════════════════════════
  // ✅ YANGI: AI Murabbiy tizimi
  // ═══════════════════════════════════

  /// Xato yozish (quiz/listening/speaking tugaganda)
  static const String recordMistake = 'recordMistake';

  /// Tavsiya olish (contentId bilan)
  static const String getRecommendations = 'getRecommendations';

  /// Takrorlashni tugallash (SM-2 yangilanadi)
  static const String completeReview = 'completeReview';

  /// Haftalik hisobotni darhol yaratish (test/debug)
  static const String triggerWeeklyReport = 'triggerWeeklyReport';
}
