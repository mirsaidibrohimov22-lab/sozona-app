// ═══════════════════════════════════════════════════════════════
// TO'LIQ FAYL — COPY-PASTE QILING
// PATH: lib/features/student/quiz/presentation/screens/quiz_detail_screen.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/presentation/providers/quiz_provider.dart';
import 'package:my_first_app/core/router/route_names.dart';

class QuizDetailScreen extends ConsumerWidget {
  final String quizId;

  const QuizDetailScreen({
    super.key,
    required this.quizId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(quizRepositoryProvider);

    return Scaffold(
      body: FutureBuilder(
        future: repository.getQuizDetail(quizId),
        builder: (context, snapshot) {
          // ─── Loading ───
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingWidget();
          }

          // ─── Error ───
          if (!snapshot.hasData || snapshot.data == null) {
            return _ErrorView(onBack: () => context.pop());
          }

          return snapshot.data!.fold(
            // ─── Failure ───
            (failure) => _ErrorView(
              message: failure.message,
              onBack: () => context.pop(),
            ),
            // ─── Success ───
            (quiz) => _QuizDetailBody(quiz: quiz),
          );
        },
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────
class _QuizDetailBody extends ConsumerWidget {
  final Quiz quiz;

  const _QuizDetailBody({required this.quiz});

  // ✅ BUG FIX: Eski kod: context.push('/quiz/play/$quizId') — route topilmadi!
  //
  // MUAMMO NIMA EDI:
  //   Router'da faqat '/student/quiz/play' mavjud.
  //   '/quiz/play/abc123' deb push qilganda "Sahifa topilmadi" chiqar edi.
  //   Bundan tashqari QuizPlayScreen state'dan quiz oladi,
  //   lekin state'ga hech nima yuklanmagan edi → "Quiz topilmadi" xatosi.
  //
  // FIX:
  //   1. startQuiz(quiz) — quiz'ni state'ga yozamiz
  //   2. context.push(RoutePaths.quizPlay) — to'g'ri path
  Future<void> _startQuiz(BuildContext context, WidgetRef ref) async {
    // 1. Quiz'ni Riverpod state'ga yuklash
    ref.read(quizProvider.notifier).startQuiz(quiz);

    // 2. To'g'ri route'ga navigate
    if (context.mounted) {
      context.push(RoutePaths.quizPlay);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ───
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                quiz.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.quiz,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),

          // ─── Content ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (quiz.description != null &&
                      quiz.description!.isNotEmpty) ...[
                    Text(
                      quiz.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Ma'lumotlar
                  _InfoCard(
                    icon: Icons.language,
                    title: 'Til',
                    value: quiz.languageLabel,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.speed,
                    title: 'Daraja',
                    value: quiz.difficultyLabel,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.quiz_outlined,
                    title: 'Savollar',
                    value: '${quiz.totalQuestions} ta',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.timer,
                    title: 'Vaqt',
                    value: quiz.timeLimitFormatted,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.grade,
                    title: "O'tish balli",
                    value: '${quiz.passingScore}%',
                  ),
                  const SizedBox(height: 24),

                  // Statistika
                  if (quiz.attemptCount > 0) ...[
                    Text(
                      'Statistika',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              label: 'Urinishlar',
                              value: '${quiz.attemptCount}',
                            ),
                            _StatItem(
                              label: "O'rtacha ball",
                              value: '${quiz.averageScore.toStringAsFixed(0)}%',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Yaratuvchi
                  Text(
                    'Yaratuvchi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: Icon(
                      quiz.isTeacherCreated
                          ? Icons.school
                          : quiz.isStudentQuiz
                              ? Icons.person
                              : Icons.smart_toy,
                      size: 18,
                    ),
                    label: Text(quiz.creatorLabel),
                  ),

                  // Bottom padding
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ─── Boshlash tugmasi ───
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer(
            builder: (context, ref, _) {
              final isLoading = ref.watch(quizProvider).isLoading;
              return ElevatedButton(
                onPressed: isLoading ? null : () => _startQuiz(context, ref),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Boshlash',
                        style: TextStyle(fontSize: 18),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onBack;

  const _ErrorView({this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Quiz yuklanmadi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Orqaga qaytish'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info card ────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─── Stat item ────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
