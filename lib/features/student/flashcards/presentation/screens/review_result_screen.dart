// lib/features/flashcard/presentation/screens/review_result_screen.dart
// So'zona — Takrorlash natijasi ekrani
// Sessiya yakunlangandan keyin ko'rsatiladi

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/animated_counter.dart';
import 'package:my_first_app/core/widgets/app_button.dart';

/// Takrorlash natijasi ekrani
class ReviewResultScreen extends StatelessWidget {
  final int correctCount;
  final int incorrectCount;
  final int totalCards;
  final VoidCallback onClose;
  final VoidCallback? onRetry;

  const ReviewResultScreen({
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
    final emoji = _getEmoji(accuracy);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji
            Text(emoji, style: const TextStyle(fontSize: 64)),

            const SizedBox(height: AppSizes.spacingXl),

            // Sarlavha
            Text(
              _getTitle(accuracy),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingSm),

            Text(
              _getSubtitle(accuracy),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingXxl),

            // Statistika
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCircle(
                  value: correctCount,
                  label: 'To\'g\'ri',
                  color: AppColors.success,
                ),
                _StatCircle(
                  value: incorrectCount,
                  label: 'Noto\'g\'ri',
                  color: AppColors.error,
                ),
                _StatCircle(
                  value: accuracy,
                  label: 'Aniqlik',
                  color: AppColors.primary,
                  suffix: '%',
                ),
              ],
            ),

            const SizedBox(height: AppSizes.spacingXxl),

            // Tugmalar
            if (onRetry != null && incorrectCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingMd),
                child: AppButton(
                  label: 'Qayta takrorlash',
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

  String _getEmoji(int accuracy) {
    if (accuracy >= 90) return '🏆';
    if (accuracy >= 70) return '🎉';
    if (accuracy >= 50) return '💪';
    return '📚';
  }

  String _getTitle(int accuracy) {
    if (accuracy >= 90) return 'Ajoyib natija!';
    if (accuracy >= 70) return 'Yaxshi ish!';
    if (accuracy >= 50) return 'Yomon emas!';
    return 'Davom eting!';
  }

  String _getSubtitle(int accuracy) {
    if (accuracy >= 90) return 'Siz bu so\'zlarni juda yaxshi bilasiz';
    if (accuracy >= 70) return 'Biroz takrorlash bilan mukammal bo\'ladi';
    if (accuracy >= 50) return 'Har kuni mashq qiling — natija yaxshilanadi';
    return 'Xavotir olmang, takrorlash bilan o\'rganasiz';
  }
}

/// Yumaloq statistika ko'rsatgich
class _StatCircle extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final String? suffix;

  const _StatCircle({
    required this.value,
    required this.label,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          alignment: Alignment.center,
          child: AnimatedCounter(
            value: value,
            suffix: suffix,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spacingSm),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
