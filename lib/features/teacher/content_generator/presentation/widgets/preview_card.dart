// lib/features/teacher/content_generator/presentation/widgets/preview_card.dart
import 'package:flutter/material.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';

class PreviewCard extends StatelessWidget {
  final GeneratedContent content;
  final VoidCallback? onPublish;
  final VoidCallback? onEdit;

  const PreviewCard({
    super.key,
    required this.content,
    this.onPublish,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeChip(content.type.name),
                const SizedBox(width: 8),
                _LevelChip(content.level),
                const Spacer(),
                Text(
                  content.language.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (content.description.isNotEmpty)
              Text(
                content.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const Divider(height: 20),
            Text(
              '${content.itemCount} ta element',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onEdit != null)
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Tahrirlash'),
                  ),
                const Spacer(),
                if (onPublish != null)
                  ElevatedButton.icon(
                    onPressed: onPublish,
                    icon: const Icon(Icons.publish, size: 16),
                    label: const Text('Nashr qilish'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip(this.type);
  @override
  Widget build(BuildContext context) {
    final labels = {
      'quiz': 'Quiz',
      'flashcard': 'Flashcard',
      'listening': 'Listening',
      'speaking': 'Speaking',
    };
    return Chip(
      label: Text(labels[type] ?? type, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String level;
  const _LevelChip(this.level);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          level,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
}
