// lib/features/teacher/analytics/presentation/widgets/performance_chart.dart
//
// ✅ FIX 1: e.value.clamp(0, 1) → e.value/100 (qiymat 0–100 oraliq)
// ✅ FIX 2: withOpacity → withValues (deprecation warning yo'qoladi)
// ✅ FIX 3: double quotes → single quotes (lint warning)

import 'package:flutter/material.dart';

class PerformanceChart extends StatelessWidget {
  final Map<String, double> skillBreakdown;
  const PerformanceChart({super.key, required this.skillBreakdown});

  static const _labels = {
    'quiz': 'Quiz / Grammatika',
    'speaking': 'Gapirish',
    'listening': 'Tinglash',
    'flashcard': 'Lug\'at',
  };

  static const _icons = {
    'quiz': Icons.quiz_outlined,
    'speaking': Icons.mic_outlined,
    'listening': Icons.headphones_outlined,
    'flashcard': Icons.style_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (skillBreakdown.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Hali ma\'lumot yo\'q',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final sorted = skillBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: sorted.map((e) {
            // ✅ FIX: qiymat 0–100 → progress uchun /100
            final pct = e.value.clamp(0.0, 100.0);
            final progress = pct / 100.0;

            final color = pct >= 70
                ? Colors.green
                : pct >= 50
                    ? Colors.orange
                    : Colors.red;

            final label = _labels[e.key] ?? e.key;
            final icon = _icons[e.key] ?? Icons.school_outlined;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        // ✅ FIX: withOpacity → withValues
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${pct.round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
