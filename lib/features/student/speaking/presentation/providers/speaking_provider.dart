// lib/features/student/speaking/presentation/providers/speaking_provider.dart
// So'zona — Speaking Provider
// ✅ AI FALLBACK: exception o'rniga bo'sh list qaytariladi — app crash bo'lmaydi
// ✅ YANGI: assessVoiceResponse() — ovoz yozish + AI baholash

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/speaking/data/datasources/speaking_remote_datasource.dart';
import 'package:my_first_app/features/student/speaking/data/repositories/speaking_repository_impl.dart';
import 'package:my_first_app/features/student/speaking/domain/entities/speaking_exercise.dart';
import 'package:my_first_app/features/student/speaking/domain/repositories/speaking_repository.dart';
import 'package:my_first_app/features/student/speaking/domain/usecases/get_speaking_exercises.dart';

// DataSource
final speakingRemoteDataSourceProvider =
    Provider<SpeakingRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  return SpeakingRemoteDataSourceImpl(
    functions: functions,
    firestore: firestore,
  );
});

// Repository
final speakingRepositoryImplProvider = Provider<SpeakingRepositoryImpl>((ref) {
  final remoteDataSource = ref.watch(speakingRemoteDataSourceProvider);
  return SpeakingRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Abstract repository provider
final speakingRepositoryProvider = Provider<SpeakingRepository>((ref) {
  return ref.watch(speakingRepositoryImplProvider);
});

// UseCase
final getSpeakingExercisesUseCaseProvider =
    Provider<GetSpeakingExercises>((ref) {
  final repository = ref.watch(speakingRepositoryProvider);
  return GetSpeakingExercises(repository);
});

// Exercise List
// ✅ FIX: throw Exception o'rniga bo'sh list — UI crash bo'lmaydi
final speakingListProvider = FutureProvider.autoDispose
    .family<List<SpeakingExercise>, GetSpeakingParams>((ref, params) async {
  final useCase = ref.watch(getSpeakingExercisesUseCaseProvider);
  final result = await useCase(params);

  return result.fold(
    (failure) {
      // ✅ AI ishlamasa — bo'sh list, UI "mashqlar topilmadi" ko'rsatadi
      return <SpeakingExercise>[];
    },
    (exercises) => exercises,
  );
});

// Speaking Session State
class SpeakingSessionState {
  final SpeakingExercise exercise;
  final int currentTurnIndex;
  final List<String> userMessages;
  final Map<String, dynamic>? feedback;

  const SpeakingSessionState({
    required this.exercise,
    this.currentTurnIndex = 0,
    this.userMessages = const [],
    this.feedback,
  });

  SpeakingSessionState copyWith({
    SpeakingExercise? exercise,
    int? currentTurnIndex,
    List<String>? userMessages,
    Map<String, dynamic>? feedback,
  }) {
    return SpeakingSessionState(
      exercise: exercise ?? this.exercise,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      userMessages: userMessages ?? this.userMessages,
      feedback: feedback ?? this.feedback,
    );
  }
}

// Speaking Session Notifier
class SpeakingSessionNotifier extends StateNotifier<SpeakingSessionState?> {
  final SpeakingRepositoryImpl _repositoryImpl;
  final String _userId;

  SpeakingSessionNotifier(this._repositoryImpl, this._userId) : super(null);

  void startSession(SpeakingExercise exercise) {
    // ✅ FIX: userId ni repository ga uzatamiz — member progress yangilansin
    _repositoryImpl.setActiveExercise(exercise, userId: _userId);
    state = SpeakingSessionState(exercise: exercise);
  }

  void submitMessage(String message) {
    if (state == null) return;
    final newMessages = [...state!.userMessages, message];
    state = state!.copyWith(
      userMessages: newMessages,
      currentTurnIndex: state!.currentTurnIndex + 1,
    );
  }

  void nextTurn() {
    if (state == null) return;
    state = state!.copyWith(
      currentTurnIndex: state!.currentTurnIndex + 1,
    );
  }

  Future<void> finishSession() async {
    if (state == null) return;
    final result = await _repositoryImpl.getFeedback(
      exerciseId: state!.exercise.id,
      userMessages: state!.userMessages,
    );
    result.fold(
      (failure) => null,
      (feedback) {
        state = state!.copyWith(feedback: feedback);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ YANGI: Ovoz yozish + AI baholash
  // Speech-to-Text orqali olingan matn AI ga yuboriladi
  // Natija: pronunciation, grammar, fluency, vocabulary + IELTS ball
  // ═══════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> assessVoiceResponse({
    required String transcribedText,
    required int audioDuration,
  }) async {
    if (state == null) return null;

    final exercise = state!.exercise;

    // Ko'proq kontekst uchun barcha user xabarlarini qo'shamiz
    final allMessages = [...state!.userMessages, transcribedText];
    final combinedText = allMessages.join(' ');

    try {
      final result = await _repositoryImpl.assessVoice(
        exerciseId: exercise.id,
        transcribedText: combinedText,
        audioDuration: audioDuration,
        language: exercise.language,
        level: exercise.level,
        topic: exercise.topic,
      );

      return result.fold(
        (failure) => null,
        (assessment) {
          // State'ga ham yozib qo'yamiz
          state = state!.copyWith(feedback: assessment);
          return assessment;
        },
      );
    } catch (e) {
      return null;
    }
  }

  void reset() {
    state = null;
  }
}

final speakingSessionProvider =
    StateNotifierProvider<SpeakingSessionNotifier, SpeakingSessionState?>(
  (ref) {
    final repositoryImpl = ref.watch(speakingRepositoryImplProvider);
    // ✅ FIX: userId ni provider ga uzatamiz
    final userId = ref.watch(authNotifierProvider).user?.id ?? '';
    return SpeakingSessionNotifier(repositoryImpl, userId);
  },
);
