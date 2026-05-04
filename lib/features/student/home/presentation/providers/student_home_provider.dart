// lib/features/student/home/presentation/providers/student_home_provider.dart
// ✅ FIX v2.0: Streak, XP, Daraja Firestore'dan to'g'ri o'qiladi
// ✅ FIX v3.0: activities timestamp filtri DateTime → Timestamp (statistika tuzatildi)

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
  final int flashcardsDone;
  final int quizzesDone;
  final int listeningDone;
  final int speakingDone;

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

    // ✅ FIX: Agar ma'lumot allaqachon bor bo'lsa — loading ko'rsatmaymiz
    // Faqat birinchi marta yuklanayotganda isLoading = true
    final isFirstLoad = state.user == null;
    if (isFirstLoad) {
      state = state.copyWith(isLoading: true, user: user, clearError: true);
    } else {
      state = state.copyWith(user: user, clearError: true);
    }

    try {
      // ✅ FIX: streak, dailyPlan, xp parallel — motivation FONDA (kutmaymiz)
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

      // ✅ FIX: motivation FONDA — UI ni kuttirib qo'ymaydi
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
      final todayDate = DateTime(today.year, today.month, today.day);

      // ✅ FIX: Composite index talab qilmaydigan query
      // Avval faqat userId bo'yicha so'rov — index kerak emas
      // Keyin Dart da bugun sanasi bo'yicha filtrlaymiz
      // userId bo'yicha so'rov — composite index kerak emas (orderBy yo'q)
      final snap = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: user.id)
          .limit(100)
          .get();

      // Bugungi faoliyatlarni Dart da filtrlaymiz
      // timestamp yoki createdAt fieldlarini tekshiramiz (ikkalasini ham qo'llab-quvvatlash)
      final docs = snap.docs.where((doc) {
        final d = doc.data();
        DateTime? docDate;

        final ts = d['timestamp'];
        if (ts is Timestamp) {
          docDate = ts.toDate();
        } else {
          final ca = d['createdAt'];
          if (ca is Timestamp) docDate = ca.toDate();
        }

        if (docDate == null) return false;
        return docDate.year == todayDate.year &&
            docDate.month == todayDate.month &&
            docDate.day == todayDate.day;
      }).toList();

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

      final flashAvg = flashCount > 0 ? (flashScore / flashCount).round() : 0;
      final quizAvg = quizCount > 0 ? (quizScore / quizCount).round() : 0;
      final listenAvg =
          listenCount > 0 ? (listenScore / listenCount).round() : 0;
      final speakAvg = speakCount > 0 ? (speakScore / speakCount).round() : 0;

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
      // ✅ FIX: Avval cache dan — tez, keyin serverdan yangilanadi
      // Source.server o'rniga default (cache+server) — UI bloklanmaydi
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userXp = _toInt(userDoc.data()?['totalXp']);
      if (userXp > 0) return userXp;

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

// ✅ FIX: Premium foydalanuvchilarda "AI Chat" o'rniga "AI Murabbiy" ko'rinadi.
// hasPremiumProvider emas user.hasActivePremium ishlatiladi — extra provider dependency yo'q.
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
    // ✅ Premium → AI Murabbiy | Tekin → AI Chat
    // ✅ FIX: AI Murabbiy endi barcha uchun — /student/ai-tutor
    const QuickAction(
        title: 'AI Murabbiy',
        subtitle: 'Tavsiyalar va statistika',
        icon: '🎓',
        route: '/student/ai-tutor'),
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
