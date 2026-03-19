// QO'YISH: lib/features/learning_loop/presentation/providers/adaptive_learning_provider.dart
// So'zona — Adaptive Learning Riverpod Provider
// UI va AdaptiveEngineService orasidagi ko'prik

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/services/adaptive_engine_service.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/activity_record.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/user_ai_profile.dart';

// ═══════════════════════════════════
// STATE
// ═══════════════════════════════════

class AdaptiveLearningState {
  final bool isLoading;
  final String? error;

  /// Foydalanuvchi AI profili
  final UserAiProfile? profile;

  /// Adaptive mashq rejasi
  final AdaptivePlanData? plan;

  /// AI Chat javoblari
  final AiChatResponse? lastChatResponse;

  /// Speaking vazifa
  final SpeakingTaskData? currentSpeakingTask;

  /// Speaking baholash
  final SpeakingAssessmentData? lastSpeakingAssessment;

  /// Adaptive quiz ma'lumotlari
  final Map<String, dynamic>? adaptiveQuizData;

  /// Motivatsiya xabari
  final String? motivationNote;

  const AdaptiveLearningState({
    this.isLoading = false,
    this.error,
    this.profile,
    this.plan,
    this.lastChatResponse,
    this.currentSpeakingTask,
    this.lastSpeakingAssessment,
    this.adaptiveQuizData,
    this.motivationNote,
  });

  AdaptiveLearningState copyWith({
    bool? isLoading,
    String? error,
    UserAiProfile? profile,
    AdaptivePlanData? plan,
    AiChatResponse? lastChatResponse,
    SpeakingTaskData? currentSpeakingTask,
    SpeakingAssessmentData? lastSpeakingAssessment,
    Map<String, dynamic>? adaptiveQuizData,
    String? motivationNote,
  }) {
    return AdaptiveLearningState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profile: profile ?? this.profile,
      plan: plan ?? this.plan,
      lastChatResponse: lastChatResponse ?? this.lastChatResponse,
      currentSpeakingTask: currentSpeakingTask ?? this.currentSpeakingTask,
      lastSpeakingAssessment:
          lastSpeakingAssessment ?? this.lastSpeakingAssessment,
      adaptiveQuizData: adaptiveQuizData ?? this.adaptiveQuizData,
      motivationNote: motivationNote ?? this.motivationNote,
    );
  }
}

// ═══════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════

class AdaptiveLearningNotifier extends StateNotifier<AdaptiveLearningState> {
  final AdaptiveEngineService _engine;

  AdaptiveLearningNotifier(this._engine) : super(const AdaptiveLearningState());

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ─── PROFIL ───

  /// Profilni yuklash
  Future<void> loadProfile() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    final profile = await _engine.getUserProfile();

    if (!mounted) return;
    state = state.copyWith(
      isLoading: false,
      profile: profile,
    );
  }

  // ─── ADAPTIVE PLAN ───

  /// Mashq rejasini olish
  Future<void> loadAdaptivePlan(String language) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    final plan = await _engine.getAdaptivePlan(language: language);

    if (!mounted) return;
    state = state.copyWith(
      isLoading: false,
      plan: plan,
      motivationNote: plan?.motivationNote,
    );
  }

  // ─── ACTIVITY SAQLASH ───

  /// Mashq natijasini saqlash
  Future<void> saveActivityResult({
    required SkillType skillType,
    required String topic,
    required DifficultyLevel difficulty,
    required int correctAnswers,
    required int wrongAnswers,
    required int responseTime,
    required String language,
    required String level,
    List<String> vocabularyUsed = const [],
    List<String> grammarErrors = const [],
    String? sessionId,
    String? contentId,
  }) async {
    final total = correctAnswers + wrongAnswers;
    final scorePercent = total > 0 ? (correctAnswers / total) * 100 : 0.0;

    final record = ActivityRecord(
      userId: _uid,
      skillType: skillType,
      topic: topic,
      difficulty: difficulty,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      responseTime: responseTime,
      vocabularyUsed: vocabularyUsed,
      grammarErrors: grammarErrors,
      language: language,
      level: level,
      scorePercent: scorePercent,
      weakItems: grammarErrors,
      strongItems: [],
      sessionId: sessionId,
      contentId: contentId,
      timestamp: DateTime.now(),
    );

    await _engine.recordActivity(record);

    // Profilni yangilash
    await loadProfile();
  }

  // ─── ADAPTIVE QUIZ ───

  /// Adaptive quiz yaratish (60/20/20)
  Future<void> generateAdaptiveQuiz({
    required String language,
    required String level,
    int questionCount = 10,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    final quizData = await _engine.generateAdaptiveQuiz(
      language: language,
      level: level,
      questionCount: questionCount,
    );

    if (!mounted) return;
    state = state.copyWith(
      isLoading: false,
      adaptiveQuizData: quizData,
    );
  }

  // ─── AI CHAT ───

  /// AI o'qituvchi bilan suhbat
  Future<AiChatResponse?> sendChatMessage({
    required String message,
    required String language,
    List<Map<String, String>> history = const [],
  }) async {
    if (!mounted) return null;
    state = state.copyWith(isLoading: true);

    final response = await _engine.chatWithTeacher(
      message: message,
      language: language,
      history: history,
    );

    if (!mounted) return null;
    state = state.copyWith(
      isLoading: false,
      lastChatResponse: response,
    );
    return response;
  }

  // ─── SPEAKING ───

  /// Speaking vazifa olish
  Future<void> loadSpeakingTask({
    required String language,
    required String level,
    String? topic,
    String taskType = 'describe',
  }) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    final task = await _engine.createSpeakingTask(
      language: language,
      level: level,
      topic: topic,
      taskType: taskType,
    );

    if (!mounted) return;
    state = state.copyWith(
      isLoading: false,
      currentSpeakingTask: task,
    );
  }

  /// Speaking natijasini baholash
  Future<SpeakingAssessmentData?> submitSpeakingResult({
    required String language,
    required String level,
    required String topic,
    required String transcribedText,
    required int audioDuration,
  }) async {
    if (!mounted) return null;
    state = state.copyWith(isLoading: true);

    final taskId = state.currentSpeakingTask?.taskId ?? '';

    final assessment = await _engine.assessSpeaking(
      taskId: taskId,
      language: language,
      level: level,
      topic: topic,
      transcribedText: transcribedText,
      audioDuration: audioDuration,
    );

    if (!mounted) return null;
    state = state.copyWith(
      isLoading: false,
      lastSpeakingAssessment: assessment,
    );
    return assessment;
  }

  /// Xatoni tozalash
  void clearError() {
    if (!mounted) return;
    state = state.copyWith(error: null);
  }
}

// ═══════════════════════════════════
// PROVIDER
// ═══════════════════════════════════

final adaptiveLearningProvider =
    StateNotifierProvider<AdaptiveLearningNotifier, AdaptiveLearningState>(
        (ref) {
  final engine = ref.watch(adaptiveEngineProvider);
  return AdaptiveLearningNotifier(engine);
});

/// Faqat profil uchun alohida provider (tez yuklash uchun)
final userAiProfileProvider = FutureProvider<UserAiProfile?>((ref) async {
  final engine = ref.watch(adaptiveEngineProvider);
  return engine.getUserProfile();
});
