// lib/features/student/quiz/presentation/providers/quiz_provider.dart
// So'zona — Quiz Riverpod Provider
// ✅ v2.0: Adaptive Quiz (60/20/20) qo'shildi
// ✅ v2.0: Activity tracking — har quiz tugaganda natija saqlanadi
// ✅ v3.0: deleteQuiz() — quiz o'chirish
// ✅ v3.0: generateAiQuizWithParams() — grammar/topic/level/count bilan AI quiz

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/api_endpoints.dart';
import 'package:my_first_app/core/providers/network_provider.dart';
import 'package:my_first_app/features/student/quiz/data/datasources/quiz_local_datasource.dart';
import 'package:my_first_app/features/student/quiz/data/datasources/quiz_remote_datasource.dart';
import 'package:my_first_app/features/student/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz_attempt.dart';

// ─── Repository provider ───
final quizRepositoryProvider = Provider<QuizRepositoryImpl>((ref) {
  return QuizRepositoryImpl(
    remote: QuizRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
      functions: FirebaseFunctions.instanceFor(region: 'us-central1'),
    ),
    local: QuizLocalDataSourceImpl(),
    net: ref.watch(networkInfoProvider),
  );
});

// ─── State ───
class QuizState {
  final bool isLoading;
  final bool isSubmitting;
  final bool isGenerating;
  final bool isDeleting;
  final String? error;
  final List<Quiz> quizzes;
  final Quiz? selectedQuiz;
  final Quiz? activeQuiz;
  final QuizAttempt? lastAttempt;
  final Map<String, String> userAnswers;
  final int currentQuestionIndex;
  final int secondsElapsed;

  /// Adaptive quiz taqsimot ma'lumotlari
  final Map<String, dynamic>? adaptiveDistribution;

  const QuizState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.isGenerating = false,
    this.isDeleting = false,
    this.error,
    this.quizzes = const [],
    this.selectedQuiz,
    this.activeQuiz,
    this.lastAttempt,
    this.userAnswers = const {},
    this.currentQuestionIndex = 0,
    this.secondsElapsed = 0,
    this.adaptiveDistribution,
  });

  bool get isLastQuestion =>
      activeQuiz != null &&
      currentQuestionIndex >= activeQuiz!.questions.length - 1;

  QuizQuestion? get currentQuestion =>
      activeQuiz != null && currentQuestionIndex < activeQuiz!.questions.length
          ? activeQuiz!.questions[currentQuestionIndex]
          : null;

  /// O'qituvchi quizlari
  List<Quiz> get teacherQuizzes =>
      quizzes.where((q) => q.creatorType == 'teacher').toList();

  /// O'z quizlari (AI + qo'lda)
  List<Quiz> get myQuizzes =>
      quizzes.where((q) => q.creatorType != 'teacher').toList();

  QuizState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isGenerating,
    bool? isDeleting,
    String? error,
    List<Quiz>? quizzes,
    Quiz? selectedQuiz,
    Quiz? activeQuiz,
    QuizAttempt? lastAttempt,
    Map<String, String>? userAnswers,
    int? currentQuestionIndex,
    int? secondsElapsed,
    Map<String, dynamic>? adaptiveDistribution,
  }) =>
      QuizState(
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isGenerating: isGenerating ?? this.isGenerating,
        isDeleting: isDeleting ?? this.isDeleting,
        error: error,
        quizzes: quizzes ?? this.quizzes,
        selectedQuiz: selectedQuiz ?? this.selectedQuiz,
        activeQuiz: activeQuiz ?? this.activeQuiz,
        lastAttempt: lastAttempt ?? this.lastAttempt,
        userAnswers: userAnswers ?? this.userAnswers,
        currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
        secondsElapsed: secondsElapsed ?? this.secondsElapsed,
        adaptiveDistribution: adaptiveDistribution ?? this.adaptiveDistribution,
      );
}

class QuizNotifier extends StateNotifier<QuizState> {
  final QuizRepositoryImpl _repo;

  QuizNotifier(this._repo) : super(const QuizState());

  Future<void> loadQuizzes({
    required String userId,
    required String language,
    required String level,
    String? classId,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    final result = await _repo.getQuizzes(
      userId: userId,
      language: language,
      level: level,
      classId: classId,
    );
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (list) => state = state.copyWith(isLoading: false, quizzes: list),
    );
  }

