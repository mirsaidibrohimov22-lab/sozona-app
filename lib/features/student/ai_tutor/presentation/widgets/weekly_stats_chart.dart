// lib/features/student/ai_tutor/presentation/widgets/weekly_stats_chart.dart
// Haftalik statistika — BarChart (fl_chart)

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/features/student/ai_tutor/presentation/providers/ai_tutor_provider.dart';

class WeeklyStatsChart extends StatelessWidget {
  final WeeklyStats stats;

  const WeeklyStatsChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.lessonsCompleted == 0) return _emptyState(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Yuqori qism — 3 ta raqam
        Row(
          children: [
            _StatChip(
              label: 'Darslar',
              value: '${stats.lessonsCompleted}',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSizes.spacingSm),
            _StatChip(
              label: 'Daqiqa',
              value: '${stats.totalMinutes}',
              icon: Icons.timer_outlined,
              color: AppColors.secondary,
            ),
            const SizedBox(width: AppSizes.spacingSm),
            _StatChip(
              label: 'O\'rtacha',
              value: '${stats.avgScore}%',
              icon: Icons.star_outline_rounded,
              color: AppColors.accent,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingLg),

        // BarChart — skill bo'yicha
        if (stats.skillBreakdown.isNotEmpty) ...[
          Text('Skill bo\'yicha ball',
              style: AppTextStyles.titleSmall
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSizes.spacingMd),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: 100,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const labels = ['Quiz', 'Listen', 'Speak', 'Flash'];
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: _buildBars(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        Theme.of(context).colorScheme.surface,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.toInt()}%',
                      AppTextStyles.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        // Zaif mavzular
        if (stats.topMistakeTags.isNotEmpty) ...[
          const SizedBox(height: AppSizes.spacingLg),
          Text('Zaif tomonlar',
              style: AppTextStyles.titleSmall
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSizes.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: stats.topMistakeTags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Text(
                  tag,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accentDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  List<BarChartGroupData> _buildBars() {
    const keys = ['quiz', 'listening', 'speaking', 'flashcard'];
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
    ];

    return List.generate(keys.length, (i) {
      final sk = stats.skillBreakdown[keys[i]];
      final score = (sk?['avgScore'] ?? 0).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: score,
            color: colors[i],
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: colors[i].withOpacity(0.08),
            ),
          ),
        ],
      );
    });
  }

  Widget _emptyState(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 48,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(
              'Hali ma\'lumot yo\'q.\nBirinchi darsni tugatgach statistika chiqadi.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(value,
                  style: AppTextStyles.titleMedium
                      .copyWith(color: color, fontWeight: FontWeight.w700)),
              Text(label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: color.withOpacity(0.7))),
            ],
          ),
        ),
      );
}
