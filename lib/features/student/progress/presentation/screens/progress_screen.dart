// lib/features/student/progress/presentation/screens/progress_screen.dart
// ✅ FIX v2.0: Kunlik/haftalik/oylik/yillik grafik qo'shildi
// ✅ FIX v2.0: Oxirgi faollik activities collectiondan o'qiladi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/progress/presentation/providers/progress_provider.dart';
import 'package:my_first_app/features/student/progress/presentation/widgets/progress_chart.dart';
import 'package:my_first_app/features/student/progress/presentation/widgets/streak_calendar.dart';
import 'package:my_first_app/features/student/progress/presentation/widgets/weak_areas_card.dart';

enum ActivityPeriod { daily, weekly, monthly, yearly }

extension ActivityPeriodLabel on ActivityPeriod {
  String get label {
    switch (this) {
      case ActivityPeriod.daily:
        return 'Kunlik';
      case ActivityPeriod.weekly:
        return 'Haftalik';
      case ActivityPeriod.monthly:
        return 'Oylik';
      case ActivityPeriod.yearly:
        return 'Yillik';
    }
  }
}

class ActivityDataPoint {
  final String label;
  final double xpEarned;
  final int minutesStudied;
  final int quizzesCompleted;
  const ActivityDataPoint({
    required this.label,
    this.xpEarned = 0,
    this.minutesStudied = 0,
    this.quizzesCompleted = 0,
  });
}

final activityChartProvider = FutureProvider.family<List<ActivityDataPoint>,
    ({String userId, ActivityPeriod period})>(
  (ref, params) async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    List<ActivityDataPoint> points = [];

    switch (params.period) {
      case ActivityPeriod.daily:
        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          final dayStart = DateTime(day.year, day.month, day.day);
          final dayEnd = dayStart.add(const Duration(days: 1));
          final snap = await db
              .collection('activities')
              .where('userId', isEqualTo: params.userId)
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
              .where('timestamp', isLessThan: Timestamp.fromDate(dayEnd))
              .get();
          double xp = 0;
          int mins = 0;
          int quizzes = 0;
          for (final doc in snap.docs) {
            final d = doc.data();
            xp += ((d['scorePercent'] as num?)?.toDouble() ?? 0) * 0.5;
            mins += ((d['responseTime'] as num?)?.toInt() ?? 0) ~/ 60;
            if (d['skillType'] == 'quiz') quizzes++;
          }
          final weekdays = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
          points.add(ActivityDataPoint(
              label: weekdays[day.weekday - 1],
              xpEarned: xp,
              minutesStudied: mins,
              quizzesCompleted: quizzes));
        }
        break;

      case ActivityPeriod.weekly:
        for (int i = 3; i >= 0; i--) {
          final weekStart =
              now.subtract(Duration(days: now.weekday - 1 + i * 7));
          final wStart =
              DateTime(weekStart.year, weekStart.month, weekStart.day);
          final wEnd = wStart.add(const Duration(days: 7));
          final snap = await db
              .collection('activities')
              .where('userId', isEqualTo: params.userId)
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(wStart))
              .where('timestamp', isLessThan: Timestamp.fromDate(wEnd))
              .get();
          double xp = 0;
          int mins = 0;
          int quizzes = 0;
          for (final doc in snap.docs) {
            final d = doc.data();
            xp += ((d['scorePercent'] as num?)?.toDouble() ?? 0) * 0.5;
            mins += ((d['responseTime'] as num?)?.toInt() ?? 0) ~/ 60;
            if (d['skillType'] == 'quiz') quizzes++;
          }
          points.add(ActivityDataPoint(
              label: '${4 - i}-hafta',
              xpEarned: xp,
              minutesStudied: mins,
              quizzesCompleted: quizzes));
        }
        break;

      case ActivityPeriod.monthly:
        final monthNames = [
          'Yan',
          'Fev',
          'Mar',
          'Apr',
          'May',
          'Iyn',
          'Iyl',
          'Avg',
          'Sen',
          'Okt',
          'Noy',
          'Dek'
        ];
        for (int i = 5; i >= 0; i--) {
          int month = now.month - i;
          int year = now.year;
          while (month <= 0) {
            month += 12;
            year--;
          }
          final mStart = DateTime(year, month, 1);
          int nextMonth = month + 1;
          int nextYear = year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear++;
          }
          final mEnd = DateTime(nextYear, nextMonth, 1);
          final snap = await db
              .collection('activities')
              .where('userId', isEqualTo: params.userId)
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(mStart))
              .where('timestamp', isLessThan: Timestamp.fromDate(mEnd))
              .get();
          double xp = 0;
          int mins = 0;
          int quizzes = 0;
          for (final doc in snap.docs) {
            final d = doc.data();
            xp += ((d['scorePercent'] as num?)?.toDouble() ?? 0) * 0.5;
            mins += ((d['responseTime'] as num?)?.toInt() ?? 0) ~/ 60;
            if (d['skillType'] == 'quiz') quizzes++;
          }
          points.add(ActivityDataPoint(
              label: monthNames[month - 1],
              xpEarned: xp,
              minutesStudied: mins,
              quizzesCompleted: quizzes));
        }
        break;

      case ActivityPeriod.yearly:
        for (int i = 2; i >= 0; i--) {
          final year = now.year - i;
          final snap = await db
              .collection('activities')
              .where('userId', isEqualTo: params.userId)
              .where('timestamp',
                  isGreaterThanOrEqualTo:
                      Timestamp.fromDate(DateTime(year, 1, 1)))
              .where('timestamp',
                  isLessThan: Timestamp.fromDate(DateTime(year + 1, 1, 1)))
              .get();
          double xp = 0;
          int mins = 0;
          int quizzes = 0;
          for (final doc in snap.docs) {
            final d = doc.data();
            xp += ((d['scorePercent'] as num?)?.toDouble() ?? 0) * 0.5;
            mins += ((d['responseTime'] as num?)?.toInt() ?? 0) ~/ 60;
            if (d['skillType'] == 'quiz') quizzes++;
          }
          points.add(ActivityDataPoint(
              label: '$year',
              xpEarned: xp,
              minutesStudied: mins,
              quizzesCompleted: quizzes));
        }
        break;
    }
    return points;
  },
);

final recentActivitiesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, userId) async {
  final db = FirebaseFirestore.instance;
  final snap = await db
      .collection('activities')
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .limit(10)
      .get();
  return snap.docs.map((d) => d.data()).toList();
});

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  ActivityPeriod _selectedPeriod = ActivityPeriod.daily;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.id ?? '';
    final progressAsync = ref.watch(progressProvider(userId));
    final chartAsync = ref.watch(
        activityChartProvider((userId: userId, period: _selectedPeriod)));
    final recentAsync = ref.watch(recentActivitiesProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mening progressim'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xato: $e')),
        data: (progress) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _XpCard(progress: progress),
              const SizedBox(height: 16),
              _ActivityChartCard(
                chartAsync: chartAsync,
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
              ),
              const SizedBox(height: 16),
              Text('Ko\'nikmalar', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              ProgressChart(skillScores: progress.skillScores),
              const SizedBox(height: 16),
              Text('Oxirgi faollik', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              _RecentActivityList(recentAsync: recentAsync),
              const SizedBox(height: 16),
              Text('So\'nggi 7 kun', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              StreakCalendar(activities: progress.recentActivity),
              const SizedBox(height: 16),
              if (progress.weakAreas.isNotEmpty) ...[
                Text('Zaif joylar', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                WeakAreasCard(weakAreas: progress.weakAreas),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _XpCard extends StatelessWidget {
  final dynamic progress;
  const _XpCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${progress.totalXp} XP',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('Daraja: ${progress.currentLevel}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Keyingi darajaga: ${progress.xpToNextLevel} XP',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            Column(
              children: [
                Text('🔥 ${progress.currentStreak}',
                    style: const TextStyle(fontSize: 22, color: Colors.white)),
                const Text('streak',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityChartCard extends StatelessWidget {
  final AsyncValue<List<ActivityDataPoint>> chartAsync;
  final ActivityPeriod selectedPeriod;
  final void Function(ActivityPeriod) onPeriodChanged;
  const _ActivityChartCard({
    required this.chartAsync,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Faollik grafigi', style: AppTextStyles.titleMedium),
                const Spacer(),
                ...ActivityPeriod.values.map((p) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ChoiceChip(
                        label: Text(p.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: selectedPeriod == p
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            )),
                        selected: selectedPeriod == p,
                        onSelected: (_) => onPeriodChanged(p),
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.grey.shade100,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              // ✅ RESPONSIVE FIX: adaptive placeholder heights
              final screenH = MediaQuery.of(context).size.height;
              final placeholderH = (screenH * 0.18).clamp(100.0, 150.0);
              return chartAsync.when(
                loading: () => SizedBox(
                    height: placeholderH,
                    child: const Center(child: CircularProgressIndicator())),
                error: (e, _) => SizedBox(
                    height: placeholderH * 0.5,
                    child: const Center(child: Text('Grafik yuklanmadi'))),
                data: (points) {
                  if (points.isEmpty || points.every((p) => p.xpEarned == 0)) {
                    return SizedBox(
                      height: placeholderH,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart_outlined,
                                size: 36, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Hali faollik yo\'q',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }
                  return _BarChart(points: points);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<ActivityDataPoint> points;
  const _BarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    // ✅ RESPONSIVE FIX: adaptive bar chart balandligi
    // iPhone SE (667px) → 120px, S24 (900px) → 160px
    final screenH = MediaQuery.of(context).size.height;
    final chartH = (screenH * 0.18).clamp(110.0, 160.0);
    final barMaxH = chartH - 30; // label va raqam uchun joy

    final maxXp = points.fold(0.0, (m, p) => p.xpEarned > m ? p.xpEarned : m);
    if (maxXp == 0)
      return SizedBox(
          height: chartH,
          child: const Center(
              child: Text('Ma\'lumot yo\'q',
                  style: TextStyle(color: Colors.grey))));

    return SizedBox(
      height: chartH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((point) {
          final ratio = maxXp > 0 ? point.xpEarned / maxXp : 0.0;
          final barH = ratio * barMaxH;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (point.xpEarned > 0)
                    Text('${point.xpEarned.round()}',
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: barH.clamp(4.0, barMaxH),
                    decoration: BoxDecoration(
                      color: point.xpEarned > 0
                          ? AppColors.primary
                          : Colors.grey.shade200,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(point.label,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> recentAsync;
  const _RecentActivityList({required this.recentAsync});

  @override
  Widget build(BuildContext context) {
    return recentAsync.when(
      loading: () => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
      data: (activities) {
        if (activities.isEmpty) {
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 36, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Hali faollik yo\'q',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: activities.take(5).map((act) {
              final skill = act['skillType'] as String? ?? 'quiz';
              final pct = (act['scorePercent'] as num?)?.toDouble() ?? 0;
              final ts = act['timestamp'] as Timestamp?;
              final date = ts?.toDate();
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _skillColor(skill).withValues(alpha: 0.15),
                  child: Icon(_skillIcon(skill),
                      color: _skillColor(skill), size: 18),
                ),
                title: Text(_skillName(skill),
                    style: const TextStyle(fontSize: 14)),
                subtitle: date != null
                    ? Text(_formatDate(date),
                        style: const TextStyle(fontSize: 12))
                    : null,
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor(pct).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${pct.round()}%',
                      style: TextStyle(
                          color: _scoreColor(pct),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _skillIcon(String s) {
    switch (s) {
      case 'quiz':
        return Icons.quiz_rounded;
      case 'flashcard':
        return Icons.style_rounded;
      case 'listening':
        return Icons.headphones_rounded;
      case 'speaking':
        return Icons.mic_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  Color _skillColor(String s) {
    switch (s) {
      case 'quiz':
        return const Color(0xFF6C5CE7);
      case 'flashcard':
        return const Color(0xFF00B894);
      case 'listening':
        return const Color(0xFF0984E3);
      case 'speaking':
        return const Color(0xFFE17055);
      default:
        return AppColors.primary;
    }
  }

  String _skillName(String s) {
    switch (s) {
      case 'quiz':
        return 'Quiz';
      case 'flashcard':
        return 'Kartochka';
      case 'listening':
        return 'Tinglash';
      case 'speaking':
        return 'Gaplashish';
      default:
        return s;
    }
  }

  Color _scoreColor(double pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
    if (diff.inHours < 24) return '${diff.inHours} soat oldin';
    if (diff.inDays < 7) return '${diff.inDays} kun oldin';
    return '${date.day}/${date.month}/${date.year}';
  }
}
