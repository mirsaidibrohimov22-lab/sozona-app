// lib/features/student/home/presentation/widgets/level_progress_widget.dart
// So'zona — Daraja progress widgeti
// CEFR darajasi va XP progress bar

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/animated_counter.dart';
import 'package:my_first_app/core/widgets/app_badge.dart';
import 'package:my_first_app/core/widgets/app_card.dart';

/// Daraja va XP progress widgeti
class LevelProgressWidget extends StatelessWidget {
  /// Hozirgi daraja (masalan: "A1", "B2")
  final String level;

  /// Hozirgi XP
  final int xp;

  /// Keyingi daraja uchun kerakli XP
  final int xpForNextLevel;

  const LevelProgressWidget({
    super.key,
    required this.level,
    required this.xp,
    required this.xpForNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        xpForNextLevel > 0 ? (xp / xpForNextLevel).clamp(0.0, 1.0) : 0.0;

    return AppCard.outlined(
      child: Column(
        children: [
          Row(
            children: [
              // Daraja badge
              AppBadge.level(level),

              const SizedBox(width: AppSizes.spacingMd),

              // XP ma'lumoti
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sizning darajangiz',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        AnimatedCounter(
                          value: xp,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.xp,
                          ),
                        ),
                        Text(
                          ' / $xpForNextLevel XP',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // XP badge
              AppBadge.xp(xp),
            ],
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Progress bar
          AnimatedProgressBar(
            value: progress,
            color: AppColors.xp,
            height: 8,
            borderRadius: 4,
          ),

          const SizedBox(height: AppSizes.spacingXs),

          // Qolgan XP
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${xpForNextLevel - xp} XP keyingi darajaga',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
