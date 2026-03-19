// QO'YISH: lib/features/learning_loop/presentation/widgets/session_type_indicator.dart
// So'zona — Sessiya turi ko'rsatgichi

import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/micro_session.dart';

class SessionTypeIndicator extends StatelessWidget {
  final SessionType sessionType;

  const SessionTypeIndicator({super.key, required this.sessionType});

  @override
  Widget build(BuildContext context) {
    final isFlashcardQuiz = sessionType == SessionType.flashcardQuiz;

    return Row(
      children: [
        _ActivityChip(
          icon: '📚',
          label: 'Flashcard',
          isActive: isFlashcardQuiz,
        ),
        const SizedBox(width: 8),
        _ActivityChip(
          icon: '❓',
          label: 'Quiz',
          isActive: isFlashcardQuiz,
        ),
        const SizedBox(width: 16),
        const Text('yoki', style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 16),
        _ActivityChip(
          icon: '🎧',
          label: 'Listening',
          isActive: !isFlashcardQuiz,
        ),
        const SizedBox(width: 8),
        _ActivityChip(
          icon: '🗣',
          label: 'Speaking',
          isActive: !isFlashcardQuiz,
        ),
      ],
    );
  }
}

class _ActivityChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;

  const _ActivityChip({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? AppColors.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
