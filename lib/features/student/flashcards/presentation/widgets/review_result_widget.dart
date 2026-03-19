// lib/features/flashcard/presentation/widgets/review_result_widget.dart
// So'zona — Takrorlash natijasi widgeti
// Review ekranida inline ko'rsatiladi

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/animated_counter.dart';
import 'package:my_first_app/core/widgets/app_button.dart';

/// Takrorlash natijasi widgeti
class ReviewResultWidget extends StatelessWidget {
  final int correctCount;
  final int incorrectCount;
  final int totalCards;
  final VoidCallback onClose;
  final VoidCallback? onRetry;

  const ReviewResultWidget({
    super.key,
    required this.correctCount,
    required this.incorrectCount,
    required this.totalCards,
    required this.onClose,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy =
        totalCards > 0 ? (correctCount / totalCards * 100).round() : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Natija emoji
            Text(
              accuracy >= 80
                  ? '🏆'
                  : accuracy >= 50
                      ? '💪'
                      : '📚',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: AppSizes.spacingLg),

            // Sarlavha
            Text(
              totalCards == 0
                  ? 'Takrorlash kerak emas!'
                  : accuracy >= 80
                      ? 'Ajoyib natija!'
                      : accuracy >= 50
                          ? 'Yaxshi harakat!'
                          : 'Davom eting!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingSm),

            if (totalCards == 0)
              const Text(
                'Hozircha takrorlashga tayyor kartochkalar yo\'q',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              )
            else ...[
              // Statistika
              const SizedBox(height: AppSizes.spacingXl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ResultStat(
                    value: correctCount,
                    label: 'To\'g\'ri',
                    color: AppColors.success,
                    icon: Icons.check_circle,
                  ),
                  _ResultStat(
                    value: incorrectCount,
                    label: 'Noto\'g\'ri',
                    color: AppColors.error,
                    icon: Icons.cancel,
                  ),
                  _ResultStat(
                    value: accuracy,
                    label: 'Aniqlik',
                    color: AppColors.primary,
                    icon: Icons.percent,
                    suffix: '%',
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSizes.spacingXxl),

            // Tugmalar
            if (onRetry != null && incorrectCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingMd),
                child: AppButton(
                  label: 'Noto\'g\'rilarni qayta takrorlash',
                  type: AppButtonType.outlined,
                  icon: Icons.refresh,
                  onPressed: onRetry,
                ),
              ),
            AppButton(
              label: 'Yakunlash',
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final IconData icon;
  final String? suffix;

  const _ResultStat({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: AppSizes.spacingSm),
        AnimatedCounter(
          value: value,
          suffix: suffix,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
