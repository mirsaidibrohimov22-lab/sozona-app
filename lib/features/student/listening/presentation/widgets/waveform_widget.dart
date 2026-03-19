import 'dart:math' show sin;
// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Waveform Widget
// QO'YISH: lib/features/student/listening/presentation/widgets/waveform_widget.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:my_first_app/core/theme/app_colors.dart';

/// Waveform Widget — audio to'lqinlarini ko'rsatish
class WaveformWidget extends StatelessWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final int barCount;

  const WaveformWidget({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    this.barCount = 50,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalDuration.inSeconds > 0
        ? currentPosition.inSeconds / totalDuration.inSeconds
        : 0.0;

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          final barProgress = index / barCount;
          final isPlayed = barProgress <= progress;
          final height = _getBarHeight(index, barCount);

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: height,
              decoration: BoxDecoration(
                color: isPlayed ? AppColors.primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  double _getBarHeight(int index, int total) {
    // To'lqin shakli yaratish (sinusoidal pattern)
    final normalizedIndex = index / total;
    const amplitude = 30.0;
    const frequency = 2.0;

    final height = amplitude *
        (0.5 + 0.5 * sin(normalizedIndex * frequency * 3.14159).abs());

    return height.clamp(10.0, 60.0);
  }
}
