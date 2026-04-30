// lib/features/student/flashcards/presentation/screens/cards_list_screen.dart
// So'zona — Papka ichidagi kartochkalar ro'yxati
// ✅ FIX: loadCards da userId to'g'ri uzatiladi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/app_badge.dart';
import 'package:my_first_app/core/widgets/app_empty_state.dart';
import 'package:my_first_app/core/widgets/app_error_widget.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';
import 'package:my_first_app/features/student/flashcards/presentation/providers/flashcard_provider.dart';
import 'package:my_first_app/features/student/flashcards/presentation/widgets/card_list_item.dart';

/// Papka ichidagi kartochkalar ekrani
class CardsListScreen extends ConsumerStatefulWidget {
  final String folderId;

  const CardsListScreen({super.key, required this.folderId});

  @override
  ConsumerState<CardsListScreen> createState() => _CardsListScreenState();
}

class _CardsListScreenState extends ConsumerState<CardsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCards();
    });
  }

  /// ✅ FIX: userId auth provider dan olinib loadCards ga uzatiladi
  void _loadCards() {
    final userId = ref.read(authNotifierProvider).user?.id ?? '';
    ref.read(cardsProvider.notifier).loadCards(widget.folderId, userId);
  }

  @override
  Widget build(BuildContext context) {
    final cardsState = ref.watch(cardsProvider);
    final dueCount = cardsState.cards.where((c) => c.isDueForReview).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartochkalar'),
        centerTitle: true,
        actions: [
          if (dueCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.spacingSm),
              child: AppBadge(
                label: '$dueCount ta tayyor',
                type: BadgeType.streak,
              ),
            ),
        ],
      ),
      body: cardsState.isLoading
          ? const AppLoadingWidget()
          : cardsState.error != null
              ? AppErrorWidget(
                  message: cardsState.error!,
                  onRetry: _loadCards,
                )
              : cardsState.cards.isEmpty
                  ? const AppEmptyWidget(
                      title: 'Kartochkalar yo\'q',
                      message: 'Yangi kartochka qo\'shing yoki AI dan so\'rang',
                      icon: Icons.style_outlined,
                    )
                  : _buildContent(cardsState),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Takrorlash boshlash — barcha kartochkalar bilan
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacingSm),
            child: FloatingActionButton.extended(
              heroTag: 'review',
              onPressed: () => context.push(
                '/student/flashcards/review/${widget.folderId}',
              ),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                dueCount > 0
                    ? 'Takrorlash ($dueCount)'
                    : 'Takrorlash (${cardsState.cards.length})',
              ),
            ),
          ),
          // Kartochka qo'shish
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _showAddCardDialog,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(CardsState state) {
    return RefreshIndicator(
      onRefresh: () async => _loadCards(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        itemCount: state.cards.length,
        itemBuilder: (context, index) {
          final card = state.cards[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacingSm),
            child: CardListItem(
              card: card,
              onTap: () => _showCardDetail(card),
              onDelete: () async {
                final confirm = await _showDeleteConfirm();
                if (confirm) {
                  ref.read(cardsProvider.notifier).deleteCard(card.id);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddCardDialog() async {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    final exampleController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Text(
          'Yangi kartochka',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'So\'z (inglizcha/nemischa) *',
                  hintText: 'Masalan: apple',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingMd),
              TextField(
                controller: backController,
                decoration: InputDecoration(
                  labelText: 'Tarjima (o\'zbekcha) *',
                  hintText: 'Masalan: olma',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingMd),
              TextField(
                controller: exampleController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Misol gap (ixtiyoriy)',
                  hintText: 'I eat an apple every day.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );

    if (result == true) {
      final userId = ref.read(authNotifierProvider).user?.id;
      if (userId != null) {
        await ref.read(cardsProvider.notifier).createCard(
              folderId: widget.folderId,
              userId: userId,
              front: frontController.text.trim(),
              back: backController.text.trim(),
              example: exampleController.text.trim().isNotEmpty
                  ? exampleController.text.trim()
                  : null,
            );
      }
    }

    frontController.dispose();
    backController.dispose();
    exampleController.dispose();
  }

  void _showCardDetail(FlashcardEntity card) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.front,
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (card.hasArtikel)
              AppBadge(label: card.artikel!, type: BadgeType.level),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              card.back,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (card.example != null) ...[
              const SizedBox(height: AppSizes.spacingMd),
              Text(
                'Misol: ${card.example}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip('Ko\'rilgan', '${card.reviewCount}'),
                _StatChip('To\'g\'ri', '${card.correctCount}'),
                _StatChip('Aniqlik', '${(card.accuracy * 100).toInt()}%'),
                _StatChip('Daraja', card.difficulty.name),
              ],
            ),
            const SizedBox(height: AppSizes.spacingLg),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirm() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kartochkani o\'chirish'),
        content: const Text('Bu kartochkani o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
