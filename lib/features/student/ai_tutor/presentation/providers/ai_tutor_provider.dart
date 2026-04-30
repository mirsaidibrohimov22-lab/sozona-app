// lib/features/student/ai_tutor/presentation/providers/ai_tutor_provider.dart
// So'zona — AI Murabbiy Provider
// Backend getRecommendations, haftalik analytics va mistakes dan ma'lumot oladi

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // debugPrint
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/api_endpoints.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';

// ─── Model ───────────────────────────────────────────────────

class TutorRecommendation {
  final String contentId;
  final String title;
  final String type;
  final String topic;
  final String level;
  final String reason;
  final String reasonUz;
  final int priority;

  const TutorRecommendation({
    required this.contentId,
    required this.title,
    required this.type,
    required this.topic,
    required this.level,
    required this.reason,
    required this.reasonUz,
    required this.priority,
  });

  factory TutorRecommendation.fromMap(Map<String, dynamic> m) =>
      TutorRecommendation(
        contentId: m['contentId'] as String? ?? '',
        title: m['title'] as String? ?? 'Dars',
        type: m['type'] as String? ?? 'quiz',
        topic: m['topic'] as String? ?? '',
        level: m['level'] as String? ?? '',
        reason: m['reason'] as String? ?? 'sequential',
        reasonUz: m['reasonUz'] as String? ?? 'Keyingi dars',
        priority: (m['priority'] as num?)?.toInt() ?? 50,
      );
}

class WeeklyStats {
  final int lessonsCompleted;
  final int totalMinutes;
  final int avgScore;
  final String weekId;
  final Map<String, Map<String, int>> skillBreakdown;
  final List<String> topMistakeTags;

  const WeeklyStats({
    required this.lessonsCompleted,
    required this.totalMinutes,
    required this.avgScore,
    required this.weekId,
    required this.skillBreakdown,
    required this.topMistakeTags,
  });

  factory WeeklyStats.empty() => const WeeklyStats(
        lessonsCompleted: 0,
        totalMinutes: 0,
        avgScore: 0,
        weekId: '',
        skillBreakdown: {},
        topMistakeTags: [],
      );

  factory WeeklyStats.fromMap(Map<String, dynamic> m) {
    final raw = m['skillBreakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = raw.map((k, v) {
      final sm = v as Map<String, dynamic>;
      return MapEntry(k, {
        'attempts': (sm['attempts'] as num?)?.toInt() ?? 0,
        'avgScore': (sm['avgScore'] as num?)?.toInt() ?? 0,
      });
    });
    return WeeklyStats(
      lessonsCompleted: (m['lessonsCompleted'] as num?)?.toInt() ?? 0,
      totalMinutes: (m['totalMinutes'] as num?)?.toInt() ?? 0,
      avgScore: (m['avgScore'] as num?)?.toInt() ?? 0,
      weekId: m['weekId'] as String? ?? '',
      skillBreakdown: breakdown,
      topMistakeTags: List<String>.from(m['topMistakeTags'] as List? ?? []),
    );
  }
}

// ─── State ───────────────────────────────────────────────────

class AiTutorState {
  final bool isLoading;
  final bool isLoadingStats;
  final String? error;
  final List<TutorRecommendation> recommendations;
  final WeeklyStats weeklyStats;
  final int mistakeCount;

  const AiTutorState({
    this.isLoading = false,
    this.isLoadingStats = false,
    this.error,
    this.recommendations = const [],
    this.weeklyStats = const WeeklyStats(
      lessonsCompleted: 0,
      totalMinutes: 0,
      avgScore: 0,
      weekId: '',
      skillBreakdown: {},
      topMistakeTags: [],
    ),
    this.mistakeCount = 0,
  });

  AiTutorState copyWith({
    bool? isLoading,
    bool? isLoadingStats,
    String? error,
    List<TutorRecommendation>? recommendations,
    WeeklyStats? weeklyStats,
    int? mistakeCount,
  }) =>
      AiTutorState(
        isLoading: isLoading ?? this.isLoading,
        isLoadingStats: isLoadingStats ?? this.isLoadingStats,
        error: error,
        recommendations: recommendations ?? this.recommendations,
        weeklyStats: weeklyStats ?? this.weeklyStats,
        mistakeCount: mistakeCount ?? this.mistakeCount,
      );
}

// ─── Notifier ────────────────────────────────────────────────

class AiTutorNotifier extends StateNotifier<AiTutorState> {
  final FirebaseFunctions _fn;
  final FirebaseFirestore _db;
  final String _userId;
  final String _language;

