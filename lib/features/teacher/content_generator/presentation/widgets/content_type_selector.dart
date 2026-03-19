// QO'YISH: lib/features/teacher/content_generator/presentation/widgets/content_type_selector.dart
// Content Type Selector Widget — Kontent turini tanlash uchun widget

import 'package:flutter/material.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';

/// Content Type Selector Widget
///
/// Bolaga: Bu widget — 3 ta katta tugma (Quiz, Flashcard, Listening).
/// Bitta tanlansa, boshqalari bo'sh ko'rinadi.
class ContentTypeSelector extends StatelessWidget {
  final ContentType selectedType;
  final ValueChanged<ContentType> onTypeChanged;

  const ContentTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeCard(
            type: ContentType.quiz,
            icon: Icons.quiz,
            label: 'Quiz',
            description: 'Savollar to\'plami',
            isSelected: selectedType == ContentType.quiz,
            onTap: () => onTypeChanged(ContentType.quiz),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeCard(
            type: ContentType.speaking,
            icon: Icons.record_voice_over,
            label: 'Speaking',
            description: 'Gaplashish mashqi',
            isSelected: selectedType == ContentType.speaking,
            onTap: () => onTypeChanged(ContentType.speaking),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeCard(
            type: ContentType.listening,
            icon: Icons.headphones,
            label: 'Listening',
            description: 'Tinglash mashqi',
            isSelected: selectedType == ContentType.listening,
            onTap: () => onTypeChanged(ContentType.listening),
          ),
        ),
      ],
    );
  }
}

/// Type Card — Har bir kontent turi uchun kartochka
class _TypeCard extends StatelessWidget {
  final ContentType type;
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(height: 8),

            // Label
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Description
            Text(
              description,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
