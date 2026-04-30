// lib/features/student/listening/presentation/screens/listening_play_screen.dart
// ✅ FIX v4.0: Savollar bug tuzatildi (timestamp=0 bo'lsa skip qilmaslik)
// ✅ YANGI: Savol tugaganda audio 20 sekund to'xtaydi, javob kutadi
// ✅ FIX: AI Murabbiy tugmasi Listening natijasida ham ko'rinadi

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/widgets/sozana_loading_animation.dart';
import 'package:my_first_app/core/widgets/sozana_success_animation.dart';
import 'package:my_first_app/features/premium/presentation/providers/premium_provider.dart';
import 'package:my_first_app/features/premium/presentation/screens/premium_coach_screen.dart';
import 'package:my_first_app/features/student/listening/presentation/providers/listening_provider.dart';
import 'package:my_first_app/features/student/listening/presentation/widgets/audio_player_widget.dart';
import 'package:my_first_app/features/student/listening/presentation/widgets/transcript_widget.dart';
import 'package:my_first_app/features/student/listening/presentation/widgets/listening_question_widget.dart';

class ListeningPlayScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const ListeningPlayScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  ConsumerState<ListeningPlayScreen> createState() =>
      _ListeningPlayScreenState();
}

class _ListeningPlayScreenState extends ConsumerState<ListeningPlayScreen> {
  bool _listeningStarted = false;

  // ✅ FIX: Faqat timestamp > 0 bo'lganda auto-next ishlaydi
  int _lastAutoNextIndex = -1;

  // ✅ YANGI: 20 sekund kutish mexanizmi
  Timer? _answerTimer;
  int _answerSecondsLeft = 20;
  bool _isPaused = false; // audio to'xtatilganmi
  bool _waitingForAnswer = false; // javob kutilmoqdami

  @override
  void dispose() {
    _answerTimer?.cancel();
    super.dispose();
  }

