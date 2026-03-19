// lib/features/student/home/presentation/providers/student_home_provider.dart
// ✅ TUZATILDI: Streak, XP, Daraja Firestore'dan to'g'ri o'qiladi
// ✅ TUZATILDI: StreakData va DailyPlan to'g'ri modellardan to'ldiriladi
// ✅ TUZATILDI: AI Motivation integratsiya saqlanadi

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/core/services/ai_motivation_service.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';

class DailyPlan {
  final int goalMinutes;
  final int completedMinutes;
  final int flashcardsDone; // 0-100 foiz
  final int quizzesDone; // 0-100 foiz
  final int listeningDone; // 0-100 foiz
  final int speakingDone; // 0-100 foiz

  const DailyPlan({
    this.goalMinutes = 15,
    this.completedMinutes = 0,
    this.flashcardsDone = 0,
    this.quizzesDone = 0,
    this.listeningDone = 0,
    this.speakingDone = 0,
  });

  double get progressPercent {
    if (goalMinutes == 0) return 0;
    return (completedMinutes / goalMinutes).clamp(0.0, 1.0);
  }

  bool get isCompleted => completedMinutes >= goalMinutes;
  int get remainingMinutes =>
      (goalMinutes - completedMinutes).clamp(0, goalMinutes);
}

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final bool todayCompleted;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.todayCompleted = false,
  });
}

class QuickAction {
  final String title;
  final String subtitle;
  final String icon;
  final String route;

  const QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}

class StudentHomeState {
  final UserEntity? user;
  final StreakData streak;
  final DailyPlan dailyPlan;
  final int totalXp;
  final int weakItemsCount;
  final bool isLoading;
  final String? error;
  final MotivationResult? motivation;

  const StudentHomeState({
    this.user,
    this.streak = const StreakData(),
    this.dailyPlan = const DailyPlan(),
    this.totalXp = 0,
    this.weakItemsCount = 0,
    this.isLoading = false,
    this.error,
    this.motivation,
  });

  StudentHomeState copyWith({
    UserEntity? user,
    StreakData? streak,
    DailyPlan? dailyPlan,
    int? totalXp,
    int? weakItemsCount,
    bool? isLoading,
    String? error,
    MotivationResult? motivation,
    bool clearMotivation = false,
    bool clearError = false,
  }) {
    return StudentHomeState(
      user: user ?? this.user,
      streak: streak ?? this.streak,
      dailyPlan: dailyPlan ?? this.dailyPlan,
      totalXp: totalXp ?? this.totalXp,
      weakItemsCount: weakItemsCount ?? this.weakItemsCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      motivation: clearMotivation ? null : (motivation ?? this.motivation),
    );
  }
}

class StudentHomeNotifier extends StateNotifier<StudentHomeState> {
  final FirebaseFirestore _firestore;
  final AiMotivationService _motivationService;

  StudentHomeNotifier({
    required FirebaseFirestore firestore,
    required AiMotivationService motivationService,
  })  : _firestore = firestore,
        _motivationService = motivationService,
        super(const StudentHomeState());

  Future<void> loadHomeData(UserEntity? user) async {
    if (user == null) return;
    if (!mounted) return;

    state = state.copyWith(isLoading: true, user: user, clearError: true);

    try {
      // ✅ Parallel yuklash
      final results = await Future.wait([
        _loadStreakData(user.id),
        _loadDailyPlanData(user),
        _loadXp(user.id),
        _loadWeakCount(user.id),
      ]);

      if (!mounted) return;

      final streakData = results[0] as StreakData;
      final dailyPlanData = results[1] as DailyPlan;
      final xp = results[2] as int;
      final weakCount = results[3] as int;

      state = state.copyWith(
        isLoading: false,
        user: user,
        streak: streakData,
        dailyPlan: dailyPlanData,
        totalXp: xp,
        weakItemsCount: weakCount,
        clearError: true,
      );

      _triggerMotivation(user, streakData, weakCount);
    } catch (e) {
      debugPrint('⚠️ Home data xatosi: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        user: user,
        streak: const StreakData(),
        dailyPlan: DailyPlan(goalMinutes: user.dailyGoalMinutes),
        clearError: true,
      );
    }
  }

