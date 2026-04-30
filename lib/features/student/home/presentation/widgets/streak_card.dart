// lib/features/student/home/presentation/widgets/streak_card.dart
// So'zona — Streak kartochkasi
// Ketma-ket kunlar va olov ikonkasi

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/app_card.dart';
import 'package:my_first_app/features/student/home/presentation/providers/student_home_provider.dart';

/// Streak kartochkasi
class StreakCard extends StatelessWidget {
  /// Streak ma'lumotlari
  final StreakData streak;

  const StreakCard({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: streak.todayCompleted
          ? AppColors.streak.withValues(alpha: 0.3)
          : AppColors.bgTertiary,
      backgroundColor: streak.todayCompleted
          ? AppColors.streak.withValues(alpha: 0.05)
          : null,
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Olov ikonkasi va raqam
          Row(
            children: [
              Text(
                streak.todayCompleted ? '🔥' : '🔥',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: AppSizes.spacingSm),
              Text(
                '${streak.currentStreak}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: streak.currentStreak > 0
                          ? AppColors.streak
                          : AppColors.textTertiary,
                    ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spacingXs),

          // Yorliq
          const Text(
            'Streak',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 2),

          // Holat
          Text(
            streak.todayCompleted
                ? 'Bugun bajarildi! ✅'
                : 'Bugun mashq qiling!',
            style: TextStyle(
              fontSize: 11,
              color:
                  streak.todayCompleted ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