  // ✅ YANGI: Audio to'xtatib 20 sekund countdown boshlash
  void _startAnswerCountdown() {
    if (!mounted) return;
    _answerTimer?.cancel();
    setState(() {
      _waitingForAnswer = true;
      _answerSecondsLeft = 20;
      _isPaused = true;
    });

    // Audiong to'xtatish
    final notifier = ref.read(listeningPlayProvider.notifier);
    final state = ref.read(listeningPlayProvider);
    if (state != null && state.isPlaying) {
      notifier.togglePlay();
    }

    // 20 sekund countdown
    _answerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _answerSecondsLeft--);
      if (_answerSecondsLeft <= 0) {
        timer.cancel();
        _onAnswerTimeExpired();
      }
    });
  }

  // Vaqt tugaganda keyingi savolga o'tish
  void _onAnswerTimeExpired() {
    if (!mounted) return;
    setState(() {
      _waitingForAnswer = false;
      _isPaused = false;
    });
    final state = ref.read(listeningPlayProvider);
    if (state == null) return;
    final notifier = ref.read(listeningPlayProvider.notifier);

    // Savollar tugamagan bo'lsa keyingisiga o'tish
    if (state.currentQuestionIndex < state.exercise.questions.length - 1) {
      notifier.nextQuestion();
      // Audiong davom ettirish
      if (!state.isPlaying) notifier.togglePlay();
    }
  }

  // O'quvchi javob berdi → countdown bekor, keyingisiga o'tish mumkin
  void _onAnswered() {
    _answerTimer?.cancel();
    setState(() {
      _waitingForAnswer = false;
      _answerSecondsLeft = 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exerciseAsync = ref.watch(
      listeningDetailProvider(widget.exerciseId),
    );
    final playState = ref.watch(listeningPlayProvider);

    return exerciseAsync.when(
      loading: () => const Scaffold(
        body: ListeningLoadingWidget(),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Xatolik yuz berdi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Orqaga'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (exercise) {
        // ✅ FIX: Faqat timestamp > 0 bo'lganda auto-next
        if (playState != null &&
            exercise.questions.isNotEmpty &&
            !_waitingForAnswer) {
          final posSeconds = playState.currentPosition.inSeconds;
          final currentIdx = playState.currentQuestionIndex;
          final nextIdx = currentIdx + 1;

          if (nextIdx < exercise.questions.length) {
            final nextQ = exercise.questions[nextIdx];
            final nextTs = nextQ.timestamp;

            // ✅ BUG FIX: nextTs > 0 bo'lgandagina ishlaydi (0 yoki null bo'lsa skip emas)
            if (nextTs != null &&
                nextTs > 0 &&
                posSeconds >= nextTs &&
                _lastAutoNextIndex != nextIdx) {
              _lastAutoNextIndex = nextIdx;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  // ✅ YANGI: Auto-next oldidan 20 sekund kutish
                  _startAnswerCountdown();
                }
              });
            }
          }
        }

        // Ma'lumot keldi, lekin playState hali null → startListening
        if (playState == null && !_listeningStarted) {
          _listeningStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(listeningPlayProvider.notifier).startListening(exercise);
            }
          });
          return const Scaffold(
            body: ListeningLoadingWidget(),
          );
        }

        if (playState == null) {
          return const Scaffold(
            body: ListeningLoadingWidget(),
          );
        }

        if (exercise.questions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(exercise.title)),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Bu mashqda hali savollar yo\'q',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        }

        final safeIndex = playState.currentQuestionIndex
            .clamp(0, exercise.questions.length - 1);
        final currentQuestion = exercise.questions[safeIndex];

        return Scaffold(
          appBar: AppBar(
            title: Text(exercise.title),
            actions: [
              IconButton(
                icon: Icon(
                  playState.showTranscript
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  ref.read(listeningPlayProvider.notifier).toggleTranscript();
                },
                tooltip: 'Transkript',
              ),
            ],
          ),
          body: Column(
            children: [
              AudioPlayerWidget(
                audioUrl: exercise.audioUrl,
                transcript: exercise.transcript,
                language: exercise.language,
                isPlaying: playState.isPlaying,
                currentPosition: playState.currentPosition,
                totalDuration: playState.totalDuration,
                seekToPosition: playState.seekToPosition,
                // ✅ FIX: audioUrl bo'sh bo'lsa premium ovoz ishlatiladi
                useOpenAiTts:
                    exercise.audioUrl.isEmpty && ref.watch(hasPremiumProvider),
                onPlayPause: () {
                  ref.read(listeningPlayProvider.notifier).togglePlay();
                },
                onSeek: (position) {
                  if (mounted) {
                    ref
                        .read(listeningPlayProvider.notifier)
                        .updatePosition(position);
                  }
                },
                onSeekDone: () {
                  if (mounted) {
                    ref.read(listeningPlayProvider.notifier).clearSeek();
                  }
                },
              ),

              if (playState.showTranscript)
                TranscriptWidget(
                  transcript: exercise.transcript,
                  currentPosition: playState.currentPosition.inSeconds,
                ),

              // ✅ YANGI: 20 sekund countdown banner
              if (_waitingForAnswer)
                _buildAnswerCountdown(context, playState, safeIndex, exercise),

              const Divider(height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Savol ${safeIndex + 1}/${exercise.questions.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // Progress dots
                          Row(
                            children: List.generate(
                              exercise.questions.length,
                              (i) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == safeIndex
                                      ? AppColors.primary
                                      : playState.userAnswers.containsKey(
                                              exercise.questions[i].id)
                                          ? AppColors.success
                                          : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListeningQuestionWidget(
                        question: currentQuestion,
                        selectedAnswer:
                            playState.userAnswers[currentQuestion.id],
                        onAnswerSelected: (answer) {
                          ref
                              .read(listeningPlayProvider.notifier)
                              .answerQuestion(currentQuestion.id, answer);
                          // ✅ Javob berildi → countdown bekor
                          if (_waitingForAnswer) _onAnswered();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (safeIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _answerTimer?.cancel();
                              setState(() => _waitingForAnswer = false);
                              ref
                                  .read(listeningPlayProvider.notifier)
                                  .previousQuestion();
                            },
                            child: const Text('Oldingi'),
                          ),
                        ),
                      if (safeIndex > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            _answerTimer?.cancel();
                            setState(() => _waitingForAnswer = false);
                            if (safeIndex < exercise.questions.length - 1) {
                              ref
                                  .read(listeningPlayProvider.notifier)
                                  .nextQuestion();
                              // Audio davom ettirish
                              if (!playState.isPlaying) {
                                ref
                                    .read(listeningPlayProvider.notifier)
                                    .togglePlay();
                              }
                            } else {
                              _finishListening();
                            }
                          },
                          child: Text(
                            safeIndex < exercise.questions.length - 1
                                ? 'Keyingi'
                                : 'Yakunlash',
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
      },
    );
  }

  // ✅ YANGI: 20 sekund countdown widget
  Widget _buildAnswerCountdown(
    BuildContext context,
    ListeningPlayState playState,
    int safeIndex,
    dynamic exercise,
  ) {
    final fraction = _answerSecondsLeft / 20.0;
    final isUrgent = _answerSecondsLeft <= 5;
    final color = isUrgent ? AppColors.error : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.08),
      child: Row(
        children: [
          // Circular countdown
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: fraction,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 3,
                ),
                Text(
                  '$_answerSecondsLeft',
                  style: TextStyle(
                    fontSize: 13,
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
                  isUrgent ? 'Tez javob bering!' : 'Javobni belgilang',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  '$_answerSecondsLeft sekund qoldi',
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Skip tugmasi
          TextButton(
            onPressed: () {
              _answerTimer?.cancel();
              setState(() => _waitingForAnswer = false);
              if (safeIndex < exercise.questions.length - 1) {
                ref.read(listeningPlayProvider.notifier).nextQuestion();
                if (!playState.isPlaying) {
                  ref.read(listeningPlayProvider.notifier).togglePlay();
                }
              }
            },
            child: Text(
              'O\'tkazish',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishListening() async {
    _answerTimer?.cancel();
    final result =
        await ref.read(listeningPlayProvider.notifier).submitAnswers();
    if (result != null && mounted) {
      final correctCount = ((result['correctCount'] ?? 0) as num).toInt();
      final totalCount = ((result['totalCount'] ?? 0) as num).toInt();
      final hasPremium = ref.read(hasPremiumProvider);
      // ✅ YANGI: Hozirgi sessiya ma'lumotlari
      final playState = ref.read(listeningPlayProvider);
      final exerciseTopic = playState?.exercise.topic ?? '';
      final exerciseTitle = playState?.exercise.title ?? '';
      final missedWords =
          (result['missedWords'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[];

      showListeningSuccess(
        context,
        score: correctCount,
        total: totalCount,
        onContinue: () => context.go(RoutePaths.listening),
        onPremiumCoach: hasPremium
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PremiumCoachScreen(
                      trigger: 'after_lesson',
                      skillType: 'listening',
                      lastScore: totalCount > 0
                          ? (correctCount / totalCount * 100)
                          : 0,
                      // ✅ YANGI: Haqiqiy sessiya ma'lumotlari
                      sessionData: {
                        'topic': exerciseTitle.isNotEmpty
                            ? exerciseTitle
                            : exerciseTopic,
                        'totalQuestions': totalCount,
                        'correctCount': correctCount,
                        'wrongCount': totalCount - correctCount,
                        if (missedWords.isNotEmpty) 'missedWords': missedWords,
                      },
                    ),
                  ),
                )
            : null,
      );
    }
  }
}
