// lib/features/student/artikel/presentation/widgets/artikel_card.dart
import 'package:flutter/material.dart';
import 'package:my_first_app/features/student/artikel/domain/entities/artikel_word.dart';

class ArtikelCard extends StatelessWidget {
  final ArtikelWord word;
  const ArtikelCard({super.key, required this.word});

  Color get _artikelColor {
    switch (word.artikel) {
      case 'der':
        return Colors.blue;
      case 'die':
        return Colors.red;
      case 'das':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _artikelColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            word.artikel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          word.word,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(word.translation),
        trailing: word.plural != null
            ? Text(
                '(${word.plural})',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              )
            : null,
      ),
    );
  }
}
