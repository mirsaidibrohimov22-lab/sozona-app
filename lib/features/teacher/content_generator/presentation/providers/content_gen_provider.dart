import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/core/providers/network_provider.dart';
import 'package:my_first_app/features/teacher/content_generator/data/datasources/content_gen_remote_datasource.dart';
import 'package:my_first_app/features/teacher/content_generator/data/repositories/content_gen_repository_impl.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/repositories/content_generator_repository.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/usecases/generate_speaking.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/usecases/generate_listening.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/usecases/generate_quiz.dart';

// QO'YISH: lib/features/teacher/content_generator/presentation/providers/content_generator_provider.dart
// Content Generator Provider — State management

/// Content Generator State
///
/// Bolaga: Bu — AI kontent yaratayotgan paytdagi holat.
/// Yaratilmoqda, tayyor, yoki xatolik — hammasini shu yerda saqlaymiz.
class ContentGeneratorState {
  final bool isGenerating;
  final GeneratedContent? generatedContent;
  final String? errorMessage;

  const ContentGeneratorState({
    this.isGenerating = false,
    this.generatedContent,
    this.errorMessage,
  });

  /// Initial state
  const ContentGeneratorState.initial()
      : isGenerating = false,
        generatedContent = null,
        errorMessage = null;

  /// Generating state
  const ContentGeneratorState.generating()
      : isGenerating = true,
        generatedContent = null,
        errorMessage = null;

  /// Success state
  ContentGeneratorState.success(GeneratedContent content)
      : isGenerating = false,
        generatedContent = content,
        errorMessage = null;

  /// Error state
  const ContentGeneratorState.error(String message)
      : isGenerating = false,
        generatedContent = null,
        errorMessage = message;

  /// Copy with
  ContentGeneratorState copyWith({
    bool? isGenerating,
    GeneratedContent? generatedContent,
    String? errorMessage,
  }) {
    return ContentGeneratorState(
      isGenerating: isGenerating ?? this.isGenerating,
      generatedContent: generatedContent ?? this.generatedContent,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Content Generator Provider
///
/// Bolaga: Bu — "buyruqlar markazi". UI dan "quiz yarat" deb kelsa,
/// bu provider ishga tushadi va barcha jarayonni boshqaradi.
class ContentGeneratorNotifier extends StateNotifier<ContentGeneratorState> {
  final GenerateQuiz generateQuizUseCase;
  final GenerateSpeaking generateSpeakingUseCase;
  final GenerateListening generateListeningUseCase;

  ContentGeneratorNotifier({
    required this.generateQuizUseCase,
    required this.generateSpeakingUseCase,
    required this.generateListeningUseCase,
  }) : super(const ContentGeneratorState.initial());

  /// Quiz yaratish
  Future<void> generateQuiz(GenerateQuizParams params) async {
    state = const ContentGeneratorState.generating();
    final result = await generateQuizUseCase(params);
    result.fold(
      (failure) => state = ContentGeneratorState.error(failure.message),
      (content) => state = ContentGeneratorState.success(content),
    );
  }

  /// Speaking yaratish
  Future<void> generateSpeaking(GenerateSpeakingParams params) async {
    state = const ContentGeneratorState.generating();
    final result = await generateSpeakingUseCase(params);
    result.fold(
      (failure) => state = ContentGeneratorState.error(failure.message),
      (content) => state = ContentGeneratorState.success(content),
    );
  }

  /// Listening yaratish
  Future<void> generateListening(GenerateListeningParams params) async {
    state = const ContentGeneratorState.generating();
    final result = await generateListeningUseCase(params);
    result.fold(
      (failure) => state = ContentGeneratorState.error(failure.message),
      (content) => state = ContentGeneratorState.success(content),
    );
  }

  void reset() => state = const ContentGeneratorState.initial();

  void clearError() {
    if (state.errorMessage != null) state = state.copyWith(errorMessage: null);
  }
}

final contentGeneratorProvider =
    StateNotifierProvider<ContentGeneratorNotifier, ContentGeneratorState>(
  (ref) {
    final generateQuiz = ref.watch(generateQuizUseCaseProvider);
    final generateSpeaking = ref.watch(generateSpeakingUseCaseProvider);
    final generateListening = ref.watch(generateListeningUseCaseProvider);

    return ContentGeneratorNotifier(
      generateQuizUseCase: generateQuiz,
      generateSpeakingUseCase: generateSpeaking,
      generateListeningUseCase: generateListening,
    );
  },
);

final generateQuizUseCaseProvider = Provider<GenerateQuiz>((ref) {
  final repository = ref.watch(contentGeneratorRepositoryProvider);
  return GenerateQuiz(repository);
});

final generateSpeakingUseCaseProvider = Provider<GenerateSpeaking>((ref) {
  final repository = ref.watch(contentGeneratorRepositoryProvider);
  final functions = ref.watch(firebaseFunctionsProvider);
  return GenerateSpeaking(repository, functions);
});

final generateListeningUseCaseProvider = Provider<GenerateListening>((ref) {
  final repository = ref.watch(contentGeneratorRepositoryProvider);
  return GenerateListening(repository);
});

// ====== Repository Provider ======
// Bu provider Repository'ni yaratadi (Data layer'dan)

final contentGeneratorRepositoryProvider =
    Provider<ContentGeneratorRepository>((ref) {
  final remoteDataSource = ref.watch(contentGeneratorRemoteDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return ContentGeneratorRepositoryImpl(
    remoteDataSource: remoteDataSource,
    networkInfo: networkInfo,
  );
});

// ====== DataSource Provider ======

final contentGeneratorRemoteDataSourceProvider =
    Provider<ContentGeneratorRemoteDataSource>((ref) {
  final functions = ref.watch(firebaseFunctionsProvider);

  return ContentGeneratorRemoteDataSourceImpl(
    functions: functions,
  );
});

// ====== Imports for providers ======

// Note: firebaseFunctionsProvider va networkInfoProvider
// core/providers papkasida aniqlanishi kerak
