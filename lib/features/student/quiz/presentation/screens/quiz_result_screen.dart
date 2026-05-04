// lib/features/student/quiz/presentation/screens/quiz_result_screen.dart
// ✅ 1-KUN FIX: '/student/quiz' → RoutePaths.quiz
// ✅ FIX: AI Murabbiy tugmasi qo'shildi (premium foydalanuvchilar uchun)
// ✅ RESPONSIVE FIX: width/height: 160 → (screenH * 0.20).clamp(120, 170) adaptive

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/widgets/app_button.dart';
import 'package:my_first_app/features/premium/presentation/providers/premium_provider.dart';
import 'package:my_first_app/features/premium/presentation/screens/premium_coach_screen.dart';
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

    // ✅ Adaptive circle: iPhone SE (667px) → 120px, S24 (900px) → 160px
    final screenH = MediaQuery.of(context).size.height;
    final circleSize = (screenH * 0.20).clamp(120.0, 170.0);
    final emojiSize = circleSize * 0.26;
    final pctFontSize = (circleSize * 0.20).clamp(24.0, 34.0);

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
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          children: [
            // ✅ Adaptive circle
            Container(
              width: circleSize,
              height: circleSize,
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
                  Text(emoji, style: TextStyle(fontSize: emojiSize)),
                  Text(
                    '${pct.round()}%',
                    style: TextStyle(
                      fontSize: pctFontSize,
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
            // ✅ Premium AI Murabbiy tugmasi
            if (ref.watch(hasPremiumProvider)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PremiumCoachScreen(
                        trigger: 'after_lesson',
                        skillType: 'quiz',
                        lastScore: attempt.percentage,
                        sessionData: {
                          'topic': attempt.quizTitle,
                          'totalQuestions': attempt.answers.length,
                          'correctCount':
                              attempt.answers.where((a) => a.isCorrect).length,
                          'wrongCount':
                              attempt.answers.where((a) => !a.isCorrect).length,
                          'wrongAnswers': attempt.wrongAnswers
                              .map((a) => {
                                    'question': a
                                        .questionText, // ✅ FIX: ID emas, savol matni
                                    'userAnswer': a.userAnswer,
                                    'correctAnswer': a.correctAnswer,
                                  })
                              .toList(),
                        },
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.workspace_premium,
                    color: Color(0xFFFFD700),
                    size: 18,
                  ),
                  label: const Text(
                    'AI Murabbiy tahlili',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side:
                        const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
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
