//lib/features/student/flashcards/presentation/providers/flashcard_provider.dart
// So'zona — Flashcard Riverpod providerlar
// Papkalar, kartochkalar, takrorlash holati

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/providers/network_provider.dart';
import 'package:my_first_app/core/services/activity_tracker.dart';
import 'package:my_first_app/core/services/member_progress_service.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/flashcards/data/datasources/flashcard_local_datasource.dart';
import 'package:my_first_app/features/student/flashcards/data/datasources/flashcard_remote_datasource.dart';
import 'package:my_first_app/features/student/flashcards/data/repositories/flashcard_repository_impl.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/folder_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/repositories/flashcard_repository.dart';
import 'package:my_first_app/features/student/flashcards/domain/usecases/create_card.dart';
import 'package:my_first_app/features/student/flashcards/domain/usecases/create_folder.dart';
import 'package:my_first_app/features/student/flashcards/domain/usecases/get_folders.dart';
import 'package:my_first_app/features/student/flashcards/domain/usecases/review_card.dart';

// ─── DATASOURCE PROVIDERLAR ───

final flashcardLocalDataSourceProvider =
    Provider<FlashcardLocalDataSource>((ref) {
  final ds = FlashcardLocalDataSourceImpl();
  ds.init(); // Async init — startup'da chaqiriladi
  return ds;
});

final flashcardRemoteDataSourceProvider =
    Provider<FlashcardRemoteDataSource>((ref) {
  return FlashcardRemoteDataSourceImpl();
});

// ─── REPOSITORY ───

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepositoryImpl(
    remoteDataSource: ref.watch(flashcardRemoteDataSourceProvider),
    localDataSource: ref.watch(flashcardLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// ─── USE CASE PROVIDERLAR ───

final getFoldersUseCaseProvider = Provider<GetFolders>((ref) {
  return GetFolders(ref.watch(flashcardRepositoryProvider));
});

final createFolderUseCaseProvider = Provider<CreateFolder>((ref) {
  return CreateFolder(ref.watch(flashcardRepositoryProvider));
});

final createCardUseCaseProvider = Provider<CreateCard>((ref) {
  return CreateCard(ref.watch(flashcardRepositoryProvider));
});

final reviewCardUseCaseProvider = Provider<ReviewCard>((ref) {
  return ReviewCard(ref.watch(flashcardRepositoryProvider));
});

// ─── PAPKALAR HOLATI ───

/// Papkalar ro'yxati holati
class FoldersState {
  final List<FolderEntity> folders;
  final bool isLoading;
  final String? error;

  const FoldersState({
    this.folders = const [],
    this.isLoading = false,
    this.error,
  });

  FoldersState copyWith({
    List<FolderEntity>? folders,
    bool? isLoading,
    String? error,
  }) {
    return FoldersState(
      folders: folders ?? this.folders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Papkalar notifier
class FoldersNotifier extends StateNotifier<FoldersState> {
  final GetFolders _getFolders;
  final CreateFolder _createFolder;
  final FlashcardRepository _repository;

  FoldersNotifier({
    required GetFolders getFolders,
    required CreateFolder createFolder,
    required FlashcardRepository repository,
  })  : _getFolders = getFolders,
        _createFolder = createFolder,
        _repository = repository,
        super(const FoldersState());

  /// Papkalarni yuklash
  Future<void> loadFolders(String userId) async {
    state = state.copyWith(isLoading: true);

    final result = await _getFolders(GetFoldersParams(userId: userId));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (folders) => state = state.copyWith(
        isLoading: false,
        folders: folders,
      ),
    );
  }

  /// Yangi papka yaratish
  Future<bool> createFolder({
    required String userId,
    required String name,
    String? description,
    FolderColor color = FolderColor.blue,
    String? emoji,
    String language = 'english',
    String? cefrLevel,
  }) async {
    final result = await _createFolder(
      CreateFolderParams(
        userId: userId,
        name: name,
        description: description,
        color: color,
        emoji: emoji,
        language: language,
        cefrLevel: cefrLevel,
      ),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (folder) {
        state = state.copyWith(
          folders: [folder, ...state.folders],
        );
        return true;
      },
    );
  }

  /// Papka o'chirish
  Future<bool> deleteFolder(String folderId) async {
    final result = await _repository.deleteFolder(folderId: folderId);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          folders: state.folders.where((f) => f.id != folderId).toList(),
        );
        return true;
      },
    );
  }

  /// Xatolikni tozalash
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Papkalar provider
final foldersProvider =
    StateNotifierProvider<FoldersNotifier, FoldersState>((ref) {
  return FoldersNotifier(
    getFolders: ref.watch(getFoldersUseCaseProvider),
    createFolder: ref.watch(createFolderUseCaseProvider),
    repository: ref.watch(flashcardRepositoryProvider),
  );
});

// ─── KARTOCHKALAR HOLATI ───

/// Kartochkalar ro'yxati holati
class CardsState {
  final List<FlashcardEntity> cards;
  final bool isLoading;
  final String? error;
  final String? currentFolderId;

  const CardsState({
    this.cards = const [],
    this.isLoading = false,
    this.error,
    this.currentFolderId,
  });

  CardsState copyWith({
    List<FlashcardEntity>? cards,
    bool? isLoading,
    String? error,
    String? currentFolderId,
  }) {
    return CardsState(
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentFolderId: currentFolderId ?? this.currentFolderId,
    );
  }
}

/// Kartochkalar notifier
class CardsNotifier extends StateNotifier<CardsState> {
  final FlashcardRepository _repository;
  final CreateCard _createCard;

  CardsNotifier({
    required FlashcardRepository repository,
    required CreateCard createCard,
  })  : _repository = repository,
        _createCard = createCard,
        super(const CardsState());

  /// Papkadagi kartochkalarni yuklash
  Future<void> loadCards(String folderId) async {
    state = state.copyWith(isLoading: true, currentFolderId: folderId);

    final result = await _repository.getCards(folderId: folderId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (cards) => state = state.copyWith(
        isLoading: false,
        cards: cards,
      ),
    );
  }

  /// Yangi kartochka yaratish
  Future<bool> createCard({
    required String folderId,
    required String userId,
    required String front,
    required String back,
    String? example,
    String? pronunciation,
    String? cefrLevel,
    String? wordType,
    String? artikel,
  }) async {
    final result = await _createCard(
      CreateCardParams(
        folderId: folderId,
        userId: userId,
        front: front,
        back: back,
        example: example,
        pronunciation: pronunciation,
        cefrLevel: cefrLevel,
        wordType: wordType,
        artikel: artikel,
      ),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (card) {
        state = state.copyWith(
          cards: [card, ...state.cards],
        );
        return true;
      },
    );
  }

  /// Kartochka o'chirish
  Future<bool> deleteCard(String cardId) async {
    final result = await _repository.deleteCard(cardId: cardId);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          cards: state.cards.where((c) => c.id != cardId).toList(),
        );
        return true;
      },
    );
  }

  /// Xatolikni tozalash
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Kartochkalar provider
final cardsProvider = StateNotifierProvider<CardsNotifier, CardsState>((ref) {
  return CardsNotifier(
    repository: ref.watch(flashcardRepositoryProvider),
    createCard: ref.watch(createCardUseCaseProvider),
  );
});

