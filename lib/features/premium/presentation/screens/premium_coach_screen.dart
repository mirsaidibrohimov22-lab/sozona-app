// lib/features/premium/presentation/screens/premium_coach_screen.dart
// So'zona — Premium AI Murabbiy natija ekrani
// ✅ FIX: Mashqlar uchun "Boshlash" tugmasi qo'shildi
// ✅ YANGI: Kitoblar tugmasi qo'shildi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/premium/presentation/providers/premium_provider.dart';

class PremiumCoachScreen extends ConsumerStatefulWidget {
  final String trigger;
  final String? skillType;
  final double? lastScore;
  final Map<String, dynamic>? sessionData; // ✅ YANGI

  const PremiumCoachScreen({
    super.key,
    this.trigger = 'after_lesson',
    this.skillType,
    this.lastScore,
    this.sessionData,
  });

  @override
  ConsumerState<PremiumCoachScreen> createState() => _PremiumCoachScreenState();
}

class _PremiumCoachScreenState extends ConsumerState<PremiumCoachScreen> {
  bool _isSimpleMode = false; // ✅ Sodda rejim holati
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdvice();
    });
  }

  void _loadAdvice() {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    ref.read(premiumCoachProvider.notifier).getAdvice(
          studentName: user.displayName,
          language: user.learningLanguage.name,
          level: user.level.name.toUpperCase(),
          trigger: widget.trigger,
          skillType: widget.skillType,
          lastScore: widget.lastScore,
          dailyGoalMinutes: user.dailyGoalMinutes,
          sessionData: widget.sessionData, // ✅ YANGI
        );
  }

  @override
  Widget build(BuildContext context) {
    final coachState = ref.watch(premiumCoachProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 20),
            SizedBox(width: 8),
            Text(
              'AI Murabbiy',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: coachState.isLoading
            ? _buildLoading()
            : coachState.error != null
                ? _buildError(coachState.error!)
                : coachState.result != null
                    ? _buildResult(coachState.result!)
                    : _buildLoading(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'AI Murabbiy tahlil qilmoqda...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Zaif nuqtalarni aniqlab, reja tuzmoqda',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40), fontSize: 13),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
            color: Color(0xFFFFD700),
            strokeWidth: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _loadAdvice,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
              ),
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(PremiumCoachResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shaxsiy tahlil
          _GradientCard(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Shaxsiy Tahlil',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  result.personalAnalysis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Motivatsiya
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
              color: const Color(0xFFFFD700).withValues(alpha: 0.06),
            ),
            child: Row(
              children: [
                const Text('💪', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.motivation,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Zaif nuqtalar
          const _SectionTitle(
              title: '⚠️ Zaif nuqtalar', subtitle: 'E\'tibor bering'),
          const SizedBox(height: 12),
          ...result.weakPoints.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 24),

          // ✅ YANGI: Noto'g'ri javoblar tushuntirishi
          if (result.wrongAnswerExplanations.isNotEmpty)
            _buildWrongAnswerExplanations(result.wrongAnswerExplanations),

          const SizedBox(height: 24),

          // Ilmiy usul
          const _SectionTitle(
              title: '🎓 Ilmiy Usul',
              subtitle: 'Tan olingan tadqiqotlarga asosan'),
          const SizedBox(height: 12),
          _GradientCard(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withValues(alpha: 0.15),
                AppColors.secondary.withValues(alpha: 0.05),
              ],
            ),
            child: Text(
              result.scientificMethod,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ),

          const SizedBox(height: 24),

          // Tavsiya etilgan mashqlar
          const _SectionTitle(
              title: '📚 Tavsiya etilgan mashqlar', subtitle: ''),
          const SizedBox(height: 12),
          ...result.exercises.map((ex) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExerciseCard(exercise: ex),
              )),

          const SizedBox(height: 24),

          // Haftalik reja
          const _SectionTitle(title: '📅 Bu hafta uchun reja', subtitle: ''),
          const SizedBox(height: 12),
          _GradientCard(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0.05),
              ],
            ),
            child: Text(
              result.weeklyPlan,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.6),
            ),
          ),

          const SizedBox(height: 24),

          // ✅ YANGI: Kitoblar tugmasi
          GestureDetector(
            onTap: () => context.push(RoutePaths.books),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.08),
                    const Color(0xFFFFA500).withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.auto_stories,
                      color: Color(0xFFFFD700),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Kitoblar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'A1–C1 kitoblari — Grammar, Dialog, Mashqlar',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFFFD700),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Yopish tugmasi
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Mashq qilishni davom ettirish',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ✅ YANGI: Noto'g'ri javoblar tushuntirishi
  Widget _buildWrongAnswerExplanations(
      List<WrongAnswerExplanation> explanations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sarlavha + Sodda rejim toggle
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                title: '❌ Xatolar tahlili',
                subtitle: 'O\'qituvchi tushuntirishi',
              ),
            ),
            // Sodda rejim tugmasi
            GestureDetector(
              onTap: () => setState(() => _isSimpleMode = !_isSimpleMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _isSimpleMode
                      ? const Color(0xFF4F46E5).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.07),
                  border: Border.all(
                    color: _isSimpleMode
                        ? const Color(0xFF4F46E5)
                        : Colors.white24,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSimpleMode ? Icons.lightbulb : Icons.lightbulb_outline,
                      size: 13,
                      color: _isSimpleMode
                          ? const Color(0xFF818CF8)
                          : Colors.white38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sodda rejim',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isSimpleMode
                            ? const Color(0xFF818CF8)
                            : Colors.white38,
                        fontWeight:
                            _isSimpleMode ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...explanations.asMap().entries.map((e) {
          final idx = e.key;
          final exp = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Savol sarlavhasi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error.withValues(alpha: 0.2),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exp.question.isNotEmpty
                                ? exp.question
                                : 'Savol ${idx + 1}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Javoblar qatori
                        Row(
                          children: [
                            _AnswerChip(
                              label: exp.userAnswer,
                              isCorrect: false,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward,
                                  size: 14, color: Colors.white38),
                            ),
                            _AnswerChip(
                              label: exp.correctAnswer,
                              isCorrect: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (_isSimpleMode) ...[
                          // Sodda rejim
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡 ', style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(
                                  exp.simpleExplanation,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // To'liq o'qituvchi tushuntirishi
                          _ExplanationRow(
                            icon: '❌',
                            label: 'Noto\'g\'ri, chunki:',
                            text: exp.whyWrong,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 10),
                          _ExplanationRow(
                            icon: '✅',
                            label: 'To\'g\'ri javob, chunki:',
                            text: exp.whyCorrect,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ════════════════════════════════════════
// KICHIK YORDAMCHI WIDGETLAR
// ════════════════════════════════════════

class _AnswerChip extends StatelessWidget {
  final String label;
  final bool isCorrect;

  const _AnswerChip({required this.label, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              label.isNotEmpty ? label : '—',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationRow extends StatelessWidget {
  final String icon;
  final String label;
  final String text;
  final Color color;

  const _ExplanationRow({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════

class _GradientCard extends StatelessWidget {
  final Gradient gradient;
  final Widget child;

  const _GradientCard({required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: gradient,
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final PremiumExercise exercise;

  const _ExerciseCard({required this.exercise});

  static const _typeIcons = {
    'flashcard': Icons.style,
    'quiz': Icons.quiz,
    'listening': Icons.headphones,
    'speaking': Icons.mic,
  };

  static const _typeLabels = {
    'flashcard': 'Flashcard',
    'quiz': 'Quiz',
    'listening': 'Listening',
    'speaking': 'Speaking',
  };

  String _routeFor(String type) {
    switch (type) {
      case 'quiz':
        return RoutePaths.quiz;
      case 'listening':
        return RoutePaths.listening;
      case 'speaking':
        return RoutePaths.speaking;
      case 'flashcard':
        return RoutePaths.flashcards;
      default:
        return RoutePaths.studentHome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _typeIcons[exercise.type] ?? Icons.fitness_center;
    final typeLabel = _typeLabels[exercise.type] ?? exercise.type;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          exercise.durationText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.40),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (exercise.source.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '📖 ${exercise.source}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(_routeFor(exercise.type)),
              icon: Icon(icon, size: 15, color: AppColors.primary),
              label: Text(
                '$typeLabel boshlash →',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side:
                    BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
