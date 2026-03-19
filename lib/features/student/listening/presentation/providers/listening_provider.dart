// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Listening Provider
// QO'YISH: lib/features/student/listening/presentation/providers/listening_provider.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/core/providers/network_provider.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/listening/data/datasources/listening_local_datasource.dart';
import 'package:my_first_app/features/student/listening/data/datasources/listening_remote_datasource.dart';
import 'package:my_first_app/features/student/listening/data/repositories/listening_repository_impl.dart';
import 'package:my_first_app/features/student/listening/domain/entities/listening_exercise.dart';
import 'package:my_first_app/features/student/listening/domain/repositories/listening_repository.dart';
import 'package:my_first_app/features/student/listening/domain/usecases/get_listening_detail.dart';
import 'package:my_first_app/features/student/listening/domain/usecases/get_listening_exercises.dart';
import 'package:my_first_app/features/student/listening/domain/usecases/submit_listening_answers.dart';

// ═══════════════════════════════════════════════════════════════
// PROVIDERS — Dependency Injection
// ═══════════════════════════════════════════════════════════════

/// Listening Remote DataSource Provider
final listeningRemoteDataSourceProvider =
    Provider<ListeningRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ListeningRemoteDataSourceImpl(firestore: firestore);
});

/// Listening Local DataSource Provider
final listeningLocalDataSourceProvider =
    Provider<ListeningLocalDataSource>((ref) {
  return ListeningLocalDataSourceImpl();
});

/// Listening Repository Provider
final listeningRepositoryProvider = Provider<ListeningRepository>((ref) {
  final remoteDataSource = ref.watch(listeningRemoteDataSourceProvider);
  final localDataSource = ref.watch(listeningLocalDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return ListeningRepositoryImpl(
    remote: remoteDataSource,
    local: localDataSource,
    networkInfo: networkInfo,
  );
});

/// Get Listening Exercises UseCase Provider
final getListeningExercisesUseCaseProvider =
    Provider<GetListeningExercises>((ref) {
  final repository = ref.watch(listeningRepositoryProvider);
  return GetListeningExercises(repository);
});

/// Get Listening Detail UseCase Provider
final getListeningDetailUseCaseProvider = Provider<GetListeningDetail>((ref) {
  final repository = ref.watch(listeningRepositoryProvider);
  return GetListeningDetail(repository);
});

/// Submit Listening Answers UseCase Provider
final submitListeningAnswersUseCaseProvider =
    Provider<SubmitListeningAnswers>((ref) {
  final repository = ref.watch(listeningRepositoryProvider);
  return SubmitListeningAnswers(repository);
});

// ═══════════════════════════════════════════════════════════════
// LISTENING LIST STATE
// ═══════════════════════════════════════════════════════════════

/// Listening List Provider
final listeningListProvider = FutureProvider.autoDispose
    .family<List<ListeningExercise>, GetListeningParams>((ref, params) async {
  final useCase = ref.watch(getListeningExercisesUseCaseProvider);
  final result = await useCase(params);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (exercises) => exercises,
  );
});

/// Listening Detail Provider
final listeningDetailProvider =
    FutureProvider.autoDispose.family<ListeningExercise, String>(
  (ref, exerciseId) async {
    final useCase = ref.watch(getListeningDetailUseCaseProvider);
    final result = await useCase(
      GetListeningDetailParams(
        exerciseId: exerciseId,
      ),
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (exercise) => exercise,
    );
  },
);

// ═══════════════════════════════════════════════════════════════
// LISTENING PLAY STATE
// ═══════════════════════════════════════════════════════════════

/// Listening Play State
class ListeningPlayState {
  final ListeningExercise exercise;
  final int currentQuestionIndex;
  final Map<String, String> userAnswers;
  final Duration? seekToPosition; // savol timestamp ga seek
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool showTranscript;
  final DateTime startTime;

  const ListeningPlayState({
    required this.exercise,
    this.currentQuestionIndex = 0,
    this.userAnswers = const {},
    this.seekToPosition,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    required this.totalDuration,
    this.showTranscript = false,
    required this.startTime,
  });

