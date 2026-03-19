// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Suggestion Chip Widget
// QO'YISH: lib/features/student/ai_chat/presentation/widgets/suggestion_chip.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:my_first_app/core/theme/app_colors.dart';

class SuggestionChipWidget extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SuggestionChipWidget({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: onTap,
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
