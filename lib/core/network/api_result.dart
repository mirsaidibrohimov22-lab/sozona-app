// ═══════════════════════════════════════════════════════════════
// SO'ZONA — API Result Type
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';

import 'package:my_first_app/core/error/failures.dart';

/// API natijasi turi — har doim MUVAFFAQIYAT yoki XATOLIK qaytaradi.
///
/// Bolaga tushuntirish:
/// Imtihon natijasi — yoki "O'tdi" yoki "Yiqildi". Ikkalasi ham bo'lishi MUMKIN EMAS.
/// ApiResult ham shunday — yoki Failure (xato), yoki T (natija).
///
/// Foydalanish:
/// ```dart
/// final result = await repository.getQuizzes();
/// result.fold(
///   (failure) => showError(failure.message),  // Xatolik
///   (quizzes) => showQuizzes(quizzes),        // Muvaffaqiyat
/// );
/// ```
typedef ApiResult<T> = Either<Failure, T>;

/// Paginatsiya bilan natija.
///
/// Ro'yxat ko'p bo'lganda — sahifalab olinadi.
/// [items] — hozirgi sahifadagi elementlar.
/// [hasMore] — yana sahifa bormi?
/// [lastDocument] — Firestore cursor (keyingi sahifa uchun).
class PaginatedResult<T> {
  final List<T> items;
  final bool hasMore;
  final dynamic lastDocument;

  const PaginatedResult({
    required this.items,
    required this.hasMore,
    this.lastDocument,
  });

  /// Bo'sh natija — hech narsa topilmadi.
  const PaginatedResult.empty()
      : items = const [],
        hasMore = false,
        lastDocument = null;

  /// Elementlar soni.
  int get count => items.length;

  /// Bo'shmi?
  bool get isEmpty => items.isEmpty;

  /// Bo'sh emasmi?
  bool get isNotEmpty => items.isNotEmpty;
}
