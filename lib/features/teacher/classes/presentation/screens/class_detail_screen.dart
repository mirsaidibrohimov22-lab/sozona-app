// QO'YISH: lib/features/teacher/classes/presentation/screens/class_detail_screen.dart
// So'zona — Sinf tafsilotlari ekrani
// Teacher sinf ma'lumotlari va a'zolar ro'yxatini ko'radi

import 'package:flutter/material.dart';
import 'package:my_first_app/core/widgets/app_empty_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/core/widgets/app_error_widget.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/core/widgets/app_snackbar.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/school_class.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/student_summary.dart';
import 'package:my_first_app/features/teacher/classes/presentation/providers/class_provider.dart';
import 'package:my_first_app/features/teacher/classes/presentation/widgets/student_list_tile.dart';

/// Sinf tafsilotlari ekrani
class ClassDetailScreen extends ConsumerWidget {
  /// Sinf identifikatori (URL dan keladi)
  final String classId;

  const ClassDetailScreen({
    super.key,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(classMembersProvider(classId));
    final selectedClass = ref.watch(selectedClassProvider);

    return Scaffold(
      
      body: CustomScrollView(
        slivers: [
          // ─── AppBar ───
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                selectedClass?.name ?? 'Sinf',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: _ClassHeaderBackground(schoolClass: selectedClass),
            ),
          ),

          // ─── Join Code kartasi ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _JoinCodeCard(schoolClass: selectedClass),
            ),
          ),

          // ─── A'zolar sarlavhasi ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text('O\'quvchilar', style: AppTextStyles.titleMedium),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      membersAsync.valueOrNull?.length.toString() ?? '...',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── A'zolar ro'yxati ───
          membersAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: AppLoadingWidget(message: 'O\'quvchilar yuklanmoqda...'),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: AppErrorWidget(
                message: error.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(classMembersProvider(classId)),
              ),
            ),
            data: (members) {
              if (members.isEmpty) {
                return const SliverToBoxAdapter(
                  child: AppEmptyWidget(
                    icon: Icons.person_add_rounded,
                    title: 'O\'quvchi yo\'q',
                    message: 'Join code orqali o\'quvchilar qo\'shilsin',
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: StudentListTile(
                        student: members[index],
                        onTap: () => _openStudentDetail(
                          context,
                          members[index],
                        ),
                        onRemove: () => _confirmRemoveStudent(
                          context,
                          ref,
                          members[index],
                        ),
                      ),
                    );
                  },
                  childCount: members.length,
                ),
              );
            },
          ),

          // ─── Pastki bo'sh joy ───
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  /// O'quvchi tafsilotlariga o'tish
  void _openStudentDetail(BuildContext context, StudentSummary student) {
    context.push(
      '/teacher/classes/$classId/student/${student.userId}',
    );
  }

  /// O'quvchini chiqarish tasdiqlash dialog'i
  Future<void> _confirmRemoveStudent(
    BuildContext context,
    WidgetRef ref,
    StudentSummary student,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('O\'quvchini chiqarish'),
        content: Text(
          '${student.fullName} ni sinfdan chiqarishni xohlaysizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Chiqarish'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await removeStudentAndRefresh(
          ref: ref,
          classId: classId,
          studentId: student.userId,
        );
        if (context.mounted) {
          AppSnackbar.success(
            context,
            '${student.fullName} sinfdan chiqarildi',
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.error(context, 'Xatolik yuz berdi');
        }
      }
    }
  }
}

/// Sarlavha foni
class _ClassHeaderBackground extends StatelessWidget {
  final SchoolClass? schoolClass;

  const _ClassHeaderBackground({this.schoolClass});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Dekorativ doira
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Statistika
          if (schoolClass != null)
            Positioned(
              left: 16,
              bottom: 56,
              child: Row(
                children: [
                  _StatChip(
                    icon: Icons.people_rounded,
                    label: '${schoolClass!.memberCount} o\'quvchi',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.school_rounded,
                    label: schoolClass!.level,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.language_rounded,
                    label: schoolClass!.languageFlag,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Statistika chip'i
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Join Code kartasi
class _JoinCodeCard extends StatelessWidget {
  final SchoolClass? schoolClass;

  const _JoinCodeCard({this.schoolClass});

  @override
  Widget build(BuildContext context) {
    final code = schoolClass?.joinCode ?? '------';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.vpn_key_rounded,
              color: AppColors.accentDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qo\'shilish kodi',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accentDark,
                  ),
                ),
                Text(
                  code,
                  style: AppTextStyles.titleLarge.copyWith(
                    letterSpacing: 4,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // Nusxa olish tugmasi
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              AppSnackbar.success(
                context,
                'Kod clipboard ga ko\'chirildi!',
              );
            },
            icon: const Icon(Icons.copy_rounded),
            color: AppColors.accentDark,
            tooltip: 'Nusxa olish',
          ),
        ],
      ),
    );
  }
}
