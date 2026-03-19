// QO'YISH: lib/features/teacher/publishing/presentation/widgets/class_selector.dart
// Class Selector Widget — Sinf tanlash uchun widget

import 'package:flutter/material.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';

/// Class Selector Widget
///
/// Bolaga: Bu widget — sinflarni ro'yxat ko'rinishida ko'rsatadi.
/// Teacher qaysi sinfga yuborishni tanlaydi.
class ClassSelector extends StatelessWidget {
  final List<ClassItem> classes;
  final String? selectedClassId;
  final ValueChanged<String> onClassSelected;

  const ClassSelector({
    super.key,
    required this.classes,
    this.selectedClassId,
    required this.onClassSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: classes.map((classItem) {
        final isSelected = classItem.id == selectedClassId;

        return _ClassCard(
          classItem: classItem,
          isSelected: isSelected,
          onTap: () => onClassSelected(classItem.id),
        );
      }).toList(),
    );
  }

  /// Bo'sh holat (sinflar yo'q)
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.class_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sizda hali sinf yo\'q',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Kontent yuborish uchun avval sinf yaratishingiz kerak',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/teacher/classes/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('Sinf yaratish'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Class Card — Har bir sinf uchun kartochka
class _ClassCard extends StatelessWidget {
  final ClassItem classItem;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClassCard({
    required this.classItem,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Class icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.class_outlined,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Class info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classItem.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${classItem.memberCount} o\'quvchi',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (classItem.level != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              classItem.level!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 24,
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: AppColors.textTertiary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Class Item Model
///
/// Sinf ma'lumotlari uchun oddiy model
class ClassItem {
  final String id;
  final String name;
  final int memberCount;
  final String? level;

  const ClassItem({
    required this.id,
    required this.name,
    required this.memberCount,
    this.level,
  });

  /// SchoolClass entity'dan ClassItem yaratish
  factory ClassItem.fromEntity(dynamic schoolClass) {
    return ClassItem(
      id: schoolClass.id,
      name: schoolClass.name,
      memberCount: schoolClass.memberCount,
      level: schoolClass.level,
    );
  }
}

/// Multi-Select Class Selector
///
/// Ko'plab sinflarni tanlash uchun
class MultiClassSelector extends StatelessWidget {
  final List<ClassItem> classes;
  final Set<String> selectedClassIds;
  final ValueChanged<Set<String>> onSelectionChanged;

  const MultiClassSelector({
    super.key,
    required this.classes,
    required this.selectedClassIds,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return ClassSelector(
        classes: const [],
        onClassSelected: (_) {},
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Select all / Deselect all
        if (classes.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton.icon(
              onPressed: () {
                if (selectedClassIds.length == classes.length) {
                  // Deselect all
                  onSelectionChanged({});
                } else {
                  // Select all
                  onSelectionChanged(
                    classes.map((c) => c.id).toSet(),
                  );
                }
              },
              icon: Icon(
                selectedClassIds.length == classes.length
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
              ),
              label: Text(
                selectedClassIds.length == classes.length
                    ? 'Hammasini bekor qilish'
                    : 'Hammasini tanlash',
              ),
            ),
          ),

        // Class cards
        ...classes.map((classItem) {
          final isSelected = selectedClassIds.contains(classItem.id);

          return _ClassCard(
            classItem: classItem,
            isSelected: isSelected,
            onTap: () {
              final newSelection = Set<String>.from(selectedClassIds);
              if (isSelected) {
                newSelection.remove(classItem.id);
              } else {
                newSelection.add(classItem.id);
              }
              onSelectionChanged(newSelection);
            },
          );
        }),
      ],
    );
  }
}
