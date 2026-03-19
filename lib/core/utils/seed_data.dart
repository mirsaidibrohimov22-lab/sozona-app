// lib/core/utils/seed_data.dart
// So'zona — Test ma'lumotlarni Firestore ga yozish
// FAQAT bir marta ishga tushiring, keyin o'chiring!
//
// Ishlatish:
//   SeedData.run(context);  ← istalgan joydan chaqiring

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class SeedData {
  static final _db = FirebaseFirestore.instance;
  static final _uuid = const Uuid();

  // ─── Bir marta ishga tushirish ───
  static Future<void> run(BuildContext context) async {
    try {
      _show(context, '⏳ Seed boshlanmoqda...');

      // Avval teacher va student yaratamiz
      final teacherId = await _createTeacher();
      final studentId = await _createStudent();

      // Class yaratamiz
      final classId = await _createClass(teacherId);

      // Student ni classga qo'shamiz
      await _addStudentToClass(classId, studentId);

      // Flashcard folder va cardlar
      await _createFlashcards(studentId);

      // Quiz (content)
      await _createQuiz(teacherId, classId);

      // Artikel so'zlari
      await _createArtikelWords();

      // Progress yaratamiz
      await _createProgress(studentId);

      if (context.mounted) _show(context, '✅ Seed muvaffaqiyatli tugadi!');
    } catch (e) {
      if (context.mounted) _show(context, '❌ Xatolik: $e');
      debugPrint('SeedData xatolik: $e');
    }
  }

  // ══════════════════════════════════════
  // TEACHER
  // ══════════════════════════════════════
  static Future<String> _createTeacher() async {
    // Firebase Auth da teacher yaratish
    final cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: 'teacher@sozona.uz',
      password: 'Teacher123!',
    )
        .catchError((_) async {
      // Allaqachon mavjud bo'lsa login qilamiz
      return FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'teacher@sozona.uz',
        password: 'Teacher123!',
      );
    });

    final uid = cred.user!.uid;
    final now = DateTime.now();

    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': 'teacher@sozona.uz',
      'displayName': 'Test Teacher',
      'photoUrl': null,
      'role': 'teacher',
      'learningLanguage': 'german',
      'level': 'b1',
      'appLanguage': 'uzbek',
      'notificationsEnabled': true,
      'dailyGoalMinutes': 30,
      'isProfileComplete': true,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'lastLoginAt': Timestamp.fromDate(now),
    });

    debugPrint('✅ Teacher yaratildi: $uid');
    return uid;
  }

  // ══════════════════════════════════════
  // STUDENT
  // ══════════════════════════════════════
  static Future<String> _createStudent() async {
    final cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: 'student@sozona.uz',
      password: 'Student123!',
    )
        .catchError((_) async {
      return FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'student@sozona.uz',
        password: 'Student123!',
      );
    });

    final uid = cred.user!.uid;
    final now = DateTime.now();

    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': 'student@sozona.uz',
      'displayName': 'Test Student',
      'photoUrl': null,
      'role': 'student',
      'learningLanguage': 'german',
      'level': 'a1',
      'appLanguage': 'uzbek',
      'notificationsEnabled': true,
      'dailyGoalMinutes': 15,
      'isProfileComplete': true,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'lastLoginAt': Timestamp.fromDate(now),
    });

    debugPrint('✅ Student yaratildi: $uid');
    return uid;
  }

  // ══════════════════════════════════════
  // CLASS
  // ══════════════════════════════════════
  static Future<String> _createClass(String teacherId) async {
    final classId = _uuid.v4();
    final now = DateTime.now();

    await _db.collection('classes').doc(classId).set({
      'name': 'Nemis tili A1',
      'description': 'Boshlang\'ich daraja — A1',
      'teacherId': teacherId,
      'teacherName': 'Test Teacher',
      'language': 'german',
      'level': 'A1',
      'joinCode': 'SOZONA01',
      'memberCount': 1,
      'maxMembers': 30,
      'isActive': true,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    debugPrint('✅ Class yaratildi: $classId');
    return classId;
  }

  // Student ni classga qo'shish
  static Future<void> _addStudentToClass(
      String classId, String studentId) async {
    await _db
        .collection('classes')
        .doc(classId)
        .collection('members')
        .doc(studentId)
        .set({
      'userId': studentId,
      'displayName': 'Test Student',
      'joinedAt': Timestamp.fromDate(DateTime.now()),
      'role': 'student',
    });
    debugPrint('✅ Student classga qo\'shildi');
  }

  // ══════════════════════════════════════
  // FLASHCARDS
  // ══════════════════════════════════════
  static Future<void> _createFlashcards(String userId) async {
    final folderId = _uuid.v4();
    final now = DateTime.now();

    // Folder
    await _db.collection('folders').doc(folderId).set({
      'userId': userId,
      'name': 'Kundalik so\'zlar',
      'description': 'Har kuni ishlatiladigan nemis so\'zlari',
      'color': 'blue',
      'emoji': '📚',
      'language': 'german',
      'cefrLevel': 'A1',
      'cardCount': 5,
      'masteredCount': 0,
      'dueCount': 5,
      'isAiGenerated': false,
      'isAssigned': false,
      'assignedByTeacherId': null,
      'sortOrder': 0,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'isDeleted': false,
    });

    // 5 ta flashcard
    final cards = [
      {'front': 'Hallo', 'back': 'Salom', 'artikel': null},
      {'front': 'Danke', 'back': 'Rahmat', 'artikel': null},
      {'front': 'Wasser', 'back': 'Suv', 'artikel': 'das'},
      {'front': 'Buch', 'back': 'Kitob', 'artikel': 'das'},
      {'front': 'Haus', 'back': 'Uy', 'artikel': 'das'},
    ];

    final batch = _db.batch();
    for (final card in cards) {
      final cardId = _uuid.v4();
      batch.set(_db.collection('flashcards').doc(cardId), {
        'folderId': folderId,
        'userId': userId,
        'front': card['front'],
        'back': card['back'],
        'example': null,
        'pronunciation': null,
        'imageUrl': null,
        'audioUrl': null,
        'artikel': card['artikel'],
        'wordType': 'noun',
        'cefrLevel': 'A1',
        'difficulty': 'newCard',
        'intervalHours': 0,
        'nextReviewAt': now.toIso8601String(),
        'reviewCount': 0,
        'correctCount': 0,
        'incorrectCount': 0,
        'easeFactor': 2.5,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDeleted': false,
      });
    }
    await batch.commit();
    debugPrint('✅ Flashcards yaratildi (folder + 5 card)');
  }

  // ══════════════════════════════════════
  // QUIZ
  // ══════════════════════════════════════
  static Future<void> _createQuiz(String teacherId, String classId) async {
    final quizId = _uuid.v4();
    final now = DateTime.now();

    final questions = [
      {
        'id': _uuid.v4(),
        'type': 'mcq',
        'question': '"Hallo" so\'zining tarjimasi nima?',
        'options': ['Xayr', 'Salom', 'Rahmat', 'Iltimos'],
        'correctAnswer': 'Salom',
        'explanation': 'Hallo — nemischa salomlashish so\'zi',
        'points': 10,
        'timeLimit': 30,
      },
      {
        'id': _uuid.v4(),
        'type': 'mcq',
        'question': '"Danke" so\'zining tarjimasi nima?',
        'options': ['Kechirasiz', 'Iltimos', 'Rahmat', 'Salom'],
        'correctAnswer': 'Rahmat',
        'explanation': 'Danke — nemischa minnatdorchilik so\'zi',
        'points': 10,
        'timeLimit': 30,
      },
      {
        'id': _uuid.v4(),
        'type': 'true_false',
        'question': '"Wasser" so\'zi "Suv" degan ma\'noni anglatadi',
        'options': ['Ha', 'Yo\'q'],
        'correctAnswer': 'Ha',
        'explanation': 'Wasser — nemischa suv',
        'points': 10,
        'timeLimit': 20,
      },
      {
        'id': _uuid.v4(),
        'type': 'fill_blank',
        'question': '"Uy" so\'zi nemischada ___ deyiladi',
        'options': [],
        'correctAnswer': 'Haus',
        'explanation': 'Haus — nemischa uy',
        'points': 15,
        'timeLimit': 40,
      },
      {
        'id': _uuid.v4(),
        'type': 'mcq',
        'question': '"Buch" so\'zi qaysi artikelga ega?',
        'options': ['der', 'die', 'das', 'Artikeli yo\'q'],
        'correctAnswer': 'das',
        'explanation': 'das Buch — kitob (neytral rod)',
        'points': 15,
        'timeLimit': 30,
      },
    ];

    await _db.collection('content').doc(quizId).set({
      'type': 'quiz',
      'title': 'A1 — Birinchi dars quiz',
      'description': 'Asosiy nemis so\'zlari bo\'yicha test',
      'language': 'german',
      'level': 'A1',
      'topic': 'Asosiy so\'zlar',
      'creatorId': teacherId, // ✅ yagona standart field
      'creatorType': 'teacher',
      'classId': classId,
      'isPublished': true,
      'generatedByAi': false,
      'attemptCount': 0,
      'averageScore': 0.0,
      'tags': ['a1', 'vocabulary', 'german'],
      'publishedAt': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
      'data': {
        'questions': questions,
        'totalPoints': 60,
        'passingScore': 36,
        'timeLimit': 300,
      },
    });

    debugPrint('✅ Quiz yaratildi: $quizId');
  }

  // ══════════════════════════════════════
  // ARTIKEL WORDS
  // ══════════════════════════════════════
  static Future<void> _createArtikelWords() async {
    final words = [
      {
        'word': 'Hund',
        'artikel': 'der',
        'plural': 'Hunde',
        'translation': 'It',
        'example': 'Der Hund ist klein.',
        'difficulty': 1.0,
        'cefrLevel': 'A1',
        'topic': 'animals',
      },
      {
        'word': 'Katze',
        'artikel': 'die',
        'plural': 'Katzen',
        'translation': 'Mushuk',
        'example': 'Die Katze schläft.',
        'difficulty': 1.0,
        'cefrLevel': 'A1',
        'topic': 'animals',
      },
      {
        'word': 'Kind',
        'artikel': 'das',
        'plural': 'Kinder',
        'translation': 'Bola',
        'example': 'Das Kind spielt.',
        'difficulty': 1.0,
        'cefrLevel': 'A1',
        'topic': 'family',
      },
      {
        'word': 'Mann',
        'artikel': 'der',
        'plural': 'Männer',
        'translation': 'Erkak',
        'example': 'Der Mann arbeitet.',
        'difficulty': 1.0,
        'cefrLevel': 'A1',
        'topic': 'family',
      },
      {
        'word': 'Frau',
        'artikel': 'die',
        'plural': 'Frauen',
        'translation': 'Ayol',
        'example': 'Die Frau liest.',
        'difficulty': 1.0,
        'cefrLevel': 'A1',
        'topic': 'family',
      },
      {
        'word': 'Auto',
        'artikel': 'das',
        'plural': 'Autos',
        'translation': 'Mashina',
        'example': 'Das Auto ist rot.',
        'difficulty': 1.0,
        'cefrLevel': 'A1',
        'topic': 'transport',
      },
      {
        'word': 'Tisch',
        'artikel': 'der',
        'plural': 'Tische',
        'translation': 'Stol',
        'example': 'Der Tisch ist groß.',
        'difficulty': 1.5,
        'cefrLevel': 'A1',
        'topic': 'furniture',
      },
      {
        'word': 'Schule',
        'artikel': 'die',
        'plural': 'Schulen',
        'translation': 'Maktab',
        'example': 'Die Schule beginnt um 8 Uhr.',
        'difficulty': 1.5,
        'cefrLevel': 'A1',
        'topic': 'education',
      },
      {
        'word': 'Brot',
        'artikel': 'das',
        'plural': 'Brote',
        'translation': 'Non',
        'example': 'Das Brot ist frisch.',
        'difficulty': 1.0,
        'cefrLevel': 'A1',
        'topic': 'food',
      },
      {
        'word': 'Baum',
        'artikel': 'der',
        'plural': 'Bäume',
        'translation': 'Daraxt',
        'example': 'Der Baum ist hoch.',
        'difficulty': 1.5,
        'cefrLevel': 'A1',
        'topic': 'nature',
      },
    ];

    final batch = _db.batch();
    for (final word in words) {
      final wordId = _uuid.v4();
      batch.set(_db.collection('artikel_words').doc(wordId), {
        ...word,
        'mastery': 0.0,
        'imageUrl': null,
      });
    }
    await batch.commit();
    debugPrint('✅ Artikel words yaratildi (10 ta)');
  }

  // ══════════════════════════════════════
  // PROGRESS
  // ══════════════════════════════════════
  static Future<void> _createProgress(String userId) async {
    final now = DateTime.now();

    await _db.collection('progress').doc(userId).set({
      'userId': userId,
      'totalXp': 0,
      'currentStreak': 0,
      'longestStreak': 0,
      'lastActiveDate': Timestamp.fromDate(now),
      'last7Days': List.filled(7, false),
      'totalQuizzes': 0,
      'averageQuizScore': 0.0,
      'skillScores': {
        'quiz': 0.0,
        'flashcard': 0.0,
        'listening': 0.0,
        'speaking': 0.0,
        'artikel': 0.0,
      },
      'weakAreas': [],
      'updatedAt': Timestamp.fromDate(now),
    });

    debugPrint('✅ Progress yaratildi');
  }

  // ══════════════════════════════════════
  // HELPER
  // ══════════════════════════════════════
  static void _show(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
    debugPrint(msg);
  }
}
