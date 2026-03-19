// QO'YISH: lib/features/student/quiz/presentation/widgets/quiz_progress_bar.dart
import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';

class QuizProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const QuizProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: total > 0 ? current / total : 0,
      
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 4,
    );
  }
}
