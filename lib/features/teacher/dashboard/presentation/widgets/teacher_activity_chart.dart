// lib/features/teacher/dashboard/presentation/widgets/teacher_activity_chart.dart
// ✅ YANGI: O'qituvchi dashboard — o'quvchi faollik grafigi widget
// Kunlik/haftalik/oylik/yillik bar chart + ko'rsatkich kartalar

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/features/teacher/dashboard/presentation/providers/teacher_activity_chart_provider.dart';

class TeacherActivityChart extends ConsumerStatefulWidget {
  final String teacherId;
  final List<String> classIds;

  const TeacherActivityChart({
    super.key,
    required this.teacherId,
    required this.classIds,
  });

  @override
  ConsumerState<TeacherActivityChart> createState() =>
      _TeacherActivityChartState();
}

class _TeacherActivityChartState extends ConsumerState<TeacherActivityChart> {
  TeacherChartPeriod _period = TeacherChartPeriod.daily;

  // Grafik ko'rsatkichi: 0=faol, 1=mashqlar, 2=ball
  int _metricIndex = 0;

  static const _metrics = [
    _MetricInfo('Faol o\'quvchilar', AppColors.primary, Icons.people_rounded),
    _MetricInfo('Jami mashqlar', AppColors.secondary, Icons.quiz_rounded),
    _MetricInfo('O\'rtacha ball', AppColors.success, Icons.star_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final chartAsync = ref.watch(teacherActivityChartProvider((
      teacherId: widget.teacherId,
      classIds: widget.classIds,
      period: _period,
    )));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Faollik grafigi ───
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sarlavha + davr tanlash
                Row(
                  children: [
                    Text('O\'quvchilar faolligi',
                        style: AppTextStyles.titleMedium),
                    const Spacer(),
                    ...TeacherChartPeriod.values.map((p) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: ChoiceChip(
                            label: Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: _period == p
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            selected: _period == p,
                            onSelected: (_) => setState(() => _period = p),
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey.shade100,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 12),

                // Ko'rsatkich tanlash
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_metrics.length, (i) {
                      final m = _metrics[i];
                      final selected = _metricIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _metricIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? m.color.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              border: Border.all(
                                color:
                                    selected ? m.color : Colors.grey.shade300,
                                width: selected ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(m.icon,
                                    size: 14,
                                    color: selected
                                        ? m.color
                                        : AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  m.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selected
                                        ? m.color
                                        : AppColors.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // Bar chart
                chartAsync.when(
                  loading: () => const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => const SizedBox(
                    height: 80,
                    child: Center(
                      child: Text(
                        'Grafik yuklanmadi',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  data: (points) {
                    final hasData = points.any((p) =>
                        p.activeStudents > 0 ||
                        p.totalActivities > 0 ||
                        p.avgScore > 0);
                    if (!hasData) {
                      return const SizedBox(
                        height: 120,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bar_chart_outlined,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Hali faollik yo\'q',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return _TeacherBarChart(
                      points: points,
                      metricIndex: _metricIndex,
                      color: _metrics[_metricIndex].color,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ─── Umumiy statistika kartalar ───
        chartAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (points) => _SummaryCards(points: points),
        ),
      ],
    );
  }
}

// ─── Bar Chart ───
class _TeacherBarChart extends StatelessWidget {
  final List<TeacherChartPoint> points;
  final int metricIndex;
  final Color color;

  const _TeacherBarChart({
    required this.points,
    required this.metricIndex,
    required this.color,
  });

  double _getValue(TeacherChartPoint p) {
    switch (metricIndex) {
      case 0:
        return p.activeStudents.toDouble();
      case 1:
        return p.totalActivities.toDouble();
      case 2:
        return p.avgScore;
      default:
        return 0;
    }
  }

  String _formatValue(double v) {
    if (metricIndex == 2) return '${v.round()}%';
    return '${v.round()}';
  }

  @override
  Widget build(BuildContext context) {
    final values = points.map(_getValue).toList();
    final maxVal = values.fold(0.0, (m, v) => v > m ? v : m);
    if (maxVal == 0) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('Ma\'lumot yo\'q', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.asMap().entries.map((entry) {
          final point = entry.value;
          final val = _getValue(point);
          final ratio = maxVal > 0 ? val / maxVal : 0.0;
          final barH = ratio * 110;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (val > 0)
                    Text(
                      _formatValue(val),
                      style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    height: barH.clamp(4.0, 110.0),
                    decoration: BoxDecoration(
                      color: val > 0
                          ? color.withValues(alpha: 0.85)
                          : Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Umumiy statistika 3 ta karta ───
class _SummaryCards extends StatelessWidget {
  final List<TeacherChartPoint> points;
  const _SummaryCards({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final totalActs = points.fold(0, (s, p) => s + p.totalActivities);
    final maxActive =
        points.fold(0, (m, p) => p.activeStudents > m ? p.activeStudents : m);
    final scores =
        points.where((p) => p.avgScore > 0).map((p) => p.avgScore).toList();
    final avgScore =
        scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

    return Row(
      children: [
        _StatCard(
          icon: Icons.quiz_rounded,
          label: 'Jami mashqlar',
          value: '$totalActs',
          color: AppColors.secondary,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.people_rounded,
          label: 'Eng faol kun',
          value: '$maxActive o\'q',
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.star_rounded,
          label: 'O\'rt. ball',
          value: '${avgScore.round()}%',
          color: AppColors.success,
        ),
      ],
    );
  }
}

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
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ko'rsatkich ma'lumoti ───
class _MetricInfo {
  final String label;
  final Color color;
  final IconData icon;
  const _MetricInfo(this.label, this.color, this.icon);
}
