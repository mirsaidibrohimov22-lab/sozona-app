// lib/features/student/flashcards/presentation/widgets/flashcard_widget.dart
// So'zona — Flashcard flip widget
import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';

/// Flashcard widget — old va orqa tomonni ko'rsatadi
class FlashcardWidget extends StatelessWidget {
  /// Kartochka ma'lumotlari
  final FlashcardEntity card;

  /// Kartochka ag'darilganmi?
  final bool isFlipped;

  /// Bosilganda chaqiriladigan funksiya
  final VoidCallback onTap;

  const FlashcardWidget({
    super.key,
    required this.card,
    required this.isFlipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) =>
            RotationYTransition(turns: anim, child: child),
        child: isFlipped
            ? _Back(card: card, key: const ValueKey('back'))
            : _Front(card: card, key: const ValueKey('front')),
      ),
    );
  }
}

/// Old tomon — o'rganiladigan so'z
class _Front extends StatelessWidget {
  final FlashcardEntity card;
  const _Front({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.front,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (card.pronunciation != null) ...[
            const SizedBox(height: 8),
            Text(
              '[${card.pronunciation}]',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Bosib teskari tomonni ko\'ring',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Orqa tomon — tarjima va misol
class _Back extends StatelessWidget {
  final FlashcardEntity card;
  const _Back({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
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
            Text(
              card.back,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (card.example != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                card.example!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
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
