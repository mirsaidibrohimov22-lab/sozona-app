// ═══════════════════════════════════════════════════════════════
// SO'ZONA — App Constants
// ═══════════════════════════════════════════════════════════════

/// Ilovaning umumiy konstantalari — barcha "sehrli raqamlar" shu yerda.
class AppConstants {
  AppConstants._();

  // 📱 APP
  static const String appName = "So'zona";
  static const String appTagline = "Til o'rganishning oson yo'li";

  // 🌐 DEFAULTS
  static const String defaultLanguage = 'en';
  static const String defaultUiLanguage = 'uz';
  static const String defaultLevel = 'A1';
  static const int defaultGoalMinutes = 20;

  // ⏱️ MICRO SESSION
  static const int microSessionDurationMin = 10;
  static const int microSessionDefaultIntervalMin = 60;

  // 🤖 RATE LIMITS
  static const int maxAiRequestsPerMinute = 60;
  static const int maxChatMessagesPerMinute = 30;
  static const int maxContentCreationPerHour = 20;
  static const int maxOtpAttemptsPerHour = 5;
  static const int maxJoinClassAttemptsPerHour = 10;

  // 📊 QUIZ
  static const int defaultQuizQuestionCount = 10;
  static const int minQuizQuestionCount = 3;
  static const int maxQuizQuestionCount = 30;
  static const int defaultQuizTimePerQuestion = 30;
  static const double passingScorePercent = 60.0;

  // 🃏 FLASHCARD
  static const int defaultFlashcardCount = 20;
  static const int minFlashcardCount = 5;
  static const int maxFlashcardCount = 50;

  // 🔄 SPACED REPETITION
  static const int spacedRepInterval1 = 1;
  static const int spacedRepInterval2 = 3;
  static const int spacedRepInterval3 = 7;
  static const int spacedRepMasteredStreak = 3;

  // 👥 CLASS
  static const int joinCodeLength = 6;
  static const int maxStudentsPerClass = 50;

  // 📤 FILE LIMITS
  static const int maxAvatarSizeMB = 5;
  static const int maxAudioSizeMB = 50;

  // ⏳ TIMEOUT
  static const int apiTimeoutSeconds = 30;
  static const int aiTimeoutSeconds = 60;
  static const int otpTimeoutSeconds = 60;

  // 📐 INPUT VALIDATION
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int otpLength = 6;

  // 🔥 XP
  static const int xpPerQuizComplete = 50;
  static const int xpPerFlashcardSet = 30;
  static const int xpPerListeningComplete = 40;
  static const int xpPerSpeakingComplete = 60;
  static const int xpPerMicroSession = 25;
  static const int xpStreakBonus = 10;
}
