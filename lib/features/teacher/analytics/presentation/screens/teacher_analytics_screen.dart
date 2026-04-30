// lib/features/teacher/analytics/presentation/screens/teacher_analytics_screen.dart
// So'zona — Teacher Analytics Screen
// ✅ YANGI: Per-student zaif soha grafigi
// ✅ YANGI: Qiynalayotgan o'quvchilar alohida bo'lim
// ✅ YANGI: Har bir o'quvchi uchun skill bar chart
// ✅ FIX: avgScore *100 kerak emas (0–100 diapazonda)
// ✅ FIX: withOpacity → withValues

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/teacher/analytics/domain/entities/teacher_analytics.dart';
import 'package:my_first_app/features/teacher/analytics/presentation/providers/teacher_analytics_provider.dart';
import 'package:my_first_app/features/teacher/analytics/presentation/widgets/ai_advice_card.dart';
import 'package:my_first_app/features/teacher/analytics/presentation/widgets/performance_chart.dart';

class TeacherAnalyticsScreen extends ConsumerWidget {
  final String classId;
  const TeacherAnalyticsScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(classAnalyticsProvider(classId));
    return Scaffold(
      appBar: AppBar(title: const Text('Sinf Analitikasi')),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Analitika yuklanmadi',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(classAnalyticsProvider(classId)),
                  child: const Text('Qayta yuklash'),
                ),
              ],
            ),
          ),
        ),
        data: (analytics) => _buildContent(context, analytics, ref),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ClassAnalytics analytics, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. UMUMIY STATISTIKA ──
          _SectionTitle('Sinf Umumiy Ko\'rsatkichi'),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatCard(
                "O'quvchilar",
                '${analytics.totalStudents}',
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _StatCard(
                'Faol (7 kun)',
                '${analytics.activeStudents}',
                Icons.bolt,
                Colors.orange,
              ),
              const SizedBox(width: 8),
              _StatCard(
                "O'rtacha",
                '${analytics.avgScore.round()}%',
                Icons.score,
                _scoreColor(analytics.avgScore),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 2. KO'NIKMALAR BREAKDOWN (sinf uchun) ──
          _SectionTitle("Sinf Ko'nikmalari"),
          const SizedBox(height: 8),
          PerformanceChart(skillBreakdown: analytics.skillBreakdown),
          const SizedBox(height: 20),

          // ── 3. QIYNALAYOTGAN O'QUVCHILAR ──
          if (analytics.struglingStudents.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                _SectionTitle('Qiynalayotgan O\'quvchilar'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${analytics.struglingStudents.length} ta o\'quvchi 60% dan past natija ko\'rsatmoqda',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            ...analytics.struglingStudents.map(
              (s) => _StudentCard(student: s, isStruggling: true),
            ),
            const SizedBox(height: 20),
          ],

          // ── 4. BARCHA O'QUVCHILAR KO'NIKMALAR GRAFIGI ──
          if (analytics.studentBreakdowns.isNotEmpty) ...[
            _SectionTitle("O'quvchilar Bo'yicha Tahlil"),
            const SizedBox(height: 4),
            Text(
              'Har bir o\'quvchining ko\'nikma natijalari',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            ...analytics.studentBreakdowns.map(
              (s) => _StudentCard(student: s, isStruggling: false),
            ),
            const SizedBox(height: 20),
          ],

          // ── 5. AI TAVSIYALAR ──
          if (analytics.aiRecommendations.isNotEmpty) ...[
            _SectionTitle('AI Tavsiyalar'),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: analytics.aiRecommendations
                      .map(
                        (rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡 ', style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(rec,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── 6. AI O'QITUVCHI MASLAHATI ──
          AiAdviceCard(classId: classId),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}

// ═══════════════════════════════════════════════════════════════
// YORDAMCHI WIDGET'LAR
// ═══════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18, color: color),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// O'QUVCHI KARTASI — ko'nikma bar chart bilan
// ═══════════════════════════════════════════════════════════════
class _StudentCard extends StatefulWidget {
  final StudentWeakAreas student;
  final bool isStruggling;

  const _StudentCard({required this.student, required this.isStruggling});

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final hasData = s.skillScores.isNotEmpty;

    final borderColor = widget.isStruggling
        ? Colors.orange.withValues(alpha: 0.4)
        : Colors.grey.withValues(alpha: 0.2);

    final bgColor = widget.isStruggling
        ? Colors.orange.withValues(alpha: 0.03)
        : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // ── Sarlavha satr ──
          InkWell(
            onTap:
                hasData ? () => setState(() => _expanded = !_expanded) : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _avatarColor(s.avgScore).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        s.displayName.isNotEmpty
                            ? s.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _avatarColor(s.avgScore),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Ism va holat
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.displayName,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!s.isRecentlyActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Faol emas',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '${s.totalActivities} mashq',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            if (s.weakestSkill.isNotEmpty) ...[
                              const Text(' • ',
                                  style: TextStyle(color: Colors.grey)),
                              Text(
                                'Zaif: ${_skillLabel(s.weakestSkill)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: s.needsAttention
                                        ? Colors.red
                                        : Colors.orange),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Umumiy ball
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${s.avgScore.round()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _scoreColor(s.avgScore),
                        ),
                      ),
                      if (hasData)
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Ko'nikma bar chart (kengaytirilganda ko'rinadi) ──
          if (_expanded && hasData)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(height: 16),
                  ...s.skillScores.entries.map((entry) {
                    final pct = entry.value.clamp(0.0, 100.0);
                    final color = _scoreColor(pct);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(_skillIcon(entry.key), size: 16, color: color),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            child: Text(
                              _skillLabel(entry.key),
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: pct / 100,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 36,
                            child: Text(
                              '${pct.round()}%',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Zaif mavzular
                  if (s.weakTopics.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Divider(height: 8),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.flag_outlined,
                            size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Zaif mavzular: ${s.weakTopics.join(', ')}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _avatarColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _scoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  String _skillLabel(String skill) {
    switch (skill) {
      case 'speaking':
        return 'Gapirish';
      case 'listening':
        return 'Tinglash';
      case 'flashcard':
        return 'Lug\'at';
      default:
        return 'Quiz';
    }
  }

  IconData _skillIcon(String skill) {
    switch (skill) {
      case 'speaking':
        return Icons.mic_outlined;
      case 'listening':
        return Icons.headphones_outlined;
      case 'flashcard':
        return Icons.style_outlined;
      default:
        return Icons.quiz_outlined;
    }
  }
}

// ClassAnalytics extension — struglingStudents getter uchun
extension on ClassAnalytics {
  List<StudentWeakAreas> get struglingStudents => studentBreakdowns
      .where((s) => s.needsAttention && s.totalActivities > 0)
      .toList()
    ..sort((a, b) => a.avgScore.compareTo(b.avgScore));
}
