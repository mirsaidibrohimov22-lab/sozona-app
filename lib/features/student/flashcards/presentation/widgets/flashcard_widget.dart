// lib/features/student/flashcards/presentation/widgets/flashcard_widget.dart
// So'zona — Flashcard flip widget
// ✅ RESPONSIVE FIX:
//   - height: 260 (fixed) → (screenH * 0.30).clamp(200, 300) (adaptive)
//   - FittedBox qo'shildi — uzun so'zlar kichrayib sig'adi
//   - height parent dan o'tkazildi — rebuild minimal

import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';

/// Flashcard widget — old va orqa tomonni ko'rsatadi
class FlashcardWidget extends StatelessWidget {
  final FlashcardEntity card;
  final bool isFlipped;
  final VoidCallback onTap;

  const FlashcardWidget({
    super.key,
    required this.card,
    required this.isFlipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Adaptive height: iPhone SE (667px) → 200px, S24 (900px) → 270px
    final cardHeight =
        (MediaQuery.of(context).size.height * 0.30).clamp(200.0, 300.0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) =>
            RotationYTransition(turns: anim, child: child),
        child: isFlipped
            ? _Back(
                card: card,
                cardHeight: cardHeight,
                key: const ValueKey('back'),
              )
            : _Front(
                card: card,
                cardHeight: cardHeight,
                key: const ValueKey('front'),
              ),
      ),
    );
  }
}

/// Old tomon — o'rganiladigan so'z
class _Front extends StatelessWidget {
  final FlashcardEntity card;
  final double cardHeight;

  const _Front({super.key, required this.card, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ FittedBox — uzun so'z kichrayib sig'adi, overflow yo'q
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                card.front,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (card.pronunciation != null) ...[
              const SizedBox(height: 8),
              Text(
                '[${card.pronunciation}]',
                style: const TextStyle(fontSize: 15, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              "Bosib teskari tomonni ko'ring",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Orqa tomon — tarjima va misol
class _Back extends StatelessWidget {
  final FlashcardEntity card;
  final double cardHeight;

  const _Back({super.key, required this.card, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ FittedBox — uzun tarjima sig'adi
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                card.back,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (card.example != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                card.example!,
                textAlign: TextAlign.center,
                // ✅ maxLines + ellipsis — uzun misol sig'adi
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Y o'qi bo'yicha aylanish animatsiyasi
class RotationYTransition extends AnimatedWidget {
  final Widget child;

  const RotationYTransition({
    super.key,
    required Animation<double> turns,
    required this.child,
  }) : super(listenable: turns);

  @override
  Widget build(BuildContext context) {
    final anim = listenable as Animation<double>;
    return Transform(
      transform: Matrix4.rotationY((1 - anim.value) * 3.14159),
      alignment: Alignment.center,
      child: child,
    );
  }
}
