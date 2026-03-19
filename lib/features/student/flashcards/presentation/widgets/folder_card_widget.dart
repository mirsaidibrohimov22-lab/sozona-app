// lib/features/flashcard/presentation/widgets/folder_card_widget.dart
// So'zona — Papka kartochkasi widgeti
// Bitta papka: nom, rasm, statistika, progress

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/animated_counter.dart';
import 'package:my_first_app/core/widgets/app_badge.dart';
import 'package:my_first_app/core/widgets/app_card.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/folder_entity.dart';

/// Papka kartochkasi
class FolderCardWidget extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FolderCardWidget({
    super.key,
    required this.folder,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yuqori qator: emoji + nom + menu
          Row(
            children: [
              // Emoji/Ikonka
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getFolderColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                alignment: Alignment.center,
                child: Text(
                  folder.emoji ?? '📁',
                  style: const TextStyle(fontSize: 22),
                ),
              ),

              const SizedBox(width: AppSizes.spacingMd),

              // Nom va tavsif
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (folder.description != null)
                      Text(
                        folder.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Badge'lar
              if (folder.isAiGenerated)
                const Padding(
                  padding: EdgeInsets.only(right: AppSizes.spacingXs),
                  child: AppBadge(label: 'AI', type: BadgeType.status),
                ),

              if (folder.cefrLevel != null) AppBadge.level(folder.cefrLevel!),

              // O'chirish
              if (onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'O\'chirish',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Statistika qatori
          Row(
            children: [
              _MiniStat(
                icon: Icons.style_outlined,
                value: '${folder.cardCount}',
                label: 'kartochka',
              ),
              const SizedBox(width: AppSizes.spacingLg),
              _MiniStat(
                icon: Icons.check_circle_outline,
                value: '${folder.masteredCount}',
                label: 'o\'zlashtirilgan',
                color: AppColors.success,
              ),
              if (folder.hasDueCards) ...[
                const SizedBox(width: AppSizes.spacingLg),
                _MiniStat(
                  icon: Icons.schedule,
                  value: '${folder.dueCount}',
                  label: 'tayyor',
                  color: AppColors.streak,
                ),
              ],
            ],
          ),

          // Progress bar
          if (folder.cardCount > 0) ...[
            const SizedBox(height: AppSizes.spacingMd),
            AnimatedProgressBar(
              value: folder.masteryPercent / 100,
              color: _getFolderColor(),
              height: 4,
            ),
          ],
        ],
      ),
    );
  }

  /// Papka rangini olish
  Color _getFolderColor() {
    switch (folder.color) {
      case FolderColor.blue:
        return AppColors.primary;
      case FolderColor.green:
        return AppColors.success;
      case FolderColor.orange:
        return AppColors.accent;
      case FolderColor.purple:
        return AppColors.xp;
      case FolderColor.red:
        return AppColors.error;
      case FolderColor.teal:
        return AppColors.secondary;
      case FolderColor.pink:
        return const Color(0xFFEC4899);
      case FolderColor.indigo:
        return AppColors.primaryDark;
    }
  }
}

/// Kichik statistika
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(fontSize: 12, color: c),
        ),
      ],
    );
  }
}
