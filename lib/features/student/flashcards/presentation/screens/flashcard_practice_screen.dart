// lib/features/student/flashcards/presentation/screens/flashcard_practice_screen.dart
// So'zona — Flashcard mashq ekrani
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart'; // ✅ FIX
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/flashcards/presentation/providers/flashcard_provider.dart';
import 'package:my_first_app/features/student/flashcards/presentation/widgets/flashcard_widget.dart';
import 'package:my_first_app/features/student/flashcards/presentation/widgets/tts_button.dart';

/// Flashcard mashq ekrani — kartochkalarni takrorlash
class FlashcardPracticeScreen extends ConsumerStatefulWidget {
  final String setId;
  const FlashcardPracticeScreen({super.key, required this.setId});

  @override
  ConsumerState<FlashcardPracticeScreen> createState() =>
      _FlashcardPracticeScreenState();
}

class _FlashcardPracticeScreenState
    extends ConsumerState<FlashcardPracticeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authNotifierProvider).user?.id ?? '';
      ref.read(flashcardProvider.notifier).loadCards(widget.setId, uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashcardProvider);
    final user = ref.watch(authNotifierProvider).user;
    final uid = user?.id ?? '';
    // ✅ FIX: user profildan to'g'ri locale — 'de-DE' yoki 'en-US'
    final ttsLocale =
        user?.learningLanguage == LearningLanguage.german ? 'de-DE' : 'en-US';

    // Yuklanmoqda
    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Sessiya tugadi
    if (state.isSessionDone) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              const Text(
                'Sessiya tugadi!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.cards.length} ta karta ko\'rib chiqildi',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => ref
                    .read(flashcardProvider.notifier)
                    .loadCards(widget.setId, uid),
                child: const Text('Qayta boshlash'),
              ),
            ],
          ),
        ),
      );
    }

    // Hozirgi kartochka
    final card = state.currentCard;
    if (card == null) {
      return const Scaffold(
        body: Center(child: Text('Karta topilmadi')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${state.currentIndex + 1} / ${state.cards.length}'),
        actions: [
          TtsButton(text: card.front, language: ttsLocale),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: state.currentIndex / state.cards.length,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),

            // Flashcard
            FlashcardWidget(
              card: card,
              isFlipped: state.isFlipped,
              onTap: () => ref.read(flashcardProvider.notifier).flip(),
            ),
            const SizedBox(height: 24),

            // Baholash tugmalari
            if (state.isFlipped) ...[
              const Text(
                'Qanchalik yaxshi bildingiz?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RateButton(
                      label: '😓 Bilmadim',
                      color: Colors.red,
                      score: 0.0,
                      uid: uid,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RateButton(
                      label: '🤔 Qiyin',
                      color: Colors.orange,
                      score: 0.5,
                      uid: uid,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RateButton(
                      label: '😊 Yaxshi',
                      color: AppColors.success,
                      score: 1.0,
                      uid: uid,
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                'Bosib teskari tomonni ko\'ring',
                style: TextStyle(color: Colors.grey.shade500),
              ),
          ],
        ),
      ),
    );
  }
}

/// Baholash tugmasi
class _RateButton extends ConsumerWidget {
  final String label;
  final Color color;
  final double score;
  final String uid;

  const _RateButton({
    required this.label,
    required this.color,
    required this.score,
    required this.uid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => ref.read(flashcardProvider.notifier).rate(uid, score),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
