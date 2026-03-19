// QO'YISH: lib/features/teacher/classes/presentation/widgets/class_card.dart
// So'zona — Sinf kartochkasi widget
// Ro'yxatdagi har bir sinf uchun chiroyli karta

import 'package:flutter/material.dart';

import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/school_class.dart';

/// Sinfni chiroyli kartochka ko'rinishida ko'rsatish
class ClassCard extends StatelessWidget {
  /// Sinf ma'lumotlari
  final SchoolClass schoolClass;

  /// Bosganda nima bo'ladi
  final VoidCallback? onTap;

  const ClassCard({
    super.key,
    required this.schoolClass,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Yuqori qator: til belgisi + daraja + a'zolar ───
              Row(
                children: [
                  // Til badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: schoolClass.isGerman
                          ? const Color(0xFFFFF3CD)
                          : AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          schoolClass.languageFlag,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          schoolClass.languageName,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: schoolClass.isGerman
                                ? const Color(0xFF856404)
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Daraja badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      schoolClass.level,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // A'zolar soni
                  Row(
                    children: [
                      const Icon(
                        Icons.people_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${schoolClass.memberCount}/${schoolClass.maxMembers}',
                        style: AppTextStyles.caption.copyWith(
                          color: schoolClass.isFull
                              ? AppColors.error
                              : AppColors.textSecondary,
                          fontWeight: schoolClass.isFull
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Sinf nomi ───
              Text(
                schoolClass.name,
                style: AppTextStyles.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // ─── Tavsif ───
              if (schoolClass.description != null &&
                  schoolClass.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  schoolClass.description!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ─── Quyi qator: Join Code + O'q belgisi ───
              Row(
                children: [
                  // Join Code
                  Row(
                    children: [
                      const Icon(
                        Icons.vpn_key_rounded,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kod: ',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        schoolClass.joinCode,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // O'tish belgisi
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
