// lib/features/flashcard/presentation/widgets/difficulty_indicator.dart
// So'zona — Qiyinlik darajasi ko'rsatgichi
// Kartochka qanchalik o'zlashtirilganini ko'rsatadi

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';

/// Qiyinlik darajasi ko'rsatgichi
class DifficultyIndicator extends StatelessWidget {
  final CardDifficulty difficulty;
  final bool showLabel;
  final double size;

  const DifficultyIndicator({
    super.key,
    required this.difficulty,
    this.showLabel = true,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 5 ta doira — to'ldirilganligi daraja bo'yicha
        ...List.generate(5, (index) {
          final isFilled = index < _getFilledCount();
          return Container(
            width: size,
            height: size,
            margin: EdgeInsets.only(
              right: index < 4 ? 3 : 0,
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? _getColor() : _getColor().withValues(alpha: 0.15),
            ),
          );
        }),

        if (showLabel) ...[
          const SizedBox(width: AppSizes.spacingSm),
          Text(
            _getLabel(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getColor(),
            ),
          ),
        ],
      ],
    );
  }

  /// Daraja bo'yicha to'ldirilgan doiralar soni
  int _getFilledCount() {
    switch (difficulty) {
      case CardDifficulty.newCard:
        return 0;
      case CardDifficulty.hard:
        return 1;
      case CardDifficulty.medium:
        return 2;
      case CardDifficulty.easy:
        return 3;
      case CardDifficulty.mastered:
        return 5;
    }
  }

  /// Rang
  Color _getColor() {
    switch (difficulty) {
      case CardDifficulty.newCard:
        return AppColors.info;
      case CardDifficulty.hard:
        return AppColors.error;
      case CardDifficulty.medium:
        return AppColors.warning;
      case CardDifficulty.easy:
        return AppColors.success;
      case CardDifficulty.mastered:
        return AppColors.xp;
    }
  }

  /// Yorliq
  String _getLabel() {
    switch (difficulty) {
      case CardDifficulty.newCard:
        return 'Yangi';
      case CardDifficulty.hard:
        return 'Qiyin';
      case CardDifficulty.medium:
        return 'O\'rtacha';
      case CardDifficulty.easy:
        return 'Oson';
      case CardDifficulty.mastered:
        return 'O\'zlashtirilgan';
    }
  }
}
