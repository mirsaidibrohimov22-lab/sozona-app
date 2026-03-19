// lib/features/flashcards/data/datasources/flashcard_local_datasource.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/student/flashcards/data/models/flashcard_model.dart';
import 'package:my_first_app/features/student/flashcards/data/models/folder_model.dart';

abstract class FlashcardLocalDataSource {
  Future<void> init();
  Future<List<FolderModel>> getFolders(String userId);
  Future<void> saveFolder(FolderModel folder);
  Future<void> saveFolders(List<FolderModel> folders);
  Future<FolderModel?> getFolderById(String folderId);
  Future<void> deleteFolder(String folderId);
  Future<List<FlashcardModel>> getCards(String folderId);
  Future<List<FlashcardModel>> getDueCards(String userId, {int limit = 20});
  Future<List<FlashcardModel>> getWeakCards(String userId, {int limit = 20});
  Future<FlashcardModel?> getCardById(String cardId);
  Future<List<FlashcardModel>> searchCards(String userId, String query);
  Future<void> saveCard(FlashcardModel card);
  Future<void> saveCards(List<FlashcardModel> cards);
  Future<void> deleteCard(String cardId);
  Future<void> clearAll();
}

class FlashcardLocalDataSourceImpl implements FlashcardLocalDataSource {
  Database? _db;
  Future<Database> get _database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  @override
  Future<void> init() async {
    try {
      final p = await getDatabasesPath();
      _db = await openDatabase(
        path.join(p, 'sozona_flashcards.db'),
        version: 1,
        onCreate: (db, v) async {
          await db.execute('''CREATE TABLE IF NOT EXISTS folders (
            id TEXT PRIMARY KEY, userId TEXT NOT NULL, name TEXT NOT NULL,
            description TEXT, color TEXT DEFAULT 'blue', emoji TEXT,
            language TEXT DEFAULT 'english', cefrLevel TEXT,
            cardCount INTEGER DEFAULT 0, masteredCount INTEGER DEFAULT 0,
            dueCount INTEGER DEFAULT 0, isAiGenerated INTEGER DEFAULT 0,
            isAssigned INTEGER DEFAULT 0, assignedByTeacherId TEXT,
            sortOrder INTEGER DEFAULT 0, createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL, isDeleted INTEGER DEFAULT 0)''');
          await db.execute('''CREATE TABLE IF NOT EXISTS flashcards (
            id TEXT PRIMARY KEY, folderId TEXT NOT NULL, userId TEXT NOT NULL,
            front TEXT NOT NULL, back TEXT NOT NULL, example TEXT,
            pronunciation TEXT, imageUrl TEXT, audioUrl TEXT,
            difficulty TEXT DEFAULT 'medium', intervalHours INTEGER DEFAULT 0,
            nextReviewAt TEXT NOT NULL, reviewCount INTEGER DEFAULT 0,
            correctCount INTEGER DEFAULT 0, incorrectCount INTEGER DEFAULT 0,
            easeFactor REAL DEFAULT 2.5, createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL, lastReviewedAt TEXT,
            isDeleted INTEGER DEFAULT 0, cefrLevel TEXT,
            wordType TEXT, artikel TEXT)''');
        },
      );
    } catch (e) {
      throw CacheException(message: 'SQLite init xatosi: $e');
    }
  }

  @override
  Future<List<FolderModel>> getFolders(String userId) async {
    final db = await _database;
    final rows = await db.query('folders',
        where: 'userId=? AND isDeleted=0',
        whereArgs: [userId],
        orderBy: 'sortOrder ASC');
    return rows.map(FolderModel.fromSqlite).toList();
  }

  @override
  Future<void> saveFolder(FolderModel f) async {
    final db = await _database;
    await db.insert('folders', f.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveFolders(List<FolderModel> folders) async {
    final db = await _database;
    final b = db.batch();
    for (final f in folders)
      b.insert('folders', f.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    await b.commit(noResult: true);
  }

  @override
  Future<FolderModel?> getFolderById(String folderId) async {
    final db = await _database;
    final rows = await db.query('folders',
        where: 'id=? AND isDeleted=0', whereArgs: [folderId], limit: 1);
    return rows.isEmpty ? null : FolderModel.fromSqlite(rows.first);
  }

  @override
  Future<void> deleteFolder(String id) async {
    final db = await _database;
    final now = DateTime.now().toIso8601String();
    await db.update('folders', {'isDeleted': 1, 'updatedAt': now},
        where: 'id=?', whereArgs: [id]);
    await db.update('flashcards', {'isDeleted': 1, 'updatedAt': now},
        where: 'folderId=?', whereArgs: [id]);
  }

  @override
  Future<List<FlashcardModel>> getCards(String folderId) async {
    final db = await _database;
    final rows = await db.query('flashcards',
        where: 'folderId=? AND isDeleted=0', whereArgs: [folderId]);
    return rows.map(FlashcardModel.fromSqlite).toList();
  }

  @override
  Future<List<FlashcardModel>> getDueCards(String userId,
      {int limit = 20}) async {
    final db = await _database;
    final now = DateTime.now().toIso8601String();
    final rows = await db.query('flashcards',
        where: 'userId=? AND isDeleted=0 AND nextReviewAt<=?',
        whereArgs: [userId, now],
        orderBy: 'nextReviewAt ASC',
        limit: limit);
    return rows.map(FlashcardModel.fromSqlite).toList();
  }

  @override
  Future<List<FlashcardModel>> getWeakCards(String userId,
      {int limit = 20}) async {
    final db = await _database;
    final rows = await db.rawQuery(
        'SELECT * FROM flashcards WHERE userId=? AND isDeleted=0 AND reviewCount>0 AND CAST(correctCount AS REAL)/CAST(reviewCount AS REAL)<0.5 ORDER BY incorrectCount DESC LIMIT ?',
        [userId, limit]);
    return rows.map(FlashcardModel.fromSqlite).toList();
  }

  @override
  Future<FlashcardModel?> getCardById(String cardId) async {
    final db = await _database;
    final rows = await db.query('flashcards',
        where: 'id=? AND isDeleted=0', whereArgs: [cardId], limit: 1);
    return rows.isEmpty ? null : FlashcardModel.fromSqlite(rows.first);
  }

  @override
  Future<List<FlashcardModel>> searchCards(String userId, String query) async {
    final db = await _database;
    final q = '%${query.toLowerCase()}%';
    final rows = await db.rawQuery(
        'SELECT * FROM flashcards WHERE userId=? AND isDeleted=0 AND (LOWER(front) LIKE ? OR LOWER(back) LIKE ?) ORDER BY front ASC LIMIT 50',
        [userId, q, q]);
    return rows.map(FlashcardModel.fromSqlite).toList();
  }

  @override
  Future<void> saveCard(FlashcardModel c) async {
    final db = await _database;
    await db.insert('flashcards', c.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveCards(List<FlashcardModel> cards) async {
    final db = await _database;
    final b = db.batch();
    for (final c in cards)
      b.insert('flashcards', c.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    await b.commit(noResult: true);
  }

  @override
  Future<void> deleteCard(String id) async {
    final db = await _database;
    await db.update('flashcards',
        {'isDeleted': 1, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id=?', whereArgs: [id]);
  }

  @override
  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('flashcards');
    await db.delete('folders');
  }
}
