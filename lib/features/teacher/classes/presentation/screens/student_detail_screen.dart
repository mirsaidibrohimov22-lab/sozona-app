// QO'YISH: lib/features/teacher/classes/presentation/screens/student_detail_screen.dart
// So'zona — O'quvchi tafsilotlari ekrani
// Teacher bitta o'quvchining barcha natijalarini ko'radi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/student_summary.dart';
import 'package:my_first_app/features/teacher/classes/presentation/providers/class_provider.dart';

/// O'quvchi tafsilotlari ekrani
class StudentDetailScreen extends ConsumerWidget {
  final String classId;
  final String studentId;

  const StudentDetailScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(classMembersProvider(classId));

    // Members ro'yxatidan shu studentni topish
    final student = membersAsync.valueOrNull
        ?.where(
          (s) => s.userId == studentId,
        )
        .firstOrNull;

    return Scaffold(
      
      appBar: AppBar(
        title: Text(student?.fullName ?? 'O\'quvchi'),
        
        elevation: 0,
      ),
      body: student == null
          ? const Center(child: CircularProgressIndicator())
          : _StudentDetailBody(student: student),
    );
  }
}

class _StudentDetailBody extends StatelessWidget {
  final StudentSummary student;

  const _StudentDetailBody({required this.student});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ─── Profil kartasi ───
          _ProfileCard(student: student),
          const SizedBox(height: 16),

          // ─── Statistika ───
          _StatsGrid(student: student),
          const SizedBox(height: 16),

          // ─── Progress bar ───
          _ScoreCard(student: student),
        ],
      ),
    );
  }
}

/// Profil kartasi
class _ProfileCard extends StatelessWidget {
  final StudentSummary student;

  const _ProfileCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 36,
              
              backgroundImage: student.avatarUrl != null
                  ? NetworkImage(student.avatarUrl!)
                  : null,
              child: student.avatarUrl == null
                  ? Text(
                      student.initials,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Badge(label: student.level),
                      const SizedBox(width: 8),
                      _Badge(
                        label: student.isRecentlyActive ? 'Faol' : 'Faol emas',
                        color: student.isRecentlyActive
                            ? AppColors.successLight
                            : AppColors.bgTertiary,
                        textColor: student.isRecentlyActive
                            ? AppColors.successDark
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qo\'shilgan: ${_formatDate(student.joinedAt)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Badge widget
class _Badge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const _Badge({
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor ?? AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Statistika grid
class _StatsGrid extends StatelessWidget {
  final StudentSummary student;

  const _StatsGrid({required this.student});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.task_alt_rounded,
            label: 'Urinishlar',
            value: student.totalAttempts.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: '${student.currentStreak} kun',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

/// Statistika kartasi
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ball ko'rsatuvchi karta
class _ScoreCard extends StatelessWidget {
  final StudentSummary student;

  const _ScoreCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final score = student.averageScore / 100;
    final scoreColor = switch (student.scoreLevel) {
      ScoreLevel.good => AppColors.success,
      ScoreLevel.medium => AppColors.warning,
      ScoreLevel.low => AppColors.error,
    };

    return Card(
      elevation: 0,
      color: AppColors.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('O\'rtacha ball', style: AppTextStyles.titleMedium),
                Text(
                  '${student.averageScore.toStringAsFixed(0)}%',
                  style: AppTextStyles.titleMedium.copyWith(color: scoreColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: score,
                backgroundColor: scoreColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              student.scoreLevel == ScoreLevel.good
                  ? 'Ajoyib natija! 🌟'
                  : student.scoreLevel == ScoreLevel.medium
                      ? 'Yaxshi, davom eting 💪'
                      : 'Ko\'proq mashq kerak 📚',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
