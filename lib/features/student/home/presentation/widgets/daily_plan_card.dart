// lib/features/student/home/presentation/widgets/daily_plan_card.dart
// So'zona — Kunlik reja kartochkasi
// Bugungi progress va qolgan vaqt

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/animated_counter.dart';
import 'package:my_first_app/core/widgets/app_card.dart';
import 'package:my_first_app/features/student/home/presentation/providers/student_home_provider.dart';

/// Kunlik reja kartochkasi
class DailyPlanCard extends StatelessWidget {
  /// Kunlik reja ma'lumotlari
  final DailyPlan dailyPlan;

  const DailyPlanCard({super.key, required this.dailyPlan});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: dailyPlan.isCompleted
          ? AppColors.success.withValues(alpha: 0.3)
          : AppColors.bgTertiary,
      backgroundColor: dailyPlan.isCompleted
          ? AppColors.success.withValues(alpha: 0.05)
          : null,
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikonka va daqiqa
          Row(
            children: [
              Text(
                dailyPlan.isCompleted ? '🎯' : '⏱️',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: AppSizes.spacingSm),
              AnimatedCounter(
                value: dailyPlan.completedMinutes,
                suffix: ' daq',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dailyPlan.isCompleted
                          ? AppColors.success
                          : AppColors.primary,
                    ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spacingXs),

          // Yorliq
          const Text(
            'Kunlik maqsad',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: AppSizes.spacingSm),

          // Progress bar
          AnimatedProgressBar(
            value: dailyPlan.progressPercent,
            color:
                dailyPlan.isCompleted ? AppColors.success : AppColors.primary,
            height: 6,
          ),

          const SizedBox(height: 4),

          // Qolgan vaqt
          Text(
            dailyPlan.isCompleted
                ? 'Maqsad bajarildi! 🎉'
                : '${dailyPlan.remainingMinutes} daq qoldi',
            style: TextStyle(
              fontSize: 11,
              color: dailyPlan.isCompleted
                  ? AppColors.success
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
