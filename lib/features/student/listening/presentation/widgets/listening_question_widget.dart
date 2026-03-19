// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Listening Question Widget
// QO'YISH: lib/features/student/listening/presentation/widgets/listening_question_widget.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/features/student/listening/domain/entities/listening_exercise.dart';

/// Listening Question Widget — listening savol ko'rsatish
class ListeningQuestionWidget extends StatelessWidget {
  final ListeningQuestion question;
  final String? selectedAnswer;
  final Function(String) onAnswerSelected;

  const ListeningQuestionWidget({
    super.key,
    required this.question,
    this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timestamp (agar bo'lsa)
        if (question.timestamp != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  _formatTimestamp(question.timestamp!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Savol matni
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Savol turiga qarab widget
        if (question.type == 'mcq' && question.options != null)
          _buildMCQOptions()
        else if (question.type == 'true_false')
          _buildTrueFalseButtons()
        else if (question.type == 'short_answer')
          _buildShortAnswerInput(),
      ],
    );
  }

  Widget _buildMCQOptions() {
    return Column(
      children: question.options!.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = selectedAnswer == option;
        final optionLetter = String.fromCharCode(65 + index); // A, B, C...

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onAnswerSelected(option),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.05),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        optionLetter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseButtons() {
    return Row(
      children: [
        Expanded(
          child: _TrueFalseButton(
            label: 'TO\'G\'RI',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            value: 'true',
            isSelected: selectedAnswer?.toLowerCase() == 'true',
            onTap: () => onAnswerSelected('true'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TrueFalseButton(
            label: 'NOTO\'G\'RI',
            icon: Icons.cancel_outlined,
            color: Colors.red,
            value: 'false',
            isSelected: selectedAnswer?.toLowerCase() == 'false',
            onTap: () => onAnswerSelected('false'),
          ),
        ),
      ],
    );
  }

  Widget _buildShortAnswerInput() {
    return TextField(
      onChanged: onAnswerSelected,
      decoration: InputDecoration(
        hintText: 'Javobingizni yozing...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  String _formatTimestamp(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

class _TrueFalseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrueFalseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
