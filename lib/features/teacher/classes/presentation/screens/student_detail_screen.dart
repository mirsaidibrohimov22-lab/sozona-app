// lib/features/teacher/classes/presentation/screens/student_detail_screen.dart
// So'zona — O'quvchi tafsilotlari (yangi dizayn)
// ✅ Har bir skill: Quiz, Listening, Speaking, Flashcard foizlarda

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/student_summary.dart';
import 'package:my_first_app/features/teacher/classes/presentation/providers/class_provider.dart';

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
    final student = membersAsync.valueOrNull
        ?.where((s) => s.userId == studentId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: Text(student?.fullName ?? "O'quvchi"),
        elevation: 0,
        backgroundColor: AppColors.bgPrimary,
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
          _ProfileCard(student: student),
          const SizedBox(height: 16),
          _QuickStats(student: student),
          const SizedBox(height: 16),
          _SkillAnalyticsCard(student: student),
          const SizedBox(height: 16),
          _OverallScoreCard(student: student),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// PROFIL KARTASI
// ═══════════════════════════════════════════════════════
class _ProfileCard extends StatelessWidget {
  final StudentSummary student;
  const _ProfileCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: student.avatarUrl != null
                ? NetworkImage(student.avatarUrl!)
                : null,
            child: student.avatarUrl == null
                ? Text(
                    student.initials,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName,
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
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
                  "Qo'shilgan: ${_fmt(student.joinedAt)}",
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ═══════════════════════════════════════════════════════
// TEZKOR STATISTIKA
// ═══════════════════════════════════════════════════════
class _QuickStats extends StatelessWidget {
  final StudentSummary student;
  const _QuickStats({required this.student});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.task_alt_rounded,
            label: 'Urinishlar',
            value: student.totalAttempts.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: '${student.currentStreak} kun',
            color: const Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.star_rounded,
            label: "O'rtacha",
            value: '${student.averageScore.round()}%',
            color: _scoreColor(student.scoreLevel),
          ),
        ),
      ],
    );
  }

  Color _scoreColor(ScoreLevel l) => switch (l) {
        ScoreLevel.good => AppColors.success,
        ScoreLevel.medium => AppColors.warning,
        ScoreLevel.low => AppColors.error,
      };
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.titleSmall
                  .copyWith(color: color, fontWeight: FontWeight.bold)),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SKILL ANALYTICS — ASOSIY KARTA
// ═══════════════════════════════════════════════════════
class _SkillAnalyticsCard extends StatelessWidget {
  final StudentSummary student;
  const _SkillAnalyticsCard({required this.student});

  static const _skills = [
    (
      key: 'quiz',
      label: 'Quiz',
      icon: Icons.quiz_rounded,
      color: Color(0xFF6366F1)
    ),
    (
      key: 'listening',
      label: 'Listening',
      icon: Icons.headphones_rounded,
      color: Color(0xFF06B6D4)
    ),
    (
      key: 'speaking',
      label: 'Speaking',
      icon: Icons.mic_rounded,
      color: Color(0xFF10B981)
    ),
    (
      key: 'flashcard',
      label: 'Flashcard',
      icon: Icons.style_rounded,
      color: Color(0xFFF59E0B)
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scores = student.skillScores;
    final hasData = scores.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text("Ko'nikma tahlili",
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (!hasData)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text("Ma'lumot yo'q",
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (hasData) ...[
            // Doira diagrammalar qatori
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _skills
                  .map((s) => _CircleSkill(
                        label: s.label,
                        icon: s.icon,
                        color: s.color,
                        percent: scores[s.key] ?? 0.0,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            // Progress bar lar
            ..._skills.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _SkillBar(
                    label: s.label,
                    icon: s.icon,
                    color: s.color,
                    percent: scores[s.key] ?? 0.0,
                  ),
                )),
          ] else ...[
            // Ma'lumot yo'q — bo'sh holat
            Center(
              child: Column(
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 48,
                      color: AppColors.textTertiary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    "O'quvchi hali mashq qilmagan",
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mashqlar bajarilgach statistika chiqadi',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// Doira widget
class _CircleSkill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double percent;

  const _CircleSkill({
    required this.label,
    required this.icon,
    required this.color,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(64, 64),
                painter: _CirclePainter(percent: percent / 100, color: color),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 16),
                  Text(
                    '${percent.round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double percent;
  final Color color;
  _CirclePainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - 8) / 2;

    // Orqa doira
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Progress arc
    if (percent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -math.pi / 2,
        2 * math.pi * percent.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) => old.percent != percent;
}

// Progress bar widget
class _SkillBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double percent;

  const _SkillBar({
    required this.label,
    required this.icon,
    required this.color,
    required this.percent,
  });

  String get _level {
    if (percent >= 80) return 'Ajoyib';
    if (percent >= 60) return 'Yaxshi';
    if (percent >= 40) return "O'rta";
    if (percent > 0) return 'Past';
    return "Ma'lumot yo'q";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            Text(
              percent > 0 ? '${percent.round()}%' : '-',
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_level,
                  style: TextStyle(
                      fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// UMUMIY BALL KARTASI
// ═══════════════════════════════════════════════════════
class _OverallScoreCard extends StatelessWidget {
  final StudentSummary student;
  const _OverallScoreCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final scoreColor = switch (student.scoreLevel) {
      ScoreLevel.good => AppColors.success,
      ScoreLevel.medium => AppColors.warning,
      ScoreLevel.low => AppColors.error,
    };
    final msg = switch (student.scoreLevel) {
      ScoreLevel.good => 'Ajoyib natija! 🌟',
      ScoreLevel.medium => 'Yaxshi, davom eting 💪',
      ScoreLevel.low => "Ko'proq mashq kerak 📚",
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Umumiy natija',
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                '${student.averageScore.round()}%',
                style: AppTextStyles.titleLarge
                    .copyWith(color: scoreColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (student.averageScore / 100).clamp(0.0, 1.0),
              backgroundColor: scoreColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(msg,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// YORDAMCHI WIDGETLAR
// ═══════════════════════════════════════════════════════
class _Badge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const _Badge({required this.label, this.color, this.textColor});

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
