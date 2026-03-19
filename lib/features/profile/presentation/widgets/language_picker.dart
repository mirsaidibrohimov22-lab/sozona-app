// QO'YISH: lib/features/profile/presentation/widgets/language_picker.dart
// So'zona — Til tanlash widget

import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';

class LanguagePicker extends StatelessWidget {
  final String selected; // "en" | "de"
  final ValueChanged<String> onChanged;

  const LanguagePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LangOption(
          code: 'en',
          label: '🇬🇧 English',
          isSelected: selected == 'en',
          onTap: () => onChanged('en'),
        ),
        const SizedBox(width: 12),
        _LangOption(
          code: 'de',
          label: '🇩🇪 Deutsch',
          isSelected: selected == 'de',
          onTap: () => onChanged('de'),
        ),
      ],
    );
  }
}

class _LangOption extends StatelessWidget {
  final String code, label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangOption({
    required this.code,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
