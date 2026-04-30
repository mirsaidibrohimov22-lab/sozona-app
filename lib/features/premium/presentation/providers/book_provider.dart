// lib/features/premium/presentation/providers/book_provider.dart
// So'zona — Kitob Provider

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/premium/data/services/book_service.dart';

// ═══════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════

class BookState {
  final BookModel? book;
  final bool isLoading;
  final String? error;

  const BookState({this.book, this.isLoading = false, this.error});

  BookState copyWith({
    BookModel? book,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BookState(
      book: book ?? this.book,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════

class BookNotifier extends StateNotifier<BookState> {
  final BookService _service;
  final String _language;
  final String _level;

  BookNotifier(this._service, this._language, this._level)
      : super(const BookState());

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final book = await _service.getBook(_language, _level);
      if (!mounted) return;
      state = state.copyWith(book: book, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Kitobni yuklab bo\'lib bo\'lmadi. Internet tekshiring.',
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════

/// Foydalanuvchi tili — 'english' yoki 'german'
final userLanguageProvider = Provider<String>((ref) {
  final user = ref.watch(authNotifierProvider).user;
  return user?.learningLanguage.name ?? 'english';
});

/// Kitob provider — (language, level) juftligi bo'yicha
final bookFamilyProvider = StateNotifierProvider.autoDispose
    .family<BookNotifier, BookState, (String, String)>(
  (ref, params) {
    final notifier = BookNotifier(BookService.instance, params.$1, params.$2);
    Future.microtask(() => notifier.load());
    return notifier;
  },
);

/// Yuklab olinganmi — books_screen uchun
final bookDownloadedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, key) async {
  final parts = key.split('_');
  if (parts.length < 2) return false;
  final lang = parts[0];
  final level = parts.sublist(1).join('_');
  return BookService.instance.isDownloaded(lang, level);
});