  Future<StreakData> _loadStreakData(String userId) async {
    try {
      final doc = await _firestore.collection('progress').doc(userId).get();
      if (!doc.exists) return const StreakData();

      final data = doc.data() ?? {};
      bool todayDone = false;
      final lastActiveRaw = data['lastActiveDate'];
      if (lastActiveRaw is Timestamp) {
        final lastDate = lastActiveRaw.toDate();
        final now = DateTime.now();
        todayDone = lastDate.year == now.year &&
            lastDate.month == now.month &&
            lastDate.day == now.day;
      }

      return StreakData(
        currentStreak: _toInt(data['currentStreak']),
        longestStreak: _toInt(data['longestStreak']),
        todayCompleted: todayDone,
      );
    } catch (e) {
      debugPrint('⚠️ Streak yuklanmadi: $e');
      return const StreakData();
    }
  }

  Future<DailyPlan> _loadDailyPlanData(UserEntity user) async {
    try {
      final today = DateTime.now();
      // Bugun UTC boshlangich vaqti
      final todayStart = DateTime(today.year, today.month, today.day);

      // ✅ activities collectiondan bugungi mashqlarni o'qish
      final snap = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: user.id)
          .where('timestamp', isGreaterThanOrEqualTo: todayStart)
          .get();

      final docs = snap.docs;

      // Har bir skill uchun oxirgi score (foiz)
      double flashScore = 0;
      double quizScore = 0;
      double listenScore = 0;
      double speakScore = 0;
      int flashCount = 0;
      int quizCount = 0;
      int listenCount = 0;
      int speakCount = 0;

      for (final d in docs) {
        final data = d.data();
        final skill = data['skillType'] as String? ?? '';
        final score = (data['scorePercent'] as num?)?.toDouble() ?? 0.0;

        switch (skill) {
          case 'flashcard':
            flashScore += score;
            flashCount++;
            break;
          case 'quiz':
            quizScore += score;
            quizCount++;
            break;
          case 'listening':
            listenScore += score;
            listenCount++;
            break;
          case 'speaking':
            speakScore += score;
            speakCount++;
            break;
        }
      }

      // O'rtacha foiz (0-100)
      final flashAvg = flashCount > 0 ? (flashScore / flashCount).round() : 0;
      final quizAvg = quizCount > 0 ? (quizScore / quizCount).round() : 0;
      final listenAvg =
          listenCount > 0 ? (listenScore / listenCount).round() : 0;
      final speakAvg = speakCount > 0 ? (speakScore / speakCount).round() : 0;

      // completedMinutes = jami mashq soni * 5 daqiqa (taxminiy)
      final totalSessions = flashCount + quizCount + listenCount + speakCount;
      final completedMinutes = totalSessions * 5;

      return DailyPlan(
        goalMinutes: user.dailyGoalMinutes,
        completedMinutes: completedMinutes.clamp(0, user.dailyGoalMinutes * 2),
        flashcardsDone: flashAvg,
        quizzesDone: quizAvg,
        listeningDone: listenAvg,
        speakingDone: speakAvg,
      );
    } catch (e) {
      debugPrint('⚠️ Daily stats yuklanmadi: $e');
      return DailyPlan(goalMinutes: user.dailyGoalMinutes);
    }
  }

  Future<int> _loadXp(String userId) async {
    try {
      // 1. users collectiondan qidirish (quiz va boshqa mashqlar shu yerga yozadi)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userXp = _toInt(userDoc.data()?['totalXp']);
      if (userXp > 0) return userXp;

      // 2. progress collectiondan fallback
      final progressDoc =
          await _firestore.collection('progress').doc(userId).get();
      return _toInt(progressDoc.data()?['totalXp']);
    } catch (e) {
      debugPrint('⚠️ XP yuklanmadi: $e');
      return 0;
    }
  }

  Future<int> _loadWeakCount(String userId) async {
    try {
      final snap = await _firestore
          .collection('progress')
          .doc(userId)
          .collection('weakItems')
          .where('status', isEqualTo: 'active')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('⚠️ Weak count yuklanmadi: $e');
      return 0;
    }
  }

  Future<void> _triggerMotivation(
    UserEntity user,
    StreakData streak,
    int weakCount,
  ) async {
    if (!mounted) return;
    _motivationService.markActive();

    try {
      MotivationResult? result;

      result = await _motivationService.onUserReturned(
        studentName: user.displayName,
        language: user.learningLanguage.name,
      );

      if (result == null &&
          !streak.todayCompleted &&
          DateTime.now().hour >= 17) {
        result = await _motivationService.onStreakRisk(
          studentName: user.displayName,
          currentStreak: streak.currentStreak,
          language: user.learningLanguage.name,
        );
      }

      if (result == null && weakCount >= 5) {
        result = await _motivationService.onWeakAreaDetected(
          studentName: user.displayName,
          weakAreas: [],
          language: user.learningLanguage.name,
        );
      }

      if (result != null && mounted) {
        state = state.copyWith(motivation: result);
      }
    } catch (e) {
      debugPrint('⚠️ Motivation trigger xatosi: $e');
    }
  }

  Future<void> onLessonCompleted({
    required int score,
    required String contentType,
  }) async {
    final user = state.user;
    if (user == null || !mounted) return;

    try {
      final result = await _motivationService.onLessonCompleted(
        studentName: user.displayName,
        score: score,
        streak: state.streak.currentStreak,
        language: user.learningLanguage.name,
      );
      if (result != null && mounted) {
        state = state.copyWith(motivation: result);
      }
    } catch (e) {
      debugPrint('⚠️ Lesson motivation xatosi: $e');
    }
  }

  /// ✅ Streak va XP ni mashqdan keyin yangilash
  Future<void> refreshAfterLesson() async {
    final user = state.user;
    if (user == null) return;
    final newStreak = await _loadStreakData(user.id);
    final newXp = await _loadXp(user.id);
    final newPlan = await _loadDailyPlanData(user);
    if (mounted) {
      state =
          state.copyWith(streak: newStreak, totalXp: newXp, dailyPlan: newPlan);
    }
  }

  void dismissMotivation() {
    if (mounted) state = state.copyWith(clearMotivation: true);
  }

  Future<void> refresh() async {
    await loadHomeData(state.user);
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

final studentHomeProvider =
    StateNotifierProvider<StudentHomeNotifier, StudentHomeState>((ref) {
  return StudentHomeNotifier(
    firestore: ref.watch(firestoreProvider),
    motivationService: ref.watch(aiMotivationServiceProvider),
  );
});

final quickActionsProvider = Provider<List<QuickAction>>((ref) {
  final user = ref.watch(authNotifierProvider).user;
  final isGerman = user?.isLearningGerman ?? false;

  return [
    const QuickAction(
        title: 'Flashcard',
        subtitle: 'So\'z o\'rganish',
        icon: '📝',
        route: '/student/flashcards'),
    const QuickAction(
        title: 'Quiz',
        subtitle: 'Bilimni tekshirish',
        icon: '🧠',
        route: '/student/quiz'),
    const QuickAction(
        title: 'Listening',
        subtitle: 'Tinglash mashqi',
        icon: '🎧',
        route: '/student/listening'),
    const QuickAction(
        title: 'Speaking',
        subtitle: 'AI bilan gaplashish',
        icon: '🗣️',
        route: '/student/speaking'),
    const QuickAction(
        title: 'AI Chat',
        subtitle: 'Savol berish',
        icon: '🤖',
        route: '/student/ai-chat'),
    const QuickAction(
        title: 'Sinfim',
        subtitle: 'Sinfga qo\'shilish',
        icon: '🏫',
        route: '/student/classes'),
    if (isGerman)
      const QuickAction(
          title: 'Artikel',
          subtitle: 'der/die/das',
          icon: '🇩🇪',
          route: '/student/artikel'),
  ];
});
