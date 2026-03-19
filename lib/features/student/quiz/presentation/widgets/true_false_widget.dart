// QO'YISH: lib/features/student/quiz/presentation/widgets/true_false_widget.dart
import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';

class TrueFalseWidget extends StatelessWidget {
  final String? selectedAnswer;
  final String? correctAnswer;
  final Function(String) onAnswer;

  const TrueFalseWidget({
    super.key,
    this.selectedAnswer,
    this.correctAnswer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Btn(
            label: 'To\'g\'ri ✓',
            value: 'True',
            selected: selectedAnswer,
            correct: correctAnswer,
            onTap: onAnswer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Btn(
            label: 'Noto\'g\'ri ✗',
            value: 'False',
            selected: selectedAnswer,
            correct: correctAnswer,
            onTap: onAnswer,
          ),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final String label, value;
  final String? selected, correct;
  final Function(String) onTap;
  const _Btn({
    required this.label,
    required this.value,
    this.selected,
    this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    final isCorrect = correct == value;
    final isWrong = isSelected && correct != null && !isCorrect;
    final Color color = correct != null
        ? (isCorrect
            ? AppColors.success
            : (isWrong ? AppColors.error : Colors.grey.shade300))
        : (isSelected ? AppColors.primary : Colors.grey.shade300);

    return GestureDetector(
      onTap: correct == null ? () => onTap(value) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ),
    );
  }
}
