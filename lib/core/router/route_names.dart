// lib/core/router/route_names.dart
// So'zona — Barcha yo'l (route) nomlari va pathlari
// ✅ YANGI: books va bookReader route qo'shildi
// ✅ YANGI: premiumExpired (loss aversion ekrani)
// ✅ YANGI: leaderboard (IELTS kampaniyasi reytingi)
// ✅ YANGI: voiceAssistant — ovozli yordamchi

abstract class RouteNames {
  // ─── Auth ───
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String phoneVerify = 'phone-verify';
  static const String forgotPassword = 'forgot-password';
  static const String setupProfile = 'setup-profile';

  // ─── Student ───
  static const String studentHome = 'student-home';
  static const String flashcards = 'flashcards';
  static const String flashcardDetail = 'flashcard-detail';
  static const String flashcardFolder = 'flashcard-folder';
  static const String flashcardSearch = 'flashcard-search';
  static const String flashcardPractice = 'flashcard-practice';
  static const String flashcardReview = 'flashcard-review';
  static const String quiz = 'quiz';
  static const String quizDetail = 'quiz-detail';
  static const String quizPlay = 'quiz-play';
  static const String quizResult = 'quiz-result';
  static const String listening = 'listening';
  static const String listeningDetail = 'listening-detail';
  static const String speaking = 'speaking';
  static const String speakingSession = 'speaking-session';
  static const String aiTutor = 'ai-tutor';
  static const String aiChat = 'ai-chat';
  static const String artikel = 'artikel';
  static const String artikelPractice = 'artikel-practice';
  static const String progress = 'progress';
  static const String microSession = 'micro-session';
  static const String joinClass = 'join-class';
  static const String studentClasses = 'student-classes';
  static const String studentClassDetail = 'student-class-detail';

  // ─── Teacher ───
  static const String teacherDashboard = 'teacher-dashboard';
  static const String teacherClasses = 'teacher-classes';
  static const String classDetail = 'class-detail';
  static const String classCreate = 'class-create';
  static const String studentDetail = 'student-detail';
  static const String contentGenerator = 'content-generator';
  static const String contentPreview = 'content-preview';
  static const String teacherAnalytics = 'teacher-analytics';
  static const String teacherProfile = 'teacher-profile';
  static const String publishing = 'publishing';

  // ─── Shared ───
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String notifications = 'notifications';
  static const String privacy = 'privacy';

  // ✅ YANGI: Referral tizimi
  static const String referral = 'referral';

  // ─── Premium ───
  static const String premium = 'premium';
  static const String premiumCoach = 'premium-coach';
  // ✅ YANGI: Loss aversion ekrani
  static const String premiumExpired = 'premium-expired';

  // ✅ YANGI: Kitoblar
  static const String books = 'books';
  static const String bookReader = 'book-reader';

  // ✅ YANGI: Leaderboard
  static const String leaderboard = 'leaderboard';

  // ✅ YANGI: Ovozli yordamchi
  static const String voiceAssistant = 'voice-assistant';
}

abstract class RoutePaths {
  // ─── Auth ───
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String phoneVerify = '/phone-verify';
  static const String forgotPassword = '/forgot-password';
  static const String setupProfile = '/setup-profile';

  // ─── Student ───
  static const String studentHome = '/student/home';
  static const String flashcards = '/student/flashcards';
  static const String flashcardSearch = '/student/flashcards/search';
  static const String flashcardDetail = '/student/flashcards/:id';
  static const String flashcardFolder = '/student/flashcards/folder/:id';
  static const String flashcardPractice = '/student/flashcards/:id/practice';
  static const String flashcardReview = '/student/flashcards/review/:id';
  static const String quiz = '/student/quiz';
  static const String quizDetail = '/student/quiz/:id';
  static const String quizPlay = '/student/quiz/play';
  static const String quizResult = '/student/quiz/result';
  static const String listening = '/student/listening';
  static const String listeningDetail = '/student/listening/:id';
  static const String speaking = '/student/speaking';
  static const String speakingSession = '/student/speaking/:id';
  static const String aiTutor = '/student/ai-tutor';
  static const String aiChat = '/student/ai-chat';
  static const String artikel = '/student/artikel';
  static const String artikelPractice = '/student/artikel/:id';
  static const String progress = '/student/progress';
  static const String microSession = '/student/micro-session';
  static const String joinClass = '/student/join-class';
  static const String studentClasses = '/student/classes';
  static const String studentClassDetail = '/student/classes/:id';

  // ─── Teacher ───
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherClasses = '/teacher/classes';
  static const String classDetail = '/teacher/classes/:id';
  static const String classCreate = '/teacher/classes/create';
  static const String studentDetail =
      '/teacher/classes/:classId/student/:studentId';
  static const String contentGenerator = '/teacher/content-generator';
  static const String contentPreview = '/teacher/content-preview';
  static const String teacherAnalytics = '/teacher/class/:classId/analytics';
  static const String teacherProfile = '/teacher/profile';
  static const String publishing = '/teacher/publishing';

  // ─── Shared ───
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String privacy = '/privacy';
  static const String premium = '/premium';
  static const String premiumCoach = '/premium/coach';
  // ✅ YANGI: Loss aversion ekrani
  static const String premiumExpired = '/premium/expired';

  // ✅ YANGI: Referral tizimi
  static const String referral = '/referral';

  // ✅ YANGI: Kitoblar
  static const String books = '/premium/books';
  static const String bookReader = '/premium/books/:level';

  // ✅ YANGI: Leaderboard
  static const String leaderboard = '/leaderboard';

  // ✅ YANGI: Ovozli yordamchi
  static const String voiceAssistant = '/student/voice-assistant';

  // ─── Helper methodlar ───
  static String speakingSessionPath(String id) => '/student/speaking/$id';
  static String listeningDetailPath(String id) => '/student/listening/$id';
  static String quizDetailPath(String id) => '/student/quiz/$id';
  static String flashcardFolderPath(String id) =>
      '/student/flashcards/folder/$id';
  static String flashcardDetailPath(String id) => '/student/flashcards/$id';
  static String flashcardPracticePath(String id) =>
      '/student/flashcards/$id/practice';
  static String flashcardReviewPath(String id) =>
      '/student/flashcards/review/$id';
  static String classDetailPath(String id) => '/teacher/classes/$id';
  static String studentDetailPath(String classId, String studentId) =>
      '/teacher/classes/$classId/student/$studentId';
  static String teacherAnalyticsPath(String classId) =>
      '/teacher/class/$classId/analytics';
  static String artikelPracticePath(String id) => '/student/artikel/$id';
  static String studentClassDetailPath(String id) => '/student/classes/$id';

  // ✅ YANGI: Kitob helper
  static String bookReaderPath(String level) => '/premium/books/$level';
}
