// lib/features/student/quiz/presentation/screens/quiz_play_screen.dart
// So'zona — Quiz o'ynash ekrani
// ✅ v3.0: Widget signature'lar to'g'rilandi (McqWidget, TrueFalseWidget, FillBlankWidget)
// ✅ v3.0: O'qituvchi quizlari uchun har bir savolga 30 soniya countdown
// ✅ v3.0: Vaqt tugaganda savol avtomatik o'tadi

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/widgets/app_button.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/presentation/providers/quiz_provider.dart';
import 'package:my_first_app/features/student/quiz/presentation/widgets/quiz_progress_bar.dart';
import 'package:my_first_app/features/student/quiz/presentation/widgets/mcq_widget.dart';
import 'package:my_first_app/features/student/quiz/presentation/widgets/true_false_widget.dart';
import 'package:my_first_app/features/student/quiz/presentation/widgets/fill_blank_widget.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen>
    with SingleTickerProviderStateMixin {
  // ─── Global timer (jami vaqt) ───
  Timer? _globalTimer;

  // ─── Per-question countdown (o'qituvchi quizlari) ───
  Timer? _questionTimer;
  int _questionSecondsLeft = 30;
  bool _isTeacherQuiz = false;
  static const int _questionTimeLimit = 30;

  late AnimationController _timerAnim;

  // ─── Savol holati ───
  String? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _timerAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _questionTimeLimit),
    );
    _startGlobalTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quiz = ref.read(quizProvider).activeQuiz;
      if (quiz != null) {
        _isTeacherQuiz = quiz.creatorType == 'teacher';
        if (_isTeacherQuiz) _startQuestionTimer();
      }
    });
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(quizProvider.notifier).tickSecond();
    });
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    setState(() => _questionSecondsLeft = _questionTimeLimit);
    _timerAnim.reset();
    _timerAnim.forward();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _questionSecondsLeft--);
      if (_questionSecondsLeft <= 0) {
        _questionTimer?.cancel();
        _onTimeExpired();
      }
    });
  }

  void _stopQuestionTimer() {
    _questionTimer?.cancel();
    _timerAnim.stop();
  }

  void _onTimeExpired() {
    if (_answered) return;
    final q = ref.read(quizProvider).currentQuestion;
    if (q == null) return;
    setState(() {
      _answered = true;
      _selectedAnswer = null;
    });
    ref.read(quizProvider.notifier).answerQuestion(q.id, '');
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _onNext();
    });
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _questionTimer?.cancel();
    _timerAnim.dispose();
    super.dispose();
  }

  void _onAnswer(String answer) {
    if (_answered) return;
    _stopQuestionTimer();
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });
    final q = ref.read(quizProvider).currentQuestion;
    if (q == null) return;
    ref.read(quizProvider.notifier).answerQuestion(q.id, answer);
  }

  void _onNext() {
    final state = ref.read(quizProvider);
    setState(() {
      _selectedAnswer = null;
      _answered = false;
    });
    if (state.isLastQuestion) {
      _submit();
    } else {
      ref.read(quizProvider.notifier).nextQuestion();
      if (_isTeacherQuiz) _startQuestionTimer();
    }
  }

  Future<void> _submit() async {
    _globalTimer?.cancel();
    _questionTimer?.cancel();
    _timerAnim.stop();
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    await ref.read(quizProvider.notifier).submitQuiz(userId: user.id);
    if (!mounted) return;
    context.pushReplacement(RoutePaths.quizResult);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);
    final quiz = state.activeQuiz;
    final question = state.currentQuestion;

    if (quiz == null || question == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Quiz topilmadi'),
              const SizedBox(height: 16),
              AppButton(label: 'Orqaga', onPressed: () => context.pop()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${state.secondsElapsed ~/ 60}:${(state.secondsElapsed % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          QuizProgressBar(
            current: state.currentQuestionIndex + 1,
            total: quiz.questions.length,
          ),

          // O'qituvchi quizi: 30s countdown
          if (_isTeacherQuiz) _buildCountdownBar(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Savol raqami
                  Row(
                    children: [
                      Text(
                        'Savol ${state.currentQuestionIndex + 1} / ${quiz.questions.length}',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const Spacer(),
                      if (quiz.creatorType == 'teacher')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "O'qituvchi",
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Savol matni
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ✅ To'g'rilangan widget chaqiruvlari
                  _buildQuestionWidget(question),

                  const SizedBox(height: 24),

                  // Keyingi tugma (javob berilgandan keyin)
                  if (_answered)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          state.isLastQuestion ? 'Yakunlash' : 'Keyingi',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: Har bir widget o'zining haqiqiy signature'i bilan chaqiriladi
  Widget _buildQuestionWidget(QuizQuestion question) {
    switch (question.type) {
      case QuestionType.mcq:
      case QuestionType.artikel:
        return McqWidget(
          options: question.options,
          selectedAnswer: _selectedAnswer,
          // Javob berilgandan keyin to'g'ri javobni ko'rsatish
          correctAnswer: _answered ? question.correctAnswer : null,
          onAnswer: _onAnswer,
          // ✅ FIX: questionId shuffle uchun — har savol o'z tartibida
          questionId: question.id,
        );

      case QuestionType.trueFalse:
        return TrueFalseWidget(
          selectedAnswer: _selectedAnswer,
          correctAnswer: _answered ? question.correctAnswer : null,
          onAnswer: _onAnswer,
        );

      case QuestionType.fillBlank:
        return FillBlankWidget(
          isAnswered: _answered,
          onAnswer: _onAnswer,
        );
    }
  }

  // ─── 30 soniya countdown widget ───
  Widget _buildCountdownBar() {
    final fraction = _questionSecondsLeft / _questionTimeLimit;
    final isUrgent = _questionSecondsLeft <= 10;
    final color = isUrgent ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.05),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(40, 40),
                  painter:
                      _CircularTimerPainter(fraction: fraction, color: color),
                ),
                Text(
                  '$_questionSecondsLeft',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isUrgent
                      ? 'Shoshiling! Vaqt oz qoldi!'
                      : 'Har bir savolga 30 soniya',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    _globalTimer?.cancel();
    _questionTimer?.cancel();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quizdan chiqish'),
        content:
            const Text('Quiz yakunlanmadi. Chiqsangiz natija saqlanmaydi.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startGlobalTimer();
              if (_isTeacherQuiz) _startQuestionTimer();
            },
            child: const Text('Davom etish'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
  }
}

// ─── Circular Timer Painter ───
class _CircularTimerPainter extends CustomPainter {
  final double fraction;
  final Color color;

  _CircularTimerPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const strokeWidth = 3.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CircularTimerPainter old) =>
      old.fraction != fraction || old.color != color;
}
