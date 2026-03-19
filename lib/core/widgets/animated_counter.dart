// lib/core/widgets/animated_counter.dart
// So'zona — Animatsiyali raqam widgeti
// Streak, XP, ball ko'rsatishda ishlatiladi

import 'package:flutter/material.dart';

/// Animatsiyali raqam ko'rsatuvchi widget
/// Qiymat o'zgarganda silliq animatsiya bilan yangilanadi
class AnimatedCounter extends StatelessWidget {
  /// Ko'rsatiladigan qiymat
  final int value;

  /// Matn stili
  final TextStyle? style;

  /// Animatsiya davomiyligi
  final Duration duration;

  /// Prefiks (masalan: "+" yoki "$")
  final String? prefix;

  /// Suffiks (masalan: " XP" yoki " kun")
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          '${prefix ?? ''}$animatedValue${suffix ?? ''}',
          style: style ??
              Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
        );
      },
    );
  }
}

/// Animatsiyali progress bar
class AnimatedProgressBar extends StatelessWidget {
  /// Progress qiymati (0.0 dan 1.0 gacha)
  final double value;

  /// Bar rangi
  final Color color;

  /// Fon rangi
  final Color? backgroundColor;

  /// Bar balandligi
  final double height;

  /// Animatsiya davomiyligi
  final Duration duration;

  /// Burchak radiusi
  final double borderRadius;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor,
    this.height = 8,
    this.duration = const Duration(milliseconds: 800),
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animatedValue,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        );
      },
    );
  }
}
