// lib/features/student/artikel/data/datasources/artikel_local_datasource.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_first_app/features/student/artikel/domain/entities/artikel_word.dart';

abstract class ArtikelLocalDataSource {
  Future<List<ArtikelWord>> getCachedWords();
  Future<void> cacheWords(List<ArtikelWord> words);
  Future<void> savePendingAnswer(String wordId, String selectedArtikel);
  Future<Map<String, String>> getPendingAnswers();
  Future<void> clearPendingAnswers();
}

class ArtikelLocalDataSourceImpl implements ArtikelLocalDataSource {
  static const _wordsBox = 'artikel_words';
  static const _pendingBox = 'artikel_pending';

  @override
  Future<List<ArtikelWord>> getCachedWords() async {
    try {
      final box = await Hive.openBox(_wordsBox);
      final raw = box.get('words') as String?;
      if (raw == null) return [];
      final list = json.decode(raw) as List;
      return list.map((e) => _fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheWords(List<ArtikelWord> words) async {
    final box = await Hive.openBox(_wordsBox);
    final data = words
        .map(
          (w) => {
            'id': w.id,
            'word': w.word,
            'artikel': w.artikel,
            'plural': w.plural,
            'example': w.example,
            'translation': w.translation,
            'imageUrl': w.imageUrl,
            'difficulty': w.difficulty,
            'mastery': w.mastery,
          },
        )
        .toList();
    await box.put('words', json.encode(data));
  }

  @override
  Future<void> savePendingAnswer(String wordId, String selectedArtikel) async {
    final box = await Hive.openBox(_pendingBox);
    await box.put(wordId, selectedArtikel);
  }

  @override
  Future<Map<String, String>> getPendingAnswers() async {
    final box = await Hive.openBox(_pendingBox);
    return {for (final k in box.keys) k.toString(): box.get(k) as String};
  }

  @override
  Future<void> clearPendingAnswers() async {
    final box = await Hive.openBox(_pendingBox);
    await box.clear();
  }

  ArtikelWord _fromMap(Map<String, dynamic> m) => ArtikelWord(
        id: m['id'],
        word: m['word'],
        artikel: m['artikel'],
        plural: m['plural'],
        example: m['example'],
        translation: m['translation'],
        imageUrl: m['imageUrl'],
        difficulty: (m['difficulty'] as num?)?.toDouble() ?? 1.0,
        mastery: (m['mastery'] as num?)?.toDouble() ?? 0.0,
      );
}
