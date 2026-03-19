// lib/features/student/quiz/presentation/widgets/mcq_widget.dart
// So'zona — Ko'p tanlovli savol widget
// ✅ FIX: Variantlar shuffle qilinadi — to'g'ri javob doim birinchi turmasin
// ✅ Shuffle bir marta bajariladi (initState'da) — har rebuild'da o'zgarmaydi

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';

class McqWidget extends StatefulWidget {
  final List<String> options;
  final String? selectedAnswer;
  final String? correctAnswer;
  final Function(String) onAnswer;
  // Savolni aniqlash uchun — har savol uchun bir xil tartib
  final String questionId;

  const McqWidget({
    super.key,
    required this.options,
    this.selectedAnswer,
    this.correctAnswer,
    required this.onAnswer,
    this.questionId = '',
  });

  @override
  State<McqWidget> createState() => _McqWidgetState();
}

class _McqWidgetState extends State<McqWidget> {
  late List<String> _shuffledOptions;

  @override
  void initState() {
    super.initState();
    _shuffledOptions = _shuffle(widget.options, widget.questionId);
  }

  @override
  void didUpdateWidget(McqWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Savol o'zgarganda qayta shuffle
    if (oldWidget.questionId != widget.questionId ||
        oldWidget.options.length != widget.options.length) {
      _shuffledOptions = _shuffle(widget.options, widget.questionId);
    }
  }

  // ✅ Deterministik shuffle — bir xil savolda har doim bir xil tartib
  // Random.seed(questionId hashCode) — rebuild bo'lsa ham tartib o'zgarmaydi
  List<String> _shuffle(List<String> options, String questionId) {
    final list = List<String>.from(options);
    // questionId bo'sh bo'lsa — vaqt asosida random
    final seed = questionId.isNotEmpty
        ? questionId.hashCode
        : DateTime.now().millisecondsSinceEpoch;
    final rng = Random(seed);
    for (int i = list.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _shuffledOptions.map((opt) {
        final isSelected = widget.selectedAnswer == opt;
        final isCorrect = widget.correctAnswer == opt;
        final isWrong =
            isSelected && widget.correctAnswer != null && !isCorrect;

        Color borderColor = Colors.grey.shade300;
        Color bgColor = Colors.white;
        Color textColor = Colors.black87;
        IconData? icon;

        if (widget.correctAnswer != null) {
          if (isCorrect) {
            borderColor = AppColors.success;
            bgColor = AppColors.success.withValues(alpha: 0.08);
            textColor = AppColors.success;
            icon = Icons.check_circle;
          }
          if (isWrong) {
            borderColor = AppColors.error;
            bgColor = AppColors.error.withValues(alpha: 0.08);
            textColor = AppColors.error;
            icon = Icons.cancel;
          }
        } else if (isSelected) {
          borderColor = AppColors.primary;
          bgColor = AppColors.primary.withValues(alpha: 0.08);
          textColor = AppColors.primary;
        }

        return GestureDetector(
          onTap:
              widget.correctAnswer == null ? () => widget.onAnswer(opt) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: borderColor, width: isSelected ? 2 : 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    color: isCorrect ? AppColors.success : AppColors.error,
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