  AiTutorNotifier({
    required String userId,
    required String language,
  })  : _fn = FirebaseFunctions.instanceFor(region: 'us-central1'),
        _db = FirebaseFirestore.instance,
        _userId = userId,
        _language = language,
        super(const AiTutorState()) {
    if (userId.isNotEmpty) loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadRecommendations(),
      loadWeeklyStats(),
      loadMistakeCount(),
    ]);
  }

  // ── Tavsiyalar ────────────────────────────────────────────
  Future<void> loadRecommendations() async {
    if (_userId.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _fn
          .httpsCallable(ApiEndpoints.getRecommendations)
          .call({'language': _language, 'limit': 5});

      final data = result.data as Map<String, dynamic>;
      final recs = (data['recommendations'] as List? ?? [])
          .map((e) =>
              TutorRecommendation.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      state = state.copyWith(isLoading: false, recommendations: recs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Haftalik statistika — activities collectiondan real-time ─
  Future<void> loadWeeklyStats() async {
    if (_userId.isEmpty) return;
    state = state.copyWith(isLoadingStats: true);
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final snap = await _db
          .collection('activities')
          .where('userId', isEqualTo: _userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(weekAgo))
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      if (snap.docs.isEmpty) {
        state = state.copyWith(
            isLoadingStats: false, weeklyStats: WeeklyStats.empty());
        return;
      }

      // Skill breakdown hisoblash
      final skillMap = <String, List<int>>{};
      int totalScore = 0;

      for (final doc in snap.docs) {
        final d = doc.data();
        final skill = d['skillType'] as String? ?? 'quiz';
        final score = (d['scorePercent'] as num?)?.toInt() ?? 0;

        skillMap.putIfAbsent(skill, () => []).add(score);
        totalScore += score;
      }

      final skillBreakdown = skillMap.map((skill, scores) {
        final avg = scores.isEmpty
            ? 0
            : scores.reduce((a, b) => a + b) ~/ scores.length;
        return MapEntry(skill, {
          'attempts': scores.length,
          'avgScore': avg,
        });
      });

      final stats = WeeklyStats(
        lessonsCompleted: snap.docs.length,
        totalMinutes: snap.docs.length * 5, // o'rtacha 5 daqiqa/mashq
        avgScore: snap.docs.isNotEmpty ? totalScore ~/ snap.docs.length : 0,
        weekId: _currentWeekId(),
        skillBreakdown: skillBreakdown,
        topMistakeTags: [],
      );

      state = state.copyWith(isLoadingStats: false, weeklyStats: stats);
    } catch (e) {
      debugPrint('⚠️ loadWeeklyStats: $e');
      state = state.copyWith(isLoadingStats: false);
    }
  }

  String _currentWeekId() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return '${monday.year}-W${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  // ── Xato soni ────────────────────────────────────────────
  Future<void> loadMistakeCount() async {
    if (_userId.isEmpty) return;
    try {
      final snap = await _db
          .collection('mistakes')
          .where('userId', isEqualTo: _userId)
          .where('reviewed', isEqualTo: false)
          .count()
          .get();

      state = state.copyWith(mistakeCount: snap.count ?? 0);
    } catch (_) {}
  }

  // ── Xato yozish (quiz/listening/speaking dan chaqiriladi) ─
  Future<void> recordMistake({
    required String contentId,
    required String contentType,
    required String userAnswer,
    required String correctAnswer,
    required double scorePercent,
  }) async {
    if (_userId.isEmpty || contentId.isEmpty) return;
    try {
      await _fn.httpsCallable(ApiEndpoints.recordMistake).call({
        'contentId': contentId,
        'contentType': contentType,
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
        'scorePercent': scorePercent,
        'language': _language,
      });
      // Xato soni yangilansin
      await loadMistakeCount();
    } catch (e) {
      // Xato yozish muvaffaqiyatsiz bo'lsa — asosiy oqim to'xtamasin
      debugPrint('⚠️ recordMistake: $e');
    }
  }

  // ── Takrorlashni tugatish ─────────────────────────────────
  Future<void> completeReview({
    required String contentId,
    required double scorePercent,
  }) async {
    if (_userId.isEmpty) return;
    try {
      await _fn.httpsCallable(ApiEndpoints.completeReview).call({
        'contentId': contentId,
        'scorePercent': scorePercent,
        'language': _language,
      });
      await loadRecommendations();
    } catch (e) {
      debugPrint('⚠️ completeReview: $e');
    }
  }
}

// ─── Provider ────────────────────────────────────────────────

final aiTutorProvider =
    StateNotifierProvider<AiTutorNotifier, AiTutorState>((ref) {
  final user = ref.watch(authNotifierProvider).user;
  final userId = user?.id ?? '';
  final language = user?.learningLanguage.name == 'german' ? 'de' : 'en';
  return AiTutorNotifier(userId: userId, language: language);
});