// ─── TAKRORLASH HOLATI ───

/// Takrorlash sessiyasi holati
class ReviewSessionState {
  final List<FlashcardEntity> cards;
  final int currentIndex;
  final bool isFlipped;
  final bool isLoading;
  final bool isCompleted;
  final int correctCount;
  final int incorrectCount;
  final String? error;

  const ReviewSessionState({
    this.cards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isLoading = false,
    this.isCompleted = false,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.error,
  });

  /// Hozirgi kartochka
  FlashcardEntity? get currentCard =>
      currentIndex < cards.length ? cards[currentIndex] : null;

  /// Jami ko'rilgan
  int get totalReviewed => correctCount + incorrectCount;

  /// Qolgan kartochkalar
  int get remaining => cards.length - currentIndex;

  /// Progress (0.0 - 1.0)
  double get progress => cards.isEmpty ? 0 : currentIndex / cards.length;

  ReviewSessionState copyWith({
    List<FlashcardEntity>? cards,
    int? currentIndex,
    bool? isFlipped,
    bool? isLoading,
    bool? isCompleted,
    int? correctCount,
    int? incorrectCount,
    String? error,
  }) {
    return ReviewSessionState(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      error: error,
    );
  }
}

/// Takrorlash sessiyasi notifier
class ReviewSessionNotifier extends StateNotifier<ReviewSessionState> {
  final FlashcardRepository _repository;
  final ReviewCard _reviewCard;
  // ✅ FIX: member progress yangilash uchun userId
  final String _userId;

  ReviewSessionNotifier({
    required FlashcardRepository repository,
    required ReviewCard reviewCard,
    String userId = '',
  })  : _repository = repository,
        _reviewCard = reviewCard,
        _userId = userId,
        super(const ReviewSessionState());

  /// Takrorlash sessiyasini boshlash (papka bo'yicha)
  Future<void> startFolderReview(String folderId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getCards(folderId: folderId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (cards) {
        // Takrorlashga tayyor kartochkalarni filter qilish
        final dueCards = cards.where((c) => c.isDueForReview).toList();
        // Aralashtirish
        dueCards.shuffle();

        state = state.copyWith(
          isLoading: false,
          cards: dueCards,
          currentIndex: 0,
          isFlipped: false,
          isCompleted: dueCards.isEmpty,
          correctCount: 0,
          incorrectCount: 0,
        );
      },
    );
  }

  /// Due kartochkalarni takrorlash
  Future<void> startDueReview(String userId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getDueCards(userId: userId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (cards) {
        cards.shuffle();
        state = state.copyWith(
          isLoading: false,
          cards: cards,
          currentIndex: 0,
          isFlipped: false,
          isCompleted: cards.isEmpty,
          correctCount: 0,
          incorrectCount: 0,
        );
      },
    );
  }

