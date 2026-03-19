// lib/core/widgets/language_selector.dart
import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final String selected;
  final List<String> languages;
  final ValueChanged<String> onChanged;

  const LanguageSelector({
    super.key,
    required this.selected,
    required this.languages,
    required this.onChanged,
  });

  static const _flags = {
    'uz': '🇺🇿',
    'ru': '🇷🇺',
    'en': '🇬🇧',
    'de': '🇩🇪',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: languages.map((lang) {
        final isSelected = lang == selected;
        return ChoiceChip(
          label: Text('${_flags[lang] ?? ''} ${lang.toUpperCase()}'),
          selected: isSelected,
          onSelected: (_) => onChanged(lang),
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        );
      }).toList(),
    );
  }
}
