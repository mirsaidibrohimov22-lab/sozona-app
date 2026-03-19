// QO'YISH: lib/features/learning_loop/presentation/widgets/session_timer.dart
// So'zona — Sessiya taymer widget

import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';

class SessionTimer extends StatelessWidget {
  final int secondsElapsed;
  static const int totalSeconds = 10 * 60; // 10 daqiqa

  const SessionTimer({super.key, required this.secondsElapsed});

  String get _timeDisplay {
    final remaining = (totalSeconds - secondsElapsed).clamp(0, totalSeconds);
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress => (secondsElapsed / totalSeconds).clamp(0.0, 1.0);

  Color get _timerColor {
    if (_progress > 0.8) return AppColors.error;
    if (_progress > 0.6) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value: _progress,
            strokeWidth: 3,
            
            valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _timeDisplay,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _timerColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
