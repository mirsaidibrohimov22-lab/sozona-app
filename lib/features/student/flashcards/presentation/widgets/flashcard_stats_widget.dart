// lib/features/flashcard/presentation/widgets/flashcard_stats_widget.dart
// So'zona — Flashcard statistika widgeti
// Umumiy kartochka statistikasi ko'rsatish

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/animated_counter.dart';
import 'package:my_first_app/core/widgets/app_card.dart';
import 'package:my_first_app/features/student/flashcards/domain/repositories/flashcard_repository.dart';

/// Flashcard statistika widgeti
class FlashcardStatsWidget extends StatelessWidget {
  final FlashcardStats stats;

  const FlashcardStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kartochka statistikasi',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSizes.spacingLg),

          // Asosiy raqamlar
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: stats.totalCards,
                  label: 'Jami',
                  icon: Icons.style_outlined,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: stats.masteredCards,
                  label: 'O\'zlashtirilgan',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: stats.dueCards,
                  label: 'Takrorlash',
                  icon: Icons.schedule,
                  color: AppColors.streak,
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: stats.weakCards,
                  label: 'Zaif',
                  icon: Icons.warning_amber,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),

          // O'zlashtirish progressi
          if (stats.totalCards > 0) ...[
            const SizedBox(height: AppSizes.spacingLg),
            Row(
              children: [
                const Text(
                  'O\'zlashtirish',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(stats.overallAccuracy * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingSm),
            AnimatedProgressBar(
              value: stats.overallAccuracy,
              color: AppColors.primary,
              height: 6,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        AnimatedCounter(
          value: value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