  /// Kartochkani ag'darish
  void flipCard() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  /// Baholash va keyingisiga o'tish
  Future<void> rateCard(int quality) async {
    final card = state.currentCard;
    if (card == null) return;

    // Natijani saqlash
    await _reviewCard(
      ReviewCardParams(
        cardId: card.id,
        quality: quality,
      ),
    );

    final isCorrect = quality >= 3;
    final nextIndex = state.currentIndex + 1;
    final isLast = nextIndex >= state.cards.length;

    final newCorrect = isCorrect ? state.correctCount + 1 : state.correctCount;
    final newIncorrect =
        !isCorrect ? state.incorrectCount + 1 : state.incorrectCount;

    state = state.copyWith(
      currentIndex: nextIndex,
      isFlipped: false,
      isCompleted: isLast,
      correctCount: newCorrect,
      incorrectCount: newIncorrect,
    );

    // ✅ Sessiya tugaganda XP/Streak uchun activity yozish
    if (isLast) {
      final total = newCorrect + newIncorrect;
      final score = total > 0 ? (newCorrect / total) * 100 : 0.0;
      ActivityTracker.recordFlashcard(
        topic: 'flashcard_review',
        language: 'de',
        level: 'A1',
        correctAnswers: newCorrect,
        wrongAnswers: newIncorrect,
        responseTime: 0,
        scorePercent: score,
      );
      // ✅ FIX: Member progress yangilash — barcha sinflarda averageScore yangilanadi
      if (_userId.isNotEmpty) {
        MemberProgressService.instance.recordAttempt(
          userId: _userId,
          scorePercent: score,
          skillType: 'flashcard',
        );
      }
    }
  }

  /// Sessiyani qayta boshlash
  void reset() {
    state = const ReviewSessionState();
  }
}

/// Takrorlash sessiyasi provider
final reviewSessionProvider =
    StateNotifierProvider<ReviewSessionNotifier, ReviewSessionState>((ref) {
  // ✅ FIX: userId ni provider ga uzatamiz
  final userId = ref.watch(authNotifierProvider).user?.id ?? '';
  return ReviewSessionNotifier(
    repository: ref.watch(flashcardRepositoryProvider),
    reviewCard: ref.watch(reviewCardUseCaseProvider),
    userId: userId,
  );
});

// ─── PRACTICE SESSION STATE ───

class FlashcardPracticeState {
  final List<FlashcardEntity> cards;
  final int currentIndex;
  final bool isFlipped;
  final bool isLoading;
  final bool isSessionDone;
  final String? error;

  const FlashcardPracticeState({
    this.cards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isLoading = false,
    this.isSessionDone = false,
    this.error,
  });

  FlashcardEntity? get currentCard =>
      cards.isNotEmpty && currentIndex < cards.length
          ? cards[currentIndex]
          : null;

  FlashcardPracticeState copyWith({
    List<FlashcardEntity>? cards,
    int? currentIndex,
    bool? isFlipped,
    bool? isLoading,
    bool? isSessionDone,
    String? error,
  }) =>
      FlashcardPracticeState(
        cards: cards ?? this.cards,
        currentIndex: currentIndex ?? this.currentIndex,
        isFlipped: isFlipped ?? this.isFlipped,
        isLoading: isLoading ?? this.isLoading,
        isSessionDone: isSessionDone ?? this.isSessionDone,
        error: error,
      );
}

class FlashcardPracticeNotifier extends StateNotifier<FlashcardPracticeState> {
  final FlashcardRepository _repo;

  FlashcardPracticeNotifier(this._repo) : super(const FlashcardPracticeState());

  Future<void> loadCards(String folderId, String userId) async {
    if (!mounted) return;
    state = state.copyWith(
      isLoading: true,
      currentIndex: 0,
      isFlipped: false,
      isSessionDone: false,
    );
    final result = await _repo.getDueCards(userId: userId, limit: 20);
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (cards) {
        // Filter by folder if provided
        final filtered = folderId.isNotEmpty
            ? cards.where((c) => c.folderId == folderId).toList()
            : cards;
        state = state.copyWith(
          isLoading: false,
          cards: filtered,
          isSessionDone: filtered.isEmpty,
        );
      },
    );
  }

  void flip() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  Future<void> rate(String userId, double score) async {
    final card = state.currentCard;
    if (card == null || !mounted) return;
    // quality 0-5 from score 0.0-1.0
    final quality = (score * 5).round().clamp(0, 5);
    await _repo.reviewCard(cardId: card.id, quality: quality);
    if (!mounted) return;
    final nextIndex = state.currentIndex + 1;
    final done = nextIndex >= state.cards.length;
    state = state.copyWith(
      currentIndex: done ? state.currentIndex : nextIndex,
      isFlipped: false,
      isSessionDone: done,
    );
  }
}

final flashcardProvider =
    StateNotifierProvider<FlashcardPracticeNotifier, FlashcardPracticeState>(
  (ref) => FlashcardPracticeNotifier(ref.watch(flashcardRepositoryProvider)),
);
