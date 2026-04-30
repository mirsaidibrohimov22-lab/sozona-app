// lib/features/student/flashcards/presentation/providers/flashcard_provider.dart
// So'zona — Flashcard Riverpod providerlar
// ✅ FIX 1: FoldersNotifier — userId saqlanadi, deleteFolder ga uzatiladi
// ✅ FIX 2: CardsNotifier.loadCards — userId parametri qo'shildi
// ✅ FIX 3: ReviewSessionNotifier.startFolderReview — barcha kartochkalar
//    yuklanadi (faqat due emas), rateCard loop qiladi noto'g'ri kartochkalarni
// ✅ FIX 4: ReviewSessionState — totalInitialCards qo'shildi (progress uchun)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/providers/network_provider.dart';
import 'package:my_first_app/core/services/activity_tracker.dart';
import 'package:my_first_app/core/services/member_progress_service.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart'; // ✅ FIX: LearningLanguage
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/flashcards/data/datasources/flashcard_local_datasource.dart';
import 'package:my_first_app/features/student/flashcards/data/datasources/flashcard_remote_datasource.dart';
import 'package:my_first_app/features/student/flashcards/data/repositories/flashcard_repository_impl.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/folder_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/repositories/flashcard_repository.dart';
import 'package:my_first_app/core/services/notification_service.dart';
import 'package:my_first_app/features/student/flashcards/domain/usecases/create_card.dart';
import 'package:my_first_app/features/student/flashcards/domain/usecases/create_folder.dart';
import 'package:my_first_app/features/student/flashcards/domain/usecases/get_folders.dart';
import 'package:my_first_app/features/student/flashcards/domain/usecases/review_card.dart';

// ─── DATASOURCE PROVIDERLAR ───