  ListeningPlayState copyWith({
    ListeningExercise? exercise,
    int? currentQuestionIndex,
    Map<String, String>? userAnswers,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    Duration? seekToPosition,
    bool clearSeek = false,
    bool? showTranscript,
    DateTime? startTime,
  }) {
    return ListeningPlayState(
      exercise: exercise ?? this.exercise,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      seekToPosition:
          clearSeek ? null : (seekToPosition ?? this.seekToPosition),
      showTranscript: showTranscript ?? this.showTranscript,
      startTime: startTime ?? this.startTime,
    );
  }
}

/// Listening Play Notifier
class ListeningPlayNotifier extends StateNotifier<ListeningPlayState?> {
  final SubmitListeningAnswers submitAnswersUseCase;
  final String studentId;

  ListeningPlayNotifier({
    required this.submitAnswersUseCase,
    required this.studentId,
  }) : super(null);

  /// Listening'ni boshlash
  void startListening(ListeningExercise exercise) {
    state = ListeningPlayState(
      exercise: exercise,
      totalDuration: Duration(seconds: exercise.duration),
      startTime: DateTime.now(),
    );
  }

  /// Audio play/pause
  void togglePlay() {
    if (state != null) {
      state = state!.copyWith(isPlaying: !state!.isPlaying);
    }
  }

  /// Audio position yangilash
  void updatePosition(Duration position) {
    if (state != null) {
      state = state!.copyWith(currentPosition: position);
    }
  }

  /// Transcript ko'rsatish/yashirish
  void toggleTranscript() {
    if (state != null) {
      state = state!.copyWith(showTranscript: !state!.showTranscript);
    }
  }

  /// Savolga javob berish
  void answerQuestion(String questionId, String answer) {
    if (state != null) {
      final newAnswers = Map<String, String>.from(state!.userAnswers);
      newAnswers[questionId] = answer;
      state = state!.copyWith(userAnswers: newAnswers);
    }
  }

  /// Keyingi savolga o'tish + audio timestamp ga seek
  void nextQuestion() {
    if (state != null &&
        state!.currentQuestionIndex < state!.exercise.questions.length - 1) {
      final nextIdx = state!.currentQuestionIndex + 1;
      final nextQ = state!.exercise.questions[nextIdx];
      // Savolda timestamp bo'lsa — audio o'sha joyga seek qiladi
      final seekPos =
          nextQ.timestamp != null ? Duration(seconds: nextQ.timestamp!) : null;
      state = state!.copyWith(
        currentQuestionIndex: nextIdx,
        currentPosition: seekPos ?? state!.currentPosition,
        seekToPosition: seekPos,
      );
    }
  }

  /// Oldingi savolga qaytish + audio timestamp ga seek
  void previousQuestion() {
    if (state != null && state!.currentQuestionIndex > 0) {
      final prevIdx = state!.currentQuestionIndex - 1;
      final prevQ = state!.exercise.questions[prevIdx];
      final seekPos =
          prevQ.timestamp != null ? Duration(seconds: prevQ.timestamp!) : null;
      state = state!.copyWith(
        currentQuestionIndex: prevIdx,
        currentPosition: seekPos ?? state!.currentPosition,
        seekToPosition: seekPos,
      );
    }
  }

  /// seekToPosition ishlatilgandan keyin tozalash
  void clearSeek() {
    if (state != null) {
      state = state!.copyWith(seekToPosition: null);
    }
  }

  /// Javoblarni yuborish
  Future<Map<String, dynamic>?> submitAnswers() async {
    if (state == null) return null;

    final timeSpent = DateTime.now().difference(state!.startTime).inSeconds;

    final result = await submitAnswersUseCase(
      SubmitListeningParams(
        exerciseId: state!.exercise.id,
        studentId: studentId,
        answers: state!.userAnswers,
        timeSpent: timeSpent,
      ),
    );

    return result.fold(
      (failure) => null,
      (result) => result,
    );
  }

  /// Reset
  void reset() {
    state = null;
  }
}

/// Listening Play Provider
final listeningPlayProvider = StateNotifierProvider.autoDispose<
    ListeningPlayNotifier, ListeningPlayState?>(
  (ref) {
    final authState = ref.watch(authNotifierProvider);
    final submitAnswers = ref.watch(submitListeningAnswersUseCaseProvider);

    return ListeningPlayNotifier(
      submitAnswersUseCase: submitAnswers,
      studentId: authState.user?.id ?? '',
    );
  },
);
