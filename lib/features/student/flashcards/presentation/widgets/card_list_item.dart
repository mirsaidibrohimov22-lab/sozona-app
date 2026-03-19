import 'package:flutter/material.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';

class CardListItem extends StatelessWidget {
  final FlashcardEntity card;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CardListItem({
    super.key,
    required this.card,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(card.front, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(card.back),
        trailing: onDelete != null
            ? IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete)
            : null,
      ),
    );
  }
}
