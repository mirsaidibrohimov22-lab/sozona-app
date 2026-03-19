// lib/features/student/artikel/data/models/artikel_model.dart
import 'package:my_first_app/features/student/artikel/domain/entities/artikel_word.dart';

class ArtikelWordModel extends ArtikelWord {
  const ArtikelWordModel({
    required super.id,
    required super.word,
    required super.artikel,
    super.plural,
    super.example,
    required super.translation,
    super.imageUrl,
    super.difficulty,
    super.mastery,
  });

  factory ArtikelWordModel.fromFirestore(Map<String, dynamic> d, String id) =>
      ArtikelWordModel(
        id: id,
        word: d['word'] ?? '',
        artikel: d['artikel'] ?? 'der',
        plural: d['plural'] as String?,
        example: d['example'] as String?,
        translation: d['translation'] ?? '',
        imageUrl: d['imageUrl'] as String?,
        difficulty: (d['difficulty'] as num?)?.toDouble() ?? 1.0,
        mastery: (d['mastery'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        'word': word,
        'artikel': artikel,
        'plural': plural,
        'example': example,
        'translation': translation,
        'imageUrl': imageUrl,
        'difficulty': difficulty,
        'mastery': mastery,
      };
}