  Future<void> selectQuiz(String quizId) async {
    state = state.copyWith(isLoading: true);
    final result = await _repo.getQuizDetail(quizId);
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (q) => state = state.copyWith(isLoading: false, selectedQuiz: q),
    );
  }

  void startQuiz(Quiz quiz) {
    state = state.copyWith(
      activeQuiz: quiz,
      currentQuestionIndex: 0,
      userAnswers: {},
      secondsElapsed: 0,
      lastAttempt: null,
    );
  }

  void answerQuestion(String questionId, String answer) {
    final updated = Map<String, String>.from(state.userAnswers);
    updated[questionId] = answer;
    state = state.copyWith(userAnswers: updated);
  }

  void nextQuestion() {
    if (!state.isLastQuestion) {
      state =
          state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    }
  }

  void tickSecond() {
    state = state.copyWith(secondsElapsed: state.secondsElapsed + 1);
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ YANGI: Quiz o'chirish
  // ═══════════════════════════════════════════════════════════════
  Future<void> deleteQuiz(String quizId) async {
    if (!mounted) return;
    state = state.copyWith(isDeleting: true);
    final result = await _repo.deleteQuiz(quizId);
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(isDeleting: false, error: f.message),
      (_) {
        final updated = state.quizzes.where((q) => q.id != quizId).toList();
        state = state.copyWith(isDeleting: false, quizzes: updated);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ YANGI: Grammar/topic/level/count bilan AI quiz yaratish
  // ═══════════════════════════════════════════════════════════════
  Future<void> generateAiQuizWithParams({
    required String userId,
    required String language,
    required String level,
    required String topic,
    required String grammar,
    required int questionCount,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isGenerating: true);
    final result = await _repo.createStudentQuiz(
      userId: userId,
      language: language,
      level: level,
      topic: topic,
      grammar: grammar,
      questionCount: questionCount,
    );
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(isGenerating: false, error: f.message),
      (quiz) {
        // Ro'yxatga ham qo'shish
        final updated = [quiz, ...state.quizzes];
        startQuiz(quiz);
        state = state.copyWith(isGenerating: false, quizzes: updated);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // submitQuiz — activity tracking bilan
  // ═══════════════════════════════════════════════════════════════
  Future<void> submitQuiz({required String userId}) async {
    final quiz = state.activeQuiz;
    if (quiz == null || !mounted) return;
    state = state.copyWith(isSubmitting: true);

    final answers = quiz.questions.map((q) {
      final userAns = state.userAnswers[q.id] ?? '';
      final isCorrect =
          userAns.toLowerCase().trim() == q.correctAnswer.toLowerCase().trim();
      return QuizAnswer(
        questionId: q.id,
        userAnswer: userAns,
        correctAnswer: q.correctAnswer,
        isCorrect: isCorrect,
        timeSpentSeconds: state.secondsElapsed ~/ quiz.questions.length,
        points: isCorrect ? q.points : 0,
      );
    }).toList();

    final result = await _repo.submitQuiz(
      userId: userId,
      quizId: quiz.id,
      quizTitle: quiz.title,
      classId: quiz.classId,
      answers: answers,
      timeSpentSeconds: state.secondsElapsed,
      maxScore: quiz.totalPoints,
    );

    if (!mounted) return;

    result.fold(
      (f) => state = state.copyWith(isSubmitting: false, error: f.message),
      (attempt) {
        state = state.copyWith(
          isSubmitting: false,
          lastAttempt: attempt,
          activeQuiz: null,
        );
        _recordQuizActivity(
          userId: userId,
          quiz: quiz,
          attempt: attempt,
          answers: answers,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Adaptive AI Quiz
  // ═══════════════════════════════════════════════════════════════
  Future<void> generateAdaptiveQuiz({
    required String userId,
    required String language,
    required String level,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isGenerating: true);

    try {
      final callable =
          FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable(
        ApiEndpoints.adaptiveQuiz,
        options: HttpsCallableOptions(timeout: ApiEndpoints.longTimeout),
      );

      final result = await callable.call({
        'language': language,
        'level': level,
        'questionCount': 10,
      });

      final data = result.data as Map<String, dynamic>;
      final rawQs = data['questions'] as List<dynamic>? ?? [];
      final questions = rawQs.map((q) {
        final m = q as Map<String, dynamic>;
        return QuizQuestion(
          id: m['id'] as String? ?? '',
          type: QuestionType.mcq,
          question: m['question'] as String? ?? '',
          options: List<String>.from(m['options'] as List? ?? []),
          correctAnswer: m['correctAnswer'] as String? ?? '',
          explanation: m['explanation'] as String? ?? '',
          points: (m['points'] as num?)?.toInt() ?? 10,
        );
      }).toList();

      final totalPts = questions.fold(0, (acc, q) => acc + q.points);

      final quiz = Quiz(
        id: 'adaptive_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Adaptive Quiz',
        language: language,
        level: level,
        topic: 'adaptive',
        creatorId: userId,
        creatorType: 'ai',
        generatedByAi: true,
        questions: questions,
        totalPoints: totalPts,
        passingScore: (totalPts * 0.6).round(),
        createdAt: DateTime.now(),
      );

      if (!mounted) return;
      startQuiz(quiz);
      state = state.copyWith(
        isGenerating: false,
        adaptiveDistribution: data['distribution'] as Map<String, dynamic>?,
      );
    } catch (e) {
      if (!mounted) return;
      await generateAiQuiz(
        userId: userId,
        language: language,
        level: level,
      );
    }
  }

  /// Oddiy AI quiz (fallback)
  Future<void> generateAiQuiz({
    required String userId,
    required String language,
    required String level,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isGenerating: true);
    final result = await _repo.getAiRecommendedQuiz(
      userId: userId,
      language: language,
      level: level,
    );
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(isGenerating: false, error: f.message),
      (quiz) {
        startQuiz(quiz);
        state = state.copyWith(isGenerating: false);
      },
    );
  }

  // ─── Activity tracking ───
  Future<void> _recordQuizActivity({
    required String userId,
    required Quiz quiz,
    required QuizAttempt attempt,
    required List<QuizAnswer> answers,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable(
        ApiEndpoints.recordActivity,
        options: HttpsCallableOptions(timeout: ApiEndpoints.defaultTimeout),
      );

      final wrongItems = answers
          .where((a) => !a.isCorrect)
          .map((a) => a.correctAnswer)
          .toList();

      await callable.call({
        'skillType': 'quiz',
        'topic': quiz.topic,
        'difficulty': 'medium',
        'correctAnswers': answers.where((a) => a.isCorrect).length,
        'wrongAnswers': answers.where((a) => !a.isCorrect).length,
        'responseTime': attempt.timeSpentSeconds,
        'vocabularyUsed': <String>[],
        'grammarErrors': wrongItems,
        'language': quiz.language,
        'level': quiz.level,
        'scorePercent': attempt.percentage,
        'weakItems': wrongItems,
        'strongItems': <String>[],
        'contentId': quiz.id,
      });
    } catch (_) {
      // Activity saqlash sessiyani buzmaydi
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref.watch(quizRepositoryProvider));
});
