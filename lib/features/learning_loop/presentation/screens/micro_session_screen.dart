// QO'YISH: lib/features/learning_loop/presentation/screens/micro_session_screen.dart
// So'zona — Mikro-sessiya ekrani (10 daqiqa mashq)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/widgets/app_button.dart';
import 'package:my_first_app/core/widgets/app_error_widget.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/micro_session.dart';
import 'package:my_first_app/features/learning_loop/presentation/providers/learning_loop_provider.dart';
import 'package:my_first_app/features/learning_loop/presentation/widgets/motivation_banner.dart';
import 'package:my_first_app/features/learning_loop/presentation/widgets/session_timer.dart';
import 'package:my_first_app/features/learning_loop/presentation/widgets/session_type_indicator.dart';
import 'package:my_first_app/core/router/route_names.dart';

class MicroSessionScreen extends ConsumerStatefulWidget {
  const MicroSessionScreen({super.key});

  @override
  ConsumerState<MicroSessionScreen> createState() => _MicroSessionScreenState();
}

class _MicroSessionScreenState extends ConsumerState<MicroSessionScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;
  static const int _sessionDurationSeconds = 10 * 60; // 10 daqiqa

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    await ref
        .read(learningLoopProvider.notifier)
        .loadAll(user.id, user.learningLanguage.name);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsElapsed++);

      // 10 daqiqa tugasa avtomatik tugatish
      if (_secondsElapsed >= _sessionDurationSeconds) {
        t.cancel();
        _completeSession();
      }
    });
  }

  Future<void> _startSession() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    await ref.read(learningLoopProvider.notifier).startCurrentSession(user.id);
    _startTimer();
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    // XP hisoblash (vaqtga qarab)
    final xp = (_secondsElapsed / 60 * 10).round().clamp(5, 100);

    await ref.read(learningLoopProvider.notifier).completeCurrentSession(
          userId: user.id,
          overallScore: 75, // Haqiqiy ballni mashqlardan hisoblaymiz
          weakItemsReviewed: 0,
          newWeakItems: 0,
          xpEarned: xp,
        );

    if (!mounted) return;
    _showCompletionDialog(xp);
  }

  void _showCompletionDialog(int xp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(
              'Sessiya tugadi!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '+$xp XP qo\'lga kiritdingiz!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Bosh sahifaga qaytish'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningLoopProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mikro-sessiya'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.currentSession?.isActive == true)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SessionTimer(secondsElapsed: _secondsElapsed),
            ),
        ],
      ),
      body: state.isLoading
          ? const AppLoadingWidget()
          : state.error != null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: _load,
                )
              : _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, LearningLoopState state) {
    final session = state.currentSession;

    if (session == null) {
      return const Center(child: Text('Sessiya topilmadi'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Motivatsiya banneri
          if (state.motivationMessage != null)
            MotivationBanner(message: state.motivationMessage!),

          const SizedBox(height: 20),

          // Sessiya turi
          SessionTypeIndicator(sessionType: session.sessionType),

          const SizedBox(height: 24),

          // Sessiya ma'lumotlari
          _buildSessionInfo(context, session),

          const SizedBox(height: 32),

          // Zaif elementlar
          if (state.dueItems.isNotEmpty) _buildWeakItemsSection(context, state),

          const SizedBox(height: 32),

          // Harakat tugmasi
          _buildActionButton(context, session),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(BuildContext context, MicroSession session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⏱ ${session.durationMinutes} daqiqa sessiya',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              session.sessionType == SessionType.flashcardQuiz
                  ? '📚 Flashcard va Quiz mashqlari'
                  : '🎧 Listening va Speaking mashqlari',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakItemsSection(BuildContext context, LearningLoopState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔄 Qayta ko\'rib chiqish (${state.dueItems.length} ta)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...state.dueItems.take(3).map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.refresh, color: AppColors.warning),
                  title: Text(item.itemData.term),
                  subtitle: item.itemData.translation != null
                      ? Text(item.itemData.translation!)
                      : null,
                  trailing: Text(
                    '${item.masteryScore}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, MicroSession session) {
    if (session.isCompleted) {
      return AppButton(
        label: '✅ Sessiya tugadi',
        onPressed: () => context.pop(),
        type: AppButtonType.outlined,
      );
    }

    if (session.isActive) {
      return Column(
        children: [
          AppButton(
            label: '🏁 Sessiyani tugatish',
            onPressed: _completeSession,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Quiz boshlash',
            onPressed: () => context.push(RoutePaths.quiz),
            type: AppButtonType.outlined,
          ),
        ],
      );
    }

    // scheduled
    return AppButton(
      label: '▶️ Sessiyani boshlash',
      onPressed: _startSession,
    );
  }
}
