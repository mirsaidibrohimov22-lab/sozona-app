// lib/core/constants/firestore_paths.dart
// So'zona — Barcha Firestore collection nomlari bir joyda
// ✅ 1-KUN FIX (K9): listeningExercises → listening_exercises
//    Sabab: datasource va firestore.rules 'listening_exercises' (snake_case) ishlatadi,
//    lekin bu fayl 'listeningExercises' (camelCase) edi → query bo'sh natija qaytarardi
//    Endi hammasi bir xil: listening_exercises
// ✅ 1-KUN FIX: chatHistory path standartlashtirildi
// ✅ FIX: dailyPlanDoc() va dailyPlansCollection() helper saqlanadi

class FirestorePaths {
  FirestorePaths._();

  // ─── ROOT COLLECTIONS ───
  static const String users = 'users';
  static const String classes = 'classes';
  static const String progress = 'progress';
  static const String attempts = 'attempts';
  static const String publishSchedules = 'publishSchedules';
  static const String dataRequests = 'dataRequests';
  static const String notifications = 'notifications';

  // ✅ DEPRECATED — root dailyPlans collection artiq ishlatilmaydi.
  // Faqat migration uchun read qoldirilgan. Yangi kod YOZMASIN.
  // ignore: constant_identifier_names
  @Deprecated('Use dailyPlanDoc(uid, date) instead')
  static const String dailyPlansLegacy = 'dailyPlans';

  // ─── CONTENT ───
  static const String quizzes = 'content';
  static const String folders = 'folders';
  static const String flashcards = 'flashcards';
  static const String artikelWords = 'artikel_words';
  static const String speakingExercises = 'speaking_exercises';

  // ✅ 1-KUN FIX (K9): camelCase → snake_case
  // ESKI: 'listeningExercises' — Firestore'da bunday collection yo'q edi!
  // YANGI: 'listening_exercises' — firestore.rules va datasource bilan mos
  static const String listeningExercises = 'listening_exercises';

  // ✅ 1-KUN FIX: chatHistory yagona standart
  // Chat messages users subcollection ichida saqlanadi
  static const String chatHistory = 'chatHistory';

  // ─── SUB-COLLECTION PATH HELPERS ───
  static String userProgress(String uid) => 'progress/$uid';
  static String weakItems(String uid) => 'progress/$uid/weakItems';

  // ✅ FIX: YAGONA dailyPlans path — progress subcollection ichida
  // Ishlatish: FirestorePaths.dailyPlanDoc(userId, '2025-01-15')
  static String dailyPlansCollection(String uid) => 'progress/$uid/dailyPlans';
  static String dailyPlanDoc(String uid, String dateStr) =>
      'progress/$uid/dailyPlans/$dateStr';

  static String classMembers(String cid) => 'classes/$cid/members';
  static String classContent(String cid) => 'classes/$cid/content';
  static String userChat(String uid) => 'users/$uid/chatHistory';
  static String artikelProgress(String uid) => 'users/$uid/artikel_progress';
  static String learnerProfile(String uid) => 'users/$uid/learnerProfile';

  // ─── Listening results ───
  static const String listeningResults = 'listening_results';

  // ✅ YANGI: Referral tizimi
  static const String referralCodes = 'referral_codes';
}
