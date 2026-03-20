// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Listening Play Screen
// QO'YISH: lib/features/student/listening/presentation/screens/listening_play_screen.dart
//
// ✅ FIX v2.0: Abadiy loading spinner muammosi hal qilindi
// ✅ v3.0: ListeningLoadingWidget + showListeningSuccess qo'shildi
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/widgets/sozana_loading_animation.dart';
import 'package:my_first_app/core/widgets/sozana_success_animation.dart';
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
  int _lastAutoNextIndex = -1;

  @override
  Widget build(BuildContext context) {
    final exerciseAsync = ref.watch(
      listeningDetailProvider(widget.exerciseId),
    );
    final playState = ref.watch(listeningPlayProvider);

    return exerciseAsync.when(
      loading: () => Scaffold(
        body: const ListeningLoadingWidget(),
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
        // Audio position bo'yicha savol avtomatik o'tishi
        if (playState != null && exercise.questions.isNotEmpty) {
          final posSeconds = playState.currentPosition.inSeconds;
          final currentIdx = playState.currentQuestionIndex;
          final nextIdx = currentIdx + 1;

          if (nextIdx < exercise.questions.length) {
            final nextQ = exercise.questions[nextIdx];
            final nextTs = nextQ.timestamp;

            if (nextTs != null &&
                posSeconds >= nextTs &&
                _lastAutoNextIndex != nextIdx) {
              _lastAutoNextIndex = nextIdx;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.read(listeningPlayProvider.notifier).nextQuestion();
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
          return Scaffold(
            body: const ListeningLoadingWidget(),
          );
        }

        if (playState == null) {
          return Scaffold(
            body: const ListeningLoadingWidget(),
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
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savol ${safeIndex + 1}/${exercise.questions.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
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
                            if (safeIndex < exercise.questions.length - 1) {
                              ref
                                  .read(listeningPlayProvider.notifier)
                                  .nextQuestion();
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

  Future<void> _finishListening() async {
    final result =
        await ref.read(listeningPlayProvider.notifier).submitAnswers();
    if (result != null && mounted) {
      final correctCount =
          result is Map ? ((result['correctCount'] ?? 0) as num).toInt() : 0;
      final totalCount =
          result is Map ? ((result['totalCount'] ?? 0) as num).toInt() : 0;

      showListeningSuccess(
        context,
        score: correctCount,
        total: totalCount,
        onContinue: () => context.go(RoutePaths.listening),
      );
    }
  }
}