final flashcardLocalDataSourceProvider =
    Provider<FlashcardLocalDataSource>((ref) {
  final ds = FlashcardLocalDataSourceImpl();
  ds.init();
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

/// ✅ FIX: userId notifier ichida saqlanadi
class FoldersNotifier extends StateNotifier<FoldersState> {
  final GetFolders _getFolders;
  final CreateFolder _createFolder;
  final FlashcardRepository _repository;
  String _userId = '';

  FoldersNotifier({
    required GetFolders getFolders,
    required CreateFolder createFolder,
    required FlashcardRepository repository,
  })  : _getFolders = getFolders,
        _createFolder = createFolder,
        _repository = repository,
        super(const FoldersState());

  Future<void> loadFolders(String userId) async {
    _userId = userId;
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

  /// ✅ FIX: userId to'g'ri uzatiladi — oldin permission xatosi bo'lardi
  Future<bool> deleteFolder(String folderId) async {
    final result = await _repository.deleteFolder(
      folderId: folderId,
      userId: _userId,
    );

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

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final foldersProvider =
    StateNotifierProvider<FoldersNotifier, FoldersState>((ref) {
  return FoldersNotifier(
    getFolders: ref.watch(getFoldersUseCaseProvider),
    createFolder: ref.watch(createFolderUseCaseProvider),
    repository: ref.watch(flashcardRepositoryProvider),
  );
});

// ─── KARTOCHKALAR HOLATI ───

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

class CardsNotifier extends StateNotifier<CardsState> {
  final FlashcardRepository _repository;
  final CreateCard _createCard;

  CardsNotifier({
    required FlashcardRepository repository,
    required CreateCard createCard,
  })  : _repository = repository,
        _createCard = createCard,
        super(const CardsState());

  /// ✅ FIX: userId qo'shildi — Firestore rules uchun zarur
  Future<void> loadCards(String folderId, String userId) async {
    state = state.copyWith(isLoading: true, currentFolderId: folderId);

    final result = await _repository.getCards(
      folderId: folderId,
      userId: userId,
    );

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

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final cardsProvider = StateNotifierProvider<CardsNotifier, CardsState>((ref) {
  return CardsNotifier(
    repository: ref.watch(flashcardRepositoryProvider),
    createCard: ref.watch(createCardUseCaseProvider),
  );
});

// ─── TAKRORLASH HOLATI ───

/// ✅ FIX: totalInitialCards qo'shildi — progress to'g'ri hisoblash uchun
class ReviewSessionState {
  final List<FlashcardEntity> cards;
  final int currentIndex;
  final bool isFlipped;
  final bool isLoading;
  final bool isCompleted;
  final int correctCount;
  final int incorrectCount;
  final int totalInitialCards;
  final String? error;

  const ReviewSessionState({
    this.cards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isLoading = false,
    this.isCompleted = false,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.totalInitialCards = 0,
    this.error,
  });

  FlashcardEntity? get currentCard =>
      cards.isNotEmpty && currentIndex < cards.length
          ? cards[currentIndex]
          : null;

  int get totalReviewed => correctCount + incorrectCount;

  /// Qolgan (noto'g'ri + ko'rilmagan)
  int get remaining => cards.length;

  /// Progress: nechta to'g'ri javob berildi / jami kartochkalar
  double get progress =>
      totalInitialCards == 0 ? 0 : correctCount / totalInitialCards;

  ReviewSessionState copyWith({
    List<FlashcardEntity>? cards,
    int? currentIndex,
    bool? isFlipped,
    bool? isLoading,
    bool? isCompleted,
    int? correctCount,
    int? incorrectCount,
    int? totalInitialCards,
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
      totalInitialCards: totalInitialCards ?? this.totalInitialCards,
      error: error,
    );
  }
}

class ReviewSessionNotifier extends StateNotifier<ReviewSessionState> {
  final FlashcardRepository _repository;
  final ReviewCard _reviewCard;
  final String _userId;
  // ✅ FIX: hardcoded 'de'/'A1' o'rniga user profildan olinadi
  final String _language;
  final String _level;

  ReviewSessionNotifier({
    required FlashcardRepository repository,
    required ReviewCard reviewCard,
    String userId = '',
    String language = 'en',
    String level = 'A1',
  })  : _repository = repository,
        _reviewCard = reviewCard,
        _userId = userId,
        _language = language,
        _level = level,
        super(const ReviewSessionState());

  /// ✅ FIX: Barcha papka kartochkalari yuklanadi (faqat due emas)
  /// Sabab: foydalanuvchi papkani ochganda BARCHA kartochkalarni ko'rmoqchi
  /// Noto'g'ri javob bersa, kartochka dekaning oxiriga qaytadi
  Future<void> startFolderReview(String folderId, String userId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getCards(
      folderId: folderId,
      userId: userId,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (cards) {
        // Barcha o'chirilmagan kartochkalar
        final allCards = cards.where((c) => !c.isDeleted).toList();
        allCards.shuffle();

        state = state.copyWith(
          isLoading: false,
          cards: allCards,
          currentIndex: 0,
          isFlipped: false,
          isCompleted: allCards.isEmpty,
          correctCount: 0,
          incorrectCount: 0,
          totalInitialCards: allCards.length,
        );
      },
    );
  }

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
          totalInitialCards: cards.length,
        );
      },
    );
  }

  void flipCard() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  /// ✅ FIX: Review loop — noto'g'ri kartochkalar dekaning oxiriga qaytariladi
  /// To'g'ri javob: kartochka dekadan o'chiriladi
  /// Noto'g'ri javob: kartochka oxiriga o'tkaziladi, qaytadan ko'rsatiladi
  /// Sessiya: BARCHA kartochkalar to'g'ri javob olganda tugaydi
  Future<void> rateCard(int quality) async {
    final card = state.currentCard;
    if (card == null) return;

    // SM-2 algoritmida saqlash
    await _reviewCard(
      ReviewCardParams(
        cardId: card.id,
        quality: quality,
      ),
    );

    final isCorrect = quality >= 3;
    final newCorrect = isCorrect ? state.correctCount + 1 : state.correctCount;
    final newIncorrect =
        !isCorrect ? state.incorrectCount + 1 : state.incorrectCount;

    // Kartochkalar ro'yxatini yangilash
    final currentCards = List<FlashcardEntity>.from(state.cards);

    if (isCorrect) {
      // ✅ To'g'ri javob: kartochkani ro'yxatdan olib tashlaymiz
      currentCards.removeAt(state.currentIndex);
      // ✅ EBBINGHAUS: to'g'ri javob berilganda notifikatsiya rejalashtirish
      // card.isNew — hali hech qachon to'g'ri javob berilmagan karta
      // card.isMastered — difficulty == CardDifficulty.mastered
      if (card.isNew || card.correctCount <= 1) {
        // Birinchi marta — barcha 8 ta intervalga notif qo'yish
        NotificationService.scheduleFlashcardReviews(
          cardId: card.id,
          cardFront: card.front,
          folderId: card.folderId,
        );
      } else if (card.isMastered) {
        // To'liq o'zlashtirilgan — barcha notiflarni bekor qilish
        NotificationService.onCardMastered(card.id);
      }
    } else {
      // ✅ Noto'g'ri javob: kartochkani oxiriga o'tkazamiz
      currentCards.removeAt(state.currentIndex);
      currentCards.add(card);
    }

    final isCompleted = currentCards.isEmpty;

    // currentIndex chegaradan chiqmasligi uchun
    int nextIndex = state.currentIndex;
    if (!isCompleted && nextIndex >= currentCards.length) {
      nextIndex = 0;
    }

    state = state.copyWith(
      cards: currentCards,
      currentIndex: nextIndex,
      isFlipped: false,
      isCompleted: isCompleted,
      correctCount: newCorrect,
      incorrectCount: newIncorrect,
    );

    // Sessiya tugaganda activity va progress yozamiz
    if (isCompleted) {
      final total = state.totalInitialCards;
      final score = total > 0 ? (newCorrect / total) * 100 : 0.0;
      ActivityTracker.recordFlashcard(
        topic: 'flashcard_review',
        language: _language, // ✅ FIX: user profildan
        level: _level, // ✅ FIX: user profildan
        correctAnswers: newCorrect,
        wrongAnswers: newIncorrect,
        responseTime: 0,
        scorePercent: score,
      );
      if (_userId.isNotEmpty) {
        await MemberProgressService.instance.recordAttempt(
          // ✅ FIX: await qo'shildi
          userId: _userId,
          scorePercent: score,
          skillType: 'flashcard',
        );
      }
    }
  }

  void reset() {
    state = const ReviewSessionState();
  }
}

final reviewSessionProvider =
    StateNotifierProvider<ReviewSessionNotifier, ReviewSessionState>((ref) {
  final user = ref.watch(authNotifierProvider).user;
  final userId = user?.id ?? '';
  // ✅ FIX: user profildan language va level olinadi
  final language =
      user?.learningLanguage == LearningLanguage.german ? 'de' : 'en';
  final level = user?.level.name.toUpperCase() ?? 'A1';
  return ReviewSessionNotifier(
    repository: ref.watch(flashcardRepositoryProvider),
    reviewCard: ref.watch(reviewCardUseCaseProvider),
    userId: userId,
    language: language,
    level: level,
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
