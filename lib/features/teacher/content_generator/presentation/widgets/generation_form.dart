// lib/features/teacher/content_generator/presentation/widgets/generation_form.dart
import 'package:flutter/material.dart';

class GenerationForm extends StatefulWidget {
  final String contentType;
  final void Function({
    required String topic,
    required String language,
    required String level,
    Map<String, dynamic>? extra,
  }) onGenerate;

  const GenerationForm({
    super.key,
    required this.contentType,
    required this.onGenerate,
  });

  @override
  State<GenerationForm> createState() => _GenerationFormState();
}

class _GenerationFormState extends State<GenerationForm> {
  final _topicCtrl = TextEditingController();
  String _language = 'de';
  String _level = 'A1';
  int _count = 5;

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _topicCtrl,
          decoration: InputDecoration(
            labelText: 'Mavzu',
            hintText: 'Masalan: Einkaufen, Familie...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _language,
          decoration: const InputDecoration(
            labelText: 'Til',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'de', child: Text('🇩🇪 Nemis')),
            DropdownMenuItem(value: 'en', child: Text('🇬🇧 Ingliz')),
            DropdownMenuItem(value: 'ru', child: Text('🇷🇺 Rus')),
          ],
          onChanged: (v) => setState(() => _language = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _level,
          decoration: const InputDecoration(
            labelText: 'Daraja',
            border: OutlineInputBorder(),
          ),
          items: ['A1', 'A2', 'B1', 'B2', 'C1']
              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
              .toList(),
          onChanged: (v) => setState(() => _level = v!),
        ),
        if (widget.contentType == 'quiz' ||
            widget.contentType == 'flashcard') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Soni:'),
              Expanded(
                child: Slider(
                  value: _count.toDouble(),
                  min: 3,
                  max: 20,
                  divisions: 17,
                  label: '$_count',
                  onChanged: (v) => setState(() => _count = v.round()),
                ),
              ),
              Text('$_count'),
            ],
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _topicCtrl.text.isEmpty
              ? null
              : () => widget.onGenerate(
                    topic: _topicCtrl.text.trim(),
                    language: _language,
                    level: _level,
                    extra: {'count': _count},
                  ),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('AI bilan yaratish'),
        ),
      ],
    );
  }
}
