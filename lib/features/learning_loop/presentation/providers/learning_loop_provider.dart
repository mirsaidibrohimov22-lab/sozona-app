// QO'YISH: lib/features/learning_loop/presentation/providers/learning_loop_provider.dart
// So'zona — Learning Loop Riverpod providerlar

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/providers/network_provider.dart';
import 'package:my_first_app/features/learning_loop/data/datasources/learning_loop_local_datasource.dart';
import 'package:my_first_app/features/learning_loop/data/datasources/learning_loop_remote_datasource.dart';
import 'package:my_first_app/features/learning_loop/data/repositories/learning_loop_repository_impl.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/learner_profile.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/micro_session.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/weak_item_pool.dart';
import 'package:my_first_app/features/learning_loop/domain/usecases/analyze_attempt.dart';
import 'package:my_first_app/features/learning_loop/domain/usecases/get_motivation_message.dart';
import 'package:my_first_app/features/learning_loop/domain/usecases/get_next_session.dart';
import 'package:my_first_app/features/learning_loop/domain/usecases/suggest_level_change.dart';
import 'package:my_first_app/features/learning_loop/domain/usecases/update_weak_items.dart';

// ─── Datasource & Repository providerlar ───

final learningLoopLocalDataSourceProvider =
    Provider<LearningLoopLocalDataSource>((ref) {
  final ds = LearningLoopLocalDataSourceImpl();
  ds.init();
  return ds;
});

final learningLoopRemoteDataSourceProvider =
    Provider<LearningLoopRemoteDataSource>((ref) {
  return LearningLoopRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: 'us-central1'),
  );
});

final learningLoopRepositoryProvider =
    Provider<LearningLoopRepositoryImpl>((ref) {
  return LearningLoopRepositoryImpl(
    remote: ref.watch(learningLoopRemoteDataSourceProvider),
    local: ref.watch(learningLoopLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// ─── UseCase providerlar ───

final analyzeAttemptProvider = Provider<AnalyzeAttempt>((ref) {
  return AnalyzeAttempt(ref.watch(learningLoopRepositoryProvider));
});

final getNextSessionProvider = Provider<GetNextSession>((ref) {
  return GetNextSession(ref.watch(learningLoopRepositoryProvider));
});

final updateWeakItemsProvider = Provider<UpdateWeakItems>((ref) {
  return UpdateWeakItems(ref.watch(learningLoopRepositoryProvider));
});

final getMotivationMessageProvider = Provider<GetMotivationMessage>((ref) {
  return GetMotivationMessage(ref.watch(learningLoopRepositoryProvider));
});

final suggestLevelChangeProvider = Provider<SuggestLevelChange>((ref) {
  return SuggestLevelChange(ref.watch(learningLoopRepositoryProvider));
});

// ─── UI State ───

class LearningLoopState {
  final bool isLoading;
  final String? error;
  final List<WeakItem> weakItems;
  final List<WeakItem> dueItems;
  final LearnerProfile? learnerProfile;
  final MicroSession? currentSession;
  final String? motivationMessage;

  const LearningLoopState({
    this.isLoading = false,
    this.error,
    this.weakItems = const [],
    this.dueItems = const [],
    this.learnerProfile,
    this.currentSession,
    this.motivationMessage,
  });

  LearningLoopState copyWith({
    bool? isLoading,
    String? error,
    List<WeakItem>? weakItems,
    List<WeakItem>? dueItems,
    LearnerProfile? learnerProfile,
    MicroSession? currentSession,
    String? motivationMessage,
  }) {
    return LearningLoopState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      weakItems: weakItems ?? this.weakItems,
      dueItems: dueItems ?? this.dueItems,
      learnerProfile: learnerProfile ?? this.learnerProfile,
      currentSession: currentSession ?? this.currentSession,
      motivationMessage: motivationMessage ?? this.motivationMessage,
    );
  }
}

class LearningLoopNotifier extends StateNotifier<LearningLoopState> {
  final LearningLoopRepositoryImpl _repo;
  final GetMotivationMessage _getMotivation;

  LearningLoopNotifier({
    required LearningLoopRepositoryImpl repo,
    required GetMotivationMessage getMotivation,
  })  : _repo = repo,
        _getMotivation = getMotivation,
        super(const LearningLoopState());

  /// Barcha ma'lumotlarni yuklash
  Future<void> loadAll(String userId, String language) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    // Zaif elementlar
    final weakResult = await _repo.getWeakItems(userId);
    final dueResult = await _repo.getDueWeakItems(userId);
    final profileResult = await _repo.getLearnerProfile(userId);
    final sessionResult = await _repo.getOrCreateNextSession(userId);

    if (!mounted) return;

    weakResult.fold((_) {}, (items) {
      state = state.copyWith(weakItems: items);
    });

    dueResult.fold((_) {}, (due) {
      state = state.copyWith(dueItems: due);
    });

    profileResult.fold((_) {}, (profile) {
      state = state.copyWith(learnerProfile: profile);
    });

    sessionResult.fold((_) {}, (session) {
      state = state.copyWith(currentSession: session);
    });

    // Motivatsiya xabari
    final profile = state.learnerProfile;
    if (profile != null) {
      final msgResult = await _getMotivation(
        GetMotivationMessageParams(
          userId: userId,
          currentStreak: 0,
          averageScore: profile.averageSessionScore,
          language: language,
        ),
      );
      if (!mounted) return;
      msgResult.fold((_) {}, (msg) {
        state = state.copyWith(motivationMessage: msg);
      });
    }

    if (!mounted) return;
    state = state.copyWith(isLoading: false);
  }

  /// Sessiyani boshlash
  Future<void> startCurrentSession(String userId) async {
    final session = state.currentSession;
    if (session == null) return;

    final result = await _repo.startSessionWithUser(session.id, userId);
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (s) => state = state.copyWith(currentSession: s),
    );
  }

  /// Sessiyani tugatish
  Future<void> completeCurrentSession({
    required String userId,
    required int overallScore,
    required int weakItemsReviewed,
    required int newWeakItems,
    required int xpEarned,
  }) async {
    final session = state.currentSession;
    if (session == null) return;

    final result = await _repo.completeSessionWithUser(
      sessionId: session.id,
      userId: userId,
      overallScore: overallScore,
      weakItemsReviewed: weakItemsReviewed,
      newWeakItems: newWeakItems,
      xpEarned: xpEarned,
    );

    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (s) => state = state.copyWith(currentSession: s),
    );
  }

  void clearError() => state = state.copyWith(error: null);
}

final learningLoopProvider =
    StateNotifierProvider<LearningLoopNotifier, LearningLoopState>((ref) {
  return LearningLoopNotifier(
    repo: ref.watch(learningLoopRepositoryProvider),
    getMotivation: ref.watch(getMotivationMessageProvider),
  );
});
