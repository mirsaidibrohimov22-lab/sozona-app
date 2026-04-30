// lib/features/premium/data/services/book_service.dart
// So'zona — Kitob Service
// Firebase Storage dan JSON yuklab oladi, Hive da saqlaydi (offline)

import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ═══════════════════════════════════════════════════════════════
// MODELLAR
// ═══════════════════════════════════════════════════════════════

class BookVocabulary {
  final String word;
  final String translation;
  final String example;

  const BookVocabulary({
    required this.word,
    required this.translation,
    required this.example,
  });

  factory BookVocabulary.fromMap(Map<String, dynamic> m) => BookVocabulary(
        word: m['word'] as String? ?? '',
        translation: m['translation'] as String? ?? '',
        example: m['example'] as String? ?? '',
      );
}

class BookGrammar {
  final String title;
  final String explanation;
  final List<String> examples;

  const BookGrammar({
    required this.title,
    required this.explanation,
    required this.examples,
  });

  factory BookGrammar.fromMap(Map<String, dynamic> m) => BookGrammar(
        title: m['title'] as String? ?? '',
        explanation: m['explanation'] as String? ?? '',
        examples: List<String>.from(m['examples'] as List? ?? []),
      );
}

class BookDialogueLine {
  final String speaker;
  final String text;

  const BookDialogueLine({required this.speaker, required this.text});

  factory BookDialogueLine.fromMap(Map<String, dynamic> m) => BookDialogueLine(
        speaker: m['speaker'] as String? ?? '',
        text: m['text'] as String? ?? '',
      );
}

class BookDialogue {
  final String title;
  final List<BookDialogueLine> lines;

  const BookDialogue({required this.title, required this.lines});

  factory BookDialogue.fromMap(Map<String, dynamic> m) => BookDialogue(
        title: m['title'] as String? ?? '',
        lines: (m['lines'] as List? ?? [])
            .map((e) =>
                BookDialogueLine.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class BookExerciseQuestion {
  final String question;
  final String answer;
  final List<String> options;

  const BookExerciseQuestion({
    required this.question,
    required this.answer,
    this.options = const [],
  });

  factory BookExerciseQuestion.fromMap(Map<String, dynamic> m) =>
      BookExerciseQuestion(
        question: m['question'] as String? ?? '',
        answer: m['answer'] as String? ?? '',
        options: List<String>.from(m['options'] as List? ?? []),
      );
}

class BookExercise {
  final String type;
  final String instruction;
  final List<BookExerciseQuestion> questions;

  const BookExercise({
    required this.type,
    required this.instruction,
    required this.questions,
  });

  factory BookExercise.fromMap(Map<String, dynamic> m) => BookExercise(
        type: m['type'] as String? ?? '',
        instruction: m['instruction'] as String? ?? '',
        questions: (m['questions'] as List? ?? [])
            .map((e) => BookExerciseQuestion.fromMap(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class BookChapter {
  final int id;
  final String title;
  final BookGrammar grammar;
  final List<BookVocabulary> vocabulary;
  final BookDialogue dialogue;
  final String readingTitle;
  final String readingText;
  final List<BookExercise> exercises;

  const BookChapter({
    required this.id,
    required this.title,
    required this.grammar,
    required this.vocabulary,
    required this.dialogue,
    required this.readingTitle,
    required this.readingText,
    required this.exercises,
  });

  factory BookChapter.fromMap(Map<String, dynamic> m) {
    final readingMap = m['reading'] as Map? ?? {};
    return BookChapter(
      id: m['id'] as int? ?? 0,
      title: m['title'] as String? ?? '',
      grammar: BookGrammar.fromMap(
          Map<String, dynamic>.from(m['grammar'] as Map? ?? {})),
      vocabulary: (m['vocabulary'] as List? ?? [])
          .map((e) =>
              BookVocabulary.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      dialogue: BookDialogue.fromMap(
          Map<String, dynamic>.from(m['dialogue'] as Map? ?? {})),
      readingTitle: readingMap['title'] as String? ?? '',
      readingText: readingMap['text'] as String? ?? '',
      exercises: (m['exercises'] as List? ?? [])
          .map((e) => BookExercise.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class BookModel {
  final String id;
  final String language;
  final String level;
  final String title;
  final String description;
  final List<BookChapter> chapters;

  const BookModel({
    required this.id,
    required this.language,
    required this.level,
    required this.title,
    required this.description,
    required this.chapters,
  });

  factory BookModel.fromMap(Map<String, dynamic> m) => BookModel(
        id: m['id'] as String? ?? '',
        language: m['language'] as String? ?? '',
        level: m['level'] as String? ?? '',
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        chapters: (m['chapters'] as List? ?? [])
            .map(
                (e) => BookChapter.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

// ═══════════════════════════════════════════════════════════════
// SERVICE
// ═══════════════════════════════════════════════════════════════

class BookService {
  BookService._();
  static final instance = BookService._();

  static const String _boxName = 'books_cache';
  static const Duration _cacheAge = Duration(days: 30);

  // ✅ Firebase Storage path: books/english/english_a1.json
  // Fayl nomlari Firebase da: english_a1.json, german_b2.json ...
  String _storagePath(String language, String level) =>
      'books/$language/${language}_${level.toLowerCase()}.json';

  String _cacheKey(String language, String level) =>
      'book_${language}_${level.toLowerCase()}';

  String _timestampKey(String language, String level) =>
      'book_${language}_${level.toLowerCase()}_ts';

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<dynamic>(_boxName);
    return Hive.openBox<dynamic>(_boxName);
  }

  // Cache dan o'qish
  Future<BookModel?> _fromCache(String language, String level) async {
    try {
      final box = await _box();
      final ts = box.get(_timestampKey(language, level)) as int?;
      if (ts == null) return null;
      final age =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
      if (age > _cacheAge) return null;
      final json = box.get(_cacheKey(language, level)) as String?;
      if (json == null) return null;
      return BookModel.fromMap(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('⚠️ BookService._fromCache: $e');
      return null;
    }
  }

  // Cache ga yozish
  Future<void> _toCache(String language, String level, String json) async {
    try {
      final box = await _box();
      await box.put(_cacheKey(language, level), json);
      await box.put(_timestampKey(language, level),
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ BookService._toCache: $e');
    }
  }

  // Kitobni olish (cache → Storage)
  Future<BookModel> getBook(String language, String level) async {
    final cached = await _fromCache(language, level);
    if (cached != null) {
      debugPrint('📚 BookService: cache — $language/$level');
      return cached;
    }

    debugPrint('📥 BookService: Storage dan yuklanmoqda — $language/$level');
    final ref = FirebaseStorage.instance.ref(_storagePath(language, level));
    final data = await ref.getData(5 * 1024 * 1024);
    if (data == null) throw Exception('Kitob topilmadi');

    final jsonStr = utf8.decode(data);
    await _toCache(language, level, jsonStr);
    return BookModel.fromMap(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  // Yuklab olinganmi?
  Future<bool> isDownloaded(String language, String level) async {
    try {
      final box = await _box();
      final ts = box.get(_timestampKey(language, level)) as int?;
      if (ts == null) return false;
      final age =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
      return age <= _cacheAge;
    } catch (_) {
      return false;
    }
  }
}
