// QO'YISH: lib/features/teacher/classes/presentation/widgets/student_list_tile.dart
// So'zona — O'quvchi ro'yxat qatori widget

import 'package:flutter/material.dart';

import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/student_summary.dart';

/// O'quvchini ro'yxatda ko'rsatish uchun widget
class StudentListTile extends StatelessWidget {
  /// O'quvchi ma'lumotlari
  final StudentSummary student;

  /// Bosganda
  final VoidCallback? onTap;

  /// Chiqarish tugmasi bosganda
  final VoidCallback? onRemove;

  const StudentListTile({
    super.key,
    required this.student,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = switch (student.scoreLevel) {
      ScoreLevel.good => AppColors.success,
      ScoreLevel.medium => AppColors.warning,
      ScoreLevel.low => AppColors.error,
    };

    return Card(
      elevation: 0,
      color: AppColors.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // ─── Avatar ───
              CircleAvatar(
                radius: 22,
                
                backgroundImage: student.avatarUrl != null
                    ? NetworkImage(student.avatarUrl!)
                    : null,
                child: student.avatarUrl == null
                    ? Text(
                        student.initials,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // ─── Ism va daraja ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // Daraja
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgTertiary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            student.level,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Faollik holati
                        if (!student.isRecentlyActive)
                          Text(
                            '• Faol emas',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── O'rtacha ball ───
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${student.averageScore.toStringAsFixed(0)}%',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${student.totalAttempts} urinish',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),

              // ─── Chiqarish tugmasi ───
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.person_remove_rounded, size: 20),
                  color: AppColors.error,
                  tooltip: 'Sinfdan chiqarish',
                  onPressed: onRemove,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
