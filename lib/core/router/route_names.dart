// lib/core/router/route_names.dart
// So'zona — Barcha yo'l (route) nomlari va pathlari
// ✅ 1-KUN FIX: Barcha route pathlari markazlashtirildi
// ✅ 1-KUN FIX: Flashcard review, quiz result, listening result qo'shildi
// ✅ 1-KUN FIX: Noto'g'ri va takroriy pathlar olib tashlandi
// ✅ REFACTOR FIX: teacherProfile route qo'shildi
//   SABAB: Teacher shell'ga 4-tab (Profil) qo'shildi,
//          uning path va name'i kerak

/// Route nomlari — barcha ekranlar uchun yagona manba
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
  // ✅ YANGI: Teacher profil tab uchun alohida route name
  static const String teacherProfile = 'teacher-profile';
  static const String publishing = 'publishing';

  // ─── Shared ───
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String notifications = 'notifications';
  static const String privacy = 'privacy';
}

/// Route yo'llari — barcha screen uchun yagona path manbai
/// ⚠️ QOIDA: Hech qayerda path string hardcode qilinmasin!
/// Faqat RoutePaths.xxx ishlatilsin.
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
  static const String aiChat = '/student/ai-chat';
  static const String artikel = '/student/artikel';
  static const String artikelPractice = '/student/artikel/:id';
  static const String progress = '/student/progress';
  static const String microSession = '/student/micro-session';
  static const String joinClass = '/student/join-class';
  static const String studentClasses = '/student/classes';
  static const String studentClassDetail = '/student/classes/:id';

  static String studentClassDetailPath(String id) => '/student/classes/$id';

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
  // ✅ YANGI: Teacher shell ichidagi profil tab uchun alohida path
  // /profile path student shell ichida bo'lgani uchun conflict bo'lmaslik uchun
  // teacher shell uchun /teacher/profile path ishlatiladi
  static const String teacherProfile = '/teacher/profile';
  static const String publishing = '/teacher/publishing';

  // ─── Shared ───
  // /profile — student shell ichida tab sifatida ishlatiladi
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String privacy = '/privacy';

  // ─── Helper methodlar — dynamic path yaratish uchun ───

  /// Speaking session: /student/speaking/abc123
  static String speakingSessionPath(String id) => '/student/speaking/$id';

  /// Listening detail: /student/listening/abc123
  static String listeningDetailPath(String id) => '/student/listening/$id';

  /// Quiz detail: /student/quiz/abc123
  static String quizDetailPath(String id) => '/student/quiz/$id';

  /// Flashcard folder: /student/flashcards/folder/abc123
  static String flashcardFolderPath(String id) =>
      '/student/flashcards/folder/$id';

  /// Flashcard detail (papka ichidagi kartochkalar): /student/flashcards/abc123
  static String flashcardDetailPath(String id) => '/student/flashcards/$id';

  /// Flashcard practice: /student/flashcards/abc123/practice
  static String flashcardPracticePath(String id) =>
      '/student/flashcards/$id/practice';

  /// Flashcard review: /student/flashcards/review/abc123
  static String flashcardReviewPath(String id) =>
      '/student/flashcards/review/$id';

  /// Class detail: /teacher/classes/abc123
  static String classDetailPath(String id) => '/teacher/classes/$id';

  /// Student detail: /teacher/classes/abc/student/xyz
  static String studentDetailPath(String classId, String studentId) =>
      '/teacher/classes/$classId/student/$studentId';

  /// Teacher analytics: /teacher/class/abc123/analytics
  static String teacherAnalyticsPath(String classId) =>
      '/teacher/class/$classId/analytics';

  /// Artikel practice: /student/artikel/abc123
  static String artikelPracticePath(String id) => '/student/artikel/$id';
}
