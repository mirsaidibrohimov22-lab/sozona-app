// QO'YISH: lib/features/learning_loop/domain/repositories/learning_loop_repository.dart
// So'zona — Learning Loop repository interfeysi

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/learner_profile.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/micro_session.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/weak_item_pool.dart';

abstract class LearningLoopRepository {
  // ─── Zaif elementlar ───

  /// Foydalanuvchining zaif elementlarini olish
  Future<Either<Failure, List<WeakItem>>> getWeakItems(String userId);

  /// Hozir ko'rib chiqish kerak bo'lgan zaif elementlar
  Future<Either<Failure, List<WeakItem>>> getDueWeakItems(String userId);

  /// Yangi zaif element qo'shish
  Future<Either<Failure, WeakItem>> addWeakItem({
    required String userId,
    required WeakItemSource sourceType,
    required String sourceContentId,
    required String itemType,
    required WeakItemData itemData,
  });

  /// Zaif elementni yangilash (to'g'ri/xato javob)
  Future<Either<Failure, WeakItem>> updateWeakItem(WeakItem item);

  /// Bir nechta zaif elementlarni batch yangilash
  Future<Either<Failure, List<WeakItem>>> batchUpdateWeakItems(
    List<WeakItem> items,
  );

  // ─── O'quvchi profili ───

  /// O'quvchi profilini olish
  Future<Either<Failure, LearnerProfile>> getLearnerProfile(String userId);

  /// O'quvchi profilini yangilash
  Future<Either<Failure, LearnerProfile>> updateLearnerProfile(
    LearnerProfile profile,
  );

  /// AI orqali profilni tahlil qilish
  Future<Either<Failure, LearnerProfile>> analyzeAndUpdateProfile({
    required String userId,
    required String language,
    required String level,
  });

  // ─── Mikro-sessiyalar ───

  /// Keyingi mikro-sessiyani olish yoki yaratish
  Future<Either<Failure, MicroSession>> getOrCreateNextSession(String userId);

  /// Sessiyani boshlash
  Future<Either<Failure, MicroSession>> startSession(String sessionId);

  /// Sessiyani tugatish
  Future<Either<Failure, MicroSession>> completeSession({
    required String sessionId,
    required int overallScore,
    required int weakItemsReviewed,
    required int newWeakItems,
    required int xpEarned,
    String? motivationMessage,
  });

  /// Sessiyani o'tkazib yuborish
  Future<Either<Failure, MicroSession>> skipSession(String sessionId);

  /// Sessiyalar tarixini olish
  Future<Either<Failure, List<MicroSession>>> getSessionHistory({
    required String userId,
    int limit = 20,
  });

  // ─── AI motivatsiya ───

  /// AI motivatsiya xabarini olish
  Future<Either<Failure, String>> getMotivationMessage({
    required String userId,
    required int currentStreak,
    required double averageScore,
    required String language,
  });
}
