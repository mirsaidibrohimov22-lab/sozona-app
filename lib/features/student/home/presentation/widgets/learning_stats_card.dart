// lib/features/student/home/presentation/widgets/learning_stats_card.dart
// So'zona — Bugungi o'quv statistikasi
// ✅ Foiz ko'rsatadi: Flashcard 50%, Quiz 60%, Listening 40%, Speaking 0%
// ✅ Progress bar bilan vizual ko'rinish

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/widgets/app_card.dart';
import 'package:my_first_app/features/student/home/presentation/providers/student_home_provider.dart';

class LearningStatsCard extends StatelessWidget {
  final int flashcardsDone; // 0-100 foiz
  final int quizzesDone; // 0-100 foiz
  final int listeningDone; // 0-100 foiz
  final int weakItemsCount;
  final int speakingDone; // 0-100 foiz

  const LearningStatsCard({
    super.key,
    required this.flashcardsDone,
    required this.quizzesDone,
    required this.listeningDone,
    required this.weakItemsCount,
    this.speakingDone = 0,
  });

  // DailyPlan dan to'g'ridan qabul qiluvchi constructor
  factory LearningStatsCard.fromPlan({
    Key? key,
    required DailyPlan dailyPlan,
    required int weakItemsCount,
  }) {
    return LearningStatsCard(
      key: key,
      flashcardsDone: dailyPlan.flashcardsDone,
      quizzesDone: dailyPlan.quizzesDone,
      listeningDone: dailyPlan.listeningDone,
      speakingDone: dailyPlan.speakingDone,
      weakItemsCount: weakItemsCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bugungi statistika',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              // Umumiy o'rtacha
              _avgBadge(
                  flashcardsDone, quizzesDone, listeningDone, speakingDone),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          _SkillRow(
            emoji: '📝',
            label: 'Flashcard',
            percent: flashcardsDone,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSizes.spacingSm),
          _SkillRow(
            emoji: '🧠',
            label: 'Quiz',
            percent: quizzesDone,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSizes.spacingSm),
          _SkillRow(
            emoji: '🎧',
            label: 'Listening',
            percent: listeningDone,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppSizes.spacingSm),
          _SkillRow(
            emoji: '🗣️',
            label: 'Speaking',
            percent: speakingDone,
            color: const Color(0xFF10B981),
          ),
          if (weakItemsCount > 0) ...[
            const Divider(height: AppSizes.spacingLg),
            Row(
              children: [
                const Text('💪', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  '$weakItemsCount ta zaif so\'z — mashq qiling!',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _avgBadge(int f, int q, int l, int s) {
    final vals = [f, q, l, s].where((v) => v > 0).toList();
    if (vals.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Bugun hali mashq yo\'q',
          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
      );
    }
    final avg = vals.reduce((a, b) => a + b) ~/ vals.length;
    final color = avg >= 70
        ? AppColors.success
        : avg >= 40
            ? AppColors.warning
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'O\'rtacha $avg%',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final String emoji;
  final String label;
  final int percent; // 0-100
  final Color color;

  const _SkillRow({
    required this.emoji,
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0, 100);
    final hasData = pct > 0;

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        // Progress bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                hasData ? color : Colors.grey.shade300,
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Foiz
        SizedBox(
          width: 40,
          child: Text(
            hasData ? '$pct%' : '—',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: hasData ? color : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
