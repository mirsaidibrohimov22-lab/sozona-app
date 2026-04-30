// lib/features/premium/presentation/providers/premium_provider.dart
// So'zona — Premium Provider
// ✅ YANGI fayl — mavjud provider larga tegmaydi

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════
// PREMIUM COACH STATE
// ═══════════════════════════════════════════════════════════════

class PremiumExercise {
  final String type;
  final String topic;
  final String title;
  final String description;
  final int duration;
  final String difficulty;
  final String source;
  final Map<String, dynamic> content;

  const PremiumExercise({
    required this.type,
    required this.topic,
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.source,
    required this.content,
  });

  factory PremiumExercise.fromMap(Map<String, dynamic> map) {
    return PremiumExercise(
      type: map['type'] as String? ?? 'quiz',
      topic: map['topic'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      duration: map['duration'] is int
          ? map['duration'] as int
          : int.tryParse(map['duration']?.toString() ?? '') ?? 10,
      difficulty: map['difficulty'] as String? ?? 'easy',
      source: map['source'] as String? ?? '',
      content: Map<String, dynamic>.from(map['content'] as Map? ?? {}),
    );
  }

  String get durationText => '$duration daqiqa';
}

class PremiumCoachResult {
  final String personalAnalysis;
  final List<String> weakPoints;
  final String scientificMethod;
  final List<PremiumExercise> exercises;
  final String motivation;
  final String weeklyPlan;

  const PremiumCoachResult({
    required this.personalAnalysis,
    required this.weakPoints,
    required this.scientificMethod,
    required this.exercises,
    required this.motivation,
    required this.weeklyPlan,
  });

  factory PremiumCoachResult.fromMap(Map<String, dynamic> map) {
    final exercisesList = (map['exercises'] as List<dynamic>? ?? [])
        .map(
            (e) => PremiumExercise.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return PremiumCoachResult(
      personalAnalysis: map['personalAnalysis'] as String? ?? '',
      weakPoints: List<String>.from(map['weakPoints'] as List? ?? []),
      scientificMethod: map['scientificMethod'] as String? ?? '',
      exercises: exercisesList,
      motivation: map['motivation'] as String? ?? '',
      weeklyPlan: map['weeklyPlan'] as String? ?? '',
    );
  }
}

class PremiumCoachState {
  final PremiumCoachResult? result;
  final bool isLoading;
  final String? error;

  const PremiumCoachState({
    this.result,
    this.isLoading = false,
    this.error,
  });

  PremiumCoachState copyWith({
    PremiumCoachResult? result,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PremiumCoachState(
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PREMIUM COACH NOTIFIER
// ═══════════════════════════════════════════════════════════════

class PremiumCoachNotifier extends StateNotifier<PremiumCoachState> {
  final FirebaseFunctions _functions;

  PremiumCoachNotifier(this._functions) : super(const PremiumCoachState());

  Future<void> getAdvice({
    required String studentName,
    required String language,
    required String level,
    required String trigger,
    String? skillType,
    double? lastScore,
    int? dailyGoalMinutes,
    Map<String, dynamic>? sessionData, // ✅ YANGI: hozirgi sessiya ma'lumotlari
  }) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final callable = _functions.httpsCallable(
        'premiumCoach',
        // ✅ FIX: 30s → 90s. Backend 120s ishlaydi (OpenAI+Gemini parallel),
        // 30s timeout esa "Xatolik yuz berdi" xatosiga olib kelardi.
        options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
      );

      final result = await callable.call({
        'studentName': studentName,
        'language': language,
        'level': level,
        'trigger': trigger,
        if (skillType != null) 'skillType': skillType,
        if (lastScore != null) 'lastScore': lastScore,
        if (dailyGoalMinutes != null) 'dailyGoalMinutes': dailyGoalMinutes,
        if (sessionData != null) 'sessionData': sessionData, // ✅ YANGI
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final coachResult = PremiumCoachResult.fromMap(data);

      if (!mounted) return;
      state = state.copyWith(isLoading: false, result: coachResult);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('⚠️ Premium coach xatosi: ${e.code} — ${e.message}');
      if (!mounted) return;
      // permission-denied: premium yo'q yoki tugagan
      final msg = e.code == 'permission-denied'
          ? 'Bu funksiya faqat premium foydalanuvchilar uchun.'
          : 'AI murabbiy hozir band. Qayta urinib ko\'ring.';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      debugPrint('⚠️ Premium coach xatosi: $e');
      if (!mounted) return;
      // ✅ FIX: TimeoutException — Flutter 30s timeout edi, endi 90s.
      // Agar hali ham timeout bo'lsa, aniq xabar ko'rsatamiz.
      final errStr = e.toString().toLowerCase();
      final msg = errStr.contains('timeout')
          ? 'Ulanish vaqti tugadi. Internet tekshirib, qayta urining.'
          : 'Xatolik yuz berdi. Qayta urining.';
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  void clear() {
    state = const PremiumCoachState();
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════

final _functionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: 'us-central1');
});

final premiumCoachProvider =
    StateNotifierProvider.autoDispose<PremiumCoachNotifier, PremiumCoachState>(
  (ref) => PremiumCoachNotifier(ref.watch(_functionsProvider)),
);

/// Foydalanuvchi premium borligini tekshiruvchi provider
final hasPremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(authNotifierProvider).user;
  return user?.hasActivePremium ?? false;
});

/// Foydalanuvchi O'zbekistondan ekanligini tekshiruvchi provider
final isUzbekUserProvider = Provider<bool>((ref) {
  final user = ref.watch(authNotifierProvider).user;
  return user?.isUzbekUser ?? false;
});
