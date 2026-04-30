import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/teacher/publishing/data/datasources/publishing_remote_datasource.dart';
import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/features/teacher/publishing/data/repositories/publishing_repository_impl.dart';
import 'package:my_first_app/features/teacher/publishing/domain/repositories/publishing_repository.dart';
import 'package:my_first_app/features/teacher/publishing/domain/usecases/publish_content.dart';
import 'package:my_first_app/features/teacher/publishing/domain/usecases/schedule_content.dart';

// QO'YISH: lib/features/teacher/publishing/presentation/providers/publishing_provider.dart
// Publishing Provider — State management

/// Publishing State
class PublishingState {
  final bool isPublishing;
  final bool isSuccess;
  final String? errorMessage;

  const PublishingState({
    this.isPublishing = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  const PublishingState.initial()
      : isPublishing = false,
        isSuccess = false,
        errorMessage = null;

  const PublishingState.publishing()
      : isPublishing = true,
        isSuccess = false,
        errorMessage = null;

  const PublishingState.success()
      : isPublishing = false,
        isSuccess = true,
        errorMessage = null;

  const PublishingState.error(String message)
      : isPublishing = false,
        isSuccess = false,
        errorMessage = message;
}

/// Publishing Provider
class PublishingNotifier extends StateNotifier<PublishingState> {
  final PublishContent publishContentUseCase;
  final ScheduleContent scheduleContentUseCase;

  PublishingNotifier({
    required this.publishContentUseCase,
    required this.scheduleContentUseCase,
  }) : super(const PublishingState.initial());

  /// Kontentni darhol yuborish
  Future<void> publishNow(PublishContentParams params) async {
    state = const PublishingState.publishing();

    final result = await publishContentUseCase(params);

    result.fold(
      (failure) => state = PublishingState.error(failure.message),
      (_) => state = const PublishingState.success(),
    );
  }

  /// Kontentni kelajakda yuborish uchun rejalashtirish
  Future<void> scheduleForLater(ScheduleContentParams params) async {
    state = const PublishingState.publishing();

    final result = await scheduleContentUseCase(params);

    result.fold(
      (failure) => state = PublishingState.error(failure.message),
      (_) => state = const PublishingState.success(),
    );
  }

  /// State'ni reset qilish
  void reset() {
    state = const PublishingState.initial();
  }
}

/// Publishing Provider Definition
final publishingProvider =
    StateNotifierProvider<PublishingNotifier, PublishingState>((ref) {
  final publishContent = ref.watch(publishContentUseCaseProvider);
  final scheduleContent = ref.watch(scheduleContentUseCaseProvider);

  return PublishingNotifier(
    publishContentUseCase: publishContent,
    scheduleContentUseCase: scheduleContent,
  );
});

// UseCase Providers
final publishContentUseCaseProvider = Provider<PublishContent>((ref) {
  final repository = ref.watch(publishingRepositoryProvider);
  return PublishContent(repository);
});

final scheduleContentUseCaseProvider = Provider<ScheduleContent>((ref) {
  final repository = ref.watch(publishingRepositoryProvider);
  return ScheduleContent(repository);
});

// Repository Provider
final publishingRepositoryProvider = Provider<PublishingRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);

  final remote = PublishingRemoteDataSourceImpl(firestore);
  return PublishingRepositoryImpl(remote);
});

// Core providers (bu fayllar core papkada bo'lishi kerak)
