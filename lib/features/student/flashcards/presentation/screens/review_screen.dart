// lib/features/flashcard/presentation/screens/review_screen.dart
// So'zona — Kartochka takrorlash ekrani
// Flip animatsiya + SM-2 baholash

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/animated_counter.dart';
import 'package:my_first_app/core/widgets/app_badge.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/features/student/flashcards/presentation/providers/flashcard_provider.dart';
import 'package:my_first_app/features/student/flashcards/presentation/widgets/review_result_widget.dart';

/// Kartochka takrorlash ekrani
class ReviewScreen extends ConsumerStatefulWidget {
  final String folderId;

  const ReviewScreen({super.key, required this.folderId});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();

    // Flip animatsiya
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // Sessiyani boshlash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(reviewSessionProvider.notifier)
          .startFolderReview(widget.folderId);
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(reviewSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${session.totalReviewed}/${session.cards.length}'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            ref.read(reviewSessionProvider.notifier).reset();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: AnimatedProgressBar(
            value: session.progress,
            color: AppColors.primary,
            height: 4,
            borderRadius: 0,
          ),
        ),
      ),
      body: session.isLoading
          ? const AppLoadingWidget(message: 'Kartochkalar yuklanmoqda...')
          : session.isCompleted
              ? ReviewResultWidget(
                  correctCount: session.correctCount,
                  incorrectCount: session.incorrectCount,
                  totalCards: session.cards.length,
                  onClose: () {
                    ref.read(reviewSessionProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  onRetry: () {
                    ref
                        .read(reviewSessionProvider.notifier)
                        .startFolderReview(widget.folderId);
                  },
                )
              : _buildReviewCard(session),
    );
  }

  Widget _buildReviewCard(ReviewSessionState session) {
    final card = session.currentCard;
    if (card == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Qolgan kartochkalar badge
        Padding(
          padding: const EdgeInsets.all(AppSizes.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppBadge(
                label: '${session.remaining} ta qoldi',
                type: BadgeType.status,
              ),
              if (card.hasArtikel) ...[
                const SizedBox(width: AppSizes.spacingSm),
                AppBadge(label: card.artikel!, type: BadgeType.level),
              ],
            ],
          ),
        ),

        // Kartochka
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (session.isFlipped) return;
              ref.read(reviewSessionProvider.notifier).flipCard();
              _flipController.forward(from: 0);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingXl,
              ),
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * pi;
                  final isBack = angle > pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: isBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _buildCardBack(card),
                          )
                        : _buildCardFront(card),
                  );
                },
              ),
            ),
          ),
        ),

        // Baholash tugmalari (faqat orqa tomoni ko'ringanda)
        if (session.isFlipped)
          _buildRatingButtons()
        else
          const Padding(
            padding: EdgeInsets.all(AppSizes.spacingXl),
            child: Text(
              'Kartochkani bosib javobni ko\'ring',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  /// Old tomon — so'z
  Widget _buildCardFront(dynamic card) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FF)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (card.hasArtikel)
              Text(
                card.artikel!,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              card.front,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (card.pronunciation != null) ...[
              const SizedBox(height: AppSizes.spacingSm),
              Text(
                card.pronunciation!,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.spacingXl),
            Icon(
              Icons.touch_app_outlined,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  /// Orqa tomon — tarjima
  Widget _buildCardBack(dynamic card) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FFF4), Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.front,
              style: const TextStyle(
                fontSize: 20,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingMd),
            const Divider(),
            const SizedBox(height: AppSizes.spacingMd),
            Text(
              card.back,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
              textAlign: TextAlign.center,
            ),
            if (card.example != null) ...[
              const SizedBox(height: AppSizes.spacingLg),
              Container(
                padding: const EdgeInsets.all(AppSizes.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  card.example!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Baholash tugmalari (SM-2: 0-5)
  Widget _buildRatingButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        child: Row(
          children: [
            _RatingButton(
              label: 'Bilmadim',
              emoji: '😞',
              color: AppColors.error,
              onTap: () => _rate(1),
            ),
            const SizedBox(width: AppSizes.spacingSm),
            _RatingButton(
              label: 'Qiyin',
              emoji: '😐',
              color: AppColors.warning,
              onTap: () => _rate(3),
            ),
            const SizedBox(width: AppSizes.spacingSm),
            _RatingButton(
              label: 'Oson',
              emoji: '😊',
              color: AppColors.info,
              onTap: () => _rate(4),
            ),
            const SizedBox(width: AppSizes.spacingSm),
            _RatingButton(
              label: 'Mukammal',
              emoji: '🎯',
              color: AppColors.success,
              onTap: () => _rate(5),
            ),
          ],
        ),
      ),
    );
  }

  void _rate(int quality) {
    _flipController.reverse();
    ref.read(reviewSessionProvider.notifier).rateCard(quality);
  }
}

/// Baholash tugmasi
class _RatingButton extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingMd),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
