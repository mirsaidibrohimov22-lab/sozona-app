// lib/features/student/flashcards/presentation/screens/review_screen.dart
// So'zona — Kartochka takrorlash ekrani
// ✅ FIX: userId authdan olinib startFolderReview ga uzatiladi
// ✅ FIX: Noto'g'ri kartochkalar qayta ko'rsatiladi (loop)

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/animated_counter.dart';
import 'package:my_first_app/core/widgets/app_badge.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/flashcards/presentation/providers/flashcard_provider.dart';
import 'package:my_first_app/features/student/flashcards/presentation/widgets/review_result_widget.dart';
import 'package:my_first_app/features/premium/presentation/providers/premium_provider.dart';
import 'package:my_first_app/features/premium/presentation/screens/premium_coach_screen.dart';

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

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ FIX: userId auth provider dan olinadi
      final userId = ref.read(authNotifierProvider).user?.id ?? '';
      ref
          .read(reviewSessionProvider.notifier)
          .startFolderReview(widget.folderId, userId);
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

    // AppBar title: nechta to'g'ri / jami
    final titleText = session.totalInitialCards > 0
        ? '${session.correctCount}/${session.totalInitialCards}'
        : '0/0';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
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
                  totalCards: session.totalInitialCards,
                  onClose: () {
                    final score = session.totalInitialCards > 0
                        ? (session.correctCount /
                            session.totalInitialCards *
                            100)
                        : 0.0;
                    ref.read(reviewSessionProvider.notifier).reset();
                    if (ref.read(hasPremiumProvider)) {
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (_) => PremiumCoachScreen(
                            trigger: 'after_lesson',
                            skillType: 'flashcard',
                            lastScore: score.toDouble(),
                            // ✅ YANGI: Haqiqiy sessiya ma'lumotlari
                            sessionData: {
                              'totalQuestions': session.totalInitialCards,
                              'correctCount': session.correctCount,
                              'wrongCount': session.incorrectCount,
                            },
                          ),
                        ),
                      )
                          .then((_) {
                        if (context.mounted) Navigator.pop(context);
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  onRetry: () {
                    final userId =
                        ref.read(authNotifierProvider).user?.id ?? '';
                    ref
                        .read(reviewSessionProvider.notifier)
                        .startFolderReview(widget.folderId, userId);
                  },
                )
              : session.cards.isEmpty
                  ? _buildNoCards()
                  : _buildReviewCard(session),
    );
  }

  /// Kartochkalar yo'q holati
  Widget _buildNoCards() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSizes.spacingMd),
          const Text(
            'Bu papkada kartochkalar yo\'q',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingLg),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Orqaga'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewSessionState session) {
    final card = session.currentCard;
    if (card == null) return const SizedBox.shrink();

    // Qolgan noto'g'ri kartochkalar soni
    final remainingCount = session.cards.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Qolgan kartochkalar badge
              AppBadge(
                label: '$remainingCount ta qoldi',
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
    // ✅ FIX: animatsiya tugashini kutib, keyin keyingi kartaga o'tamiz
    _flipController.reverse().then((_) {
      if (mounted) {
        ref.read(reviewSessionProvider.notifier).rateCard(quality);
      }
    });
  }
}

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
