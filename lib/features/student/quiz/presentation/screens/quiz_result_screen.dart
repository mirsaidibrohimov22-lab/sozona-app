// lib/features/student/quiz/presentation/screens/quiz_result_screen.dart
// So'zona — Quiz natijasi ekrani
// ✅ 1-KUN FIX: '/student/quiz' → RoutePaths.quiz

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/widgets/app_button.dart';
import 'package:my_first_app/features/student/quiz/presentation/providers/quiz_provider.dart';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempt = ref.watch(quizProvider).lastAttempt;

    if (attempt == null) {
      return Scaffold(
        body: Center(
          child: AppButton(
            label: 'Quizlarga qaytish',
            onPressed: () => context.go(RoutePaths.quiz),
          ),
        ),
      );
    }

    final pct = attempt.percentage;
    final passed = attempt.passed;
    final emoji = pct >= 90
        ? '🏆'
        : pct >= 70
            ? '🌟'
            : pct >= 60
                ? '✅'
                : '💪';
    final message = pct >= 90
        ? 'Mukammal!'
        : pct >= 70
            ? 'Juda yaxshi!'
            : pct >= 60
                ? "O'tdingiz!"
                : 'Harakat qiling!';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Natija'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (passed ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.1),
                border: Border.all(
                  color: passed ? AppColors.success : AppColors.error,
                  width: 4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  Text(
                    '${pct.round()}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: passed ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${attempt.score} / ${attempt.maxScore} ball',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _StatRow(
              icon: Icons.check_circle,
              label: "To'g'ri",
              value: '${attempt.answers.where((a) => a.isCorrect).length} ta',
              color: AppColors.success,
            ),
            _StatRow(
              icon: Icons.cancel,
              label: "Noto'g'ri",
              value: '${attempt.answers.where((a) => !a.isCorrect).length} ta',
              color: AppColors.error,
            ),
            _StatRow(
              icon: Icons.timer,
              label: 'Vaqt',
              value:
                  '${attempt.timeSpentSeconds ~/ 60}m ${attempt.timeSpentSeconds % 60}s',
              color: AppColors.primary,
            ),
            _StatRow(
              icon: Icons.bolt,
              label: 'XP',
              value: '+${attempt.xpEarned}',
              color: Colors.orange,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: '🔄 Qayta urinish',
              onPressed: () => context.pop(),
              type: AppButtonType.outlined,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Quizlarga qaytish',
              onPressed: () => context.go(RoutePaths.quiz),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
