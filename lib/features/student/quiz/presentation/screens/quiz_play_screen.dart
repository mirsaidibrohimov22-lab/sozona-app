// lib/features/student/quiz/presentation/screens/quiz_play_screen.dart
// So'zona — Quiz o'ynash ekrani (yangi dizayn)
// ✅ v3.0: Widget signature'lar to'g'rilandi
// ✅ v3.0: O'qituvchi quizlari uchun 30s countdown

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/widgets/app_button.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/presentation/providers/quiz_provider.dart';
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
  Timer? _globalTimer;
  Timer? _questionTimer;
  int _questionSecondsLeft = 30;
  bool _isTeacherQuiz = false;
  static const int _questionTimeLimit = 30;

  late AnimationController _timerAnim;

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

    // ✅ FIX: Natija kechikmasligi uchun — submitQuiz ni kutib,
    // xato bo'lsa ham result ekraniga o'tamiz (lastAttempt null bo'lsa
    // result ekrani "Quizlarga qaytish" tugmasini ko'rsatadi)
    await ref.read(quizProvider.notifier).submitQuiz(userId: user.id);
    if (!mounted) return;

    // ✅ FIX: Natija chiqmasligi — agar submit xato bo'lsa,
    // lokal attempt yaratib, result ekranini ko'rsatamiz
    final state = ref.read(quizProvider);
    if (state.lastAttempt == null && state.activeQuiz != null) {
      // Server xatosi — lokal hisoblash
      ref.read(quizProvider.notifier).computeLocalResult(userId: user.id);
    }

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

    final progressFraction =
        (state.currentQuestionIndex + 1) / quiz.questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      body: Column(
        children: [
          // ── Gradient header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4A42D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    // Top row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showExitDialog(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            quiz.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Timer
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${state.secondsElapsed ~/ 60}:${(state.secondsElapsed % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Progress bar
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Savol ${state.currentQuestionIndex + 1}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '${quiz.questions.length} ta',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progressFraction,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF2DD4BF)),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // O'qituvchi quizi countdown
          if (_isTeacherQuiz) _buildCountdownBar(),

          // ── Savol ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // O'qituvchi badge
                  if (quiz.creatorType == 'teacher')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4FC3F7), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "O'qituvchi quizi",
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),

                  // Savol kartasi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF6C63FF).withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                          color: const Color(0xFFEEEDFF), width: 1.5),
                    ),
                    child: Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: Color(0xFF1A1D2E),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Javob widgeti
                  _buildQuestionWidget(question),

                  const SizedBox(height: 24),

                  // Keyingi tugma
                  if (_answered)
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4A42D6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6C63FF).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          state.isLastQuestion ? '🏆 Yakunlash' : 'Keyingi →',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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

  Widget _buildQuestionWidget(QuizQuestion question) {
    switch (question.type) {
      case QuestionType.mcq:
      case QuestionType.artikel:
        return McqWidget(
          options: question.options,
          selectedAnswer: _selectedAnswer,
          correctAnswer: _answered ? question.correctAnswer : null,
          onAnswer: _onAnswer,
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

  Widget _buildCountdownBar() {
    final fraction = _questionSecondsLeft / _questionTimeLimit;
    final isUrgent = _questionSecondsLeft <= 10;
    final color = isUrgent ? const Color(0xFFFF5252) : const Color(0xFFFFB347);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.06),
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
