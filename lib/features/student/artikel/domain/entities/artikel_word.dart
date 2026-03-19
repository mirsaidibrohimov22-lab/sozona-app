// lib/features/student/artikel/domain/entities/artikel_word.dart
import 'package:equatable/equatable.dart';

enum Artikel { der, die, das }

class ArtikelWord extends Equatable {
  final String id;
  final String word;
  final String artikel; // 'der' | 'die' | 'das'
  final String? plural;
  final String? example;
  final String translation;
  final String? imageUrl;
  final double difficulty;
  final double mastery;

  const ArtikelWord({
    required this.id,
    required this.word,
    required this.artikel,
    this.plural,
    this.example,
    required this.translation,
    this.imageUrl,
    this.difficulty = 1.0,
    this.mastery = 0.0,
  });

  @override
  List<Object?> get props => [id];
}
