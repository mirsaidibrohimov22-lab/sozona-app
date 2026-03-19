// QO'YISH: lib/features/learning_loop/domain/usecases/suggest_level_change.dart
// So'zona — Daraja o'zgarishini tavsiya qilish

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/learner_profile.dart';
import 'package:my_first_app/features/learning_loop/domain/repositories/learning_loop_repository.dart';

class SuggestLevelChangeParams extends Equatable {
  final String userId;
  final String currentLevel; // "A1", "A2", "B1", "B2", "C1"
  final String language; // "en" | "de"

  const SuggestLevelChangeParams({
    required this.userId,
    required this.currentLevel,
    required this.language,
  });

  @override
  List<Object?> get props => [userId, currentLevel, language];
}

/// Daraja tavsiyasi natijasi
class LevelSuggestion extends Equatable {
  /// Tavsiya qilingan daraja (null = hozirgi daraja to'g'ri)
  final String? suggestedLevel;
  final String reason;
  final bool shouldChange;

  const LevelSuggestion({
    this.suggestedLevel,
    required this.reason,
    this.shouldChange = false,
  });

  @override
  List<Object?> get props => [suggestedLevel, shouldChange];
}

/// Daraja o'zgarishini tavsiya qilish UseCase
class SuggestLevelChange
    implements UseCase<LevelSuggestion, SuggestLevelChangeParams> {
  final LearningLoopRepository _repository;

  SuggestLevelChange(this._repository);

  @override
  Future<Either<Failure, LevelSuggestion>> call(
    SuggestLevelChangeParams params,
  ) async {
    // Profilni olish
    final profileResult = await _repository.getLearnerProfile(params.userId);

    return profileResult.fold(
      Left.new,
      (profile) async {
        // Kamida 20 ta urinish bo'lmasa — tavsiya bermaymiz
        if (!profile.isProfileReady || profile.totalAttempts < 20) {
          return Right(
            LevelSuggestion(
              reason:
                  'Tavsiya berish uchun kamida 20 ta mashq kerak (hozir: ${profile.totalAttempts})',
              shouldChange: false,
            ),
          );
        }

        // AI orqali tahlil
        final analysisResult = await _repository.analyzeAndUpdateProfile(
          userId: params.userId,
          language: params.language,
          level: params.currentLevel,
        );

        return analysisResult.fold(
          (_) => Right(_localSuggestion(profile, params.currentLevel)),
          (updatedProfile) => Right(
            _buildSuggestion(updatedProfile, params.currentLevel),
          ),
        );
      },
    );
  }

  /// AI ishlamasa local mantiq
  LevelSuggestion _localSuggestion(
    LearnerProfile profile,
    String currentLevel,
  ) {
    final avg = profile.averageSessionScore;
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1'];
    final currentIndex = levels.indexOf(currentLevel);

    if (avg >= 85 && currentIndex < levels.length - 1) {
      return LevelSuggestion(
        suggestedLevel: levels[currentIndex + 1],
        reason:
            "O'rtacha ballingiz ${avg.toStringAsFixed(0)}% — yuqori darajaga tayyor!",
        shouldChange: true,
      );
    } else if (avg < 40 && currentIndex > 0) {
      return LevelSuggestion(
        suggestedLevel: levels[currentIndex - 1],
        reason:
            "O'rtacha ballingiz ${avg.toStringAsFixed(0)}% — pastroq darajadan boshlash tavsiya etiladi.",
        shouldChange: true,
      );
    }

    return LevelSuggestion(
      reason: 'Hozirgi daraja ($currentLevel) sizga mos kelmoqda.',
      shouldChange: false,
    );
  }

  LevelSuggestion _buildSuggestion(
    LearnerProfile profile,
    String currentLevel,
  ) {
    if (profile.suggestedLevel != null &&
        profile.suggestedLevel != currentLevel) {
      return LevelSuggestion(
        suggestedLevel: profile.suggestedLevel,
        reason: profile.suggestedLevelReason ??
            "AI tahlili asosida daraja o'zgarishi tavsiya etiladi.",
        shouldChange: true,
      );
    }

    return LevelSuggestion(
      reason: profile.suggestedLevelReason ??
          'Hozirgi daraja ($currentLevel) sizga mos kelmoqda.',
      shouldChange: false,
    );
  }
}
