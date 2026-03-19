// lib/features/flashcard/data/models/folder_model.dart
// So'zona — Folder data modeli
// Firestore va SQLite bilan ishlash uchun serializatsiya

import 'package:my_first_app/features/student/flashcards/domain/entities/folder_entity.dart';

/// Folder data modeli — Entity'dan meros oladi
class FolderModel extends FolderEntity {
  const FolderModel({
    required super.id,
    required super.userId,
    required super.name,
    super.description,
    super.color,
    super.emoji,
    super.language,
    super.cefrLevel,
    super.cardCount,
    super.masteredCount,
    super.dueCount,
    super.isAiGenerated,
    super.isAssigned,
    super.assignedByTeacherId,
    super.sortOrder,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
  });

  /// Firestore hujjatidan yaratish
  factory FolderModel.fromFirestore(
    Map<String, dynamic> map,
    String docId,
  ) {
    return FolderModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      color: _parseColor(map['color'] as String?),
      emoji: map['emoji'] as String?,
      language: map['language'] as String? ?? 'english',
      cefrLevel: map['cefrLevel'] as String?,
      cardCount: map['cardCount'] as int? ?? 0,
      masteredCount: map['masteredCount'] as int? ?? 0,
      dueCount: map['dueCount'] as int? ?? 0,
      isAiGenerated: map['isAiGenerated'] as bool? ?? false,
      isAssigned: map['isAssigned'] as bool? ?? false,
      assignedByTeacherId: map['assignedByTeacherId'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  /// Firestore'ga yozish uchun Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'color': color.name,
      'emoji': emoji,
      'language': language,
      'cefrLevel': cefrLevel,
      'cardCount': cardCount,
      'masteredCount': masteredCount,
      'dueCount': dueCount,
      'isAiGenerated': isAiGenerated,
      'isAssigned': isAssigned,
      'assignedByTeacherId': assignedByTeacherId,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  /// SQLite'dan o'qish
  factory FolderModel.fromSqlite(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      color: _parseColor(map['color'] as String?),
      emoji: map['emoji'] as String?,
      language: map['language'] as String? ?? 'english',
      cefrLevel: map['cefrLevel'] as String?,
      cardCount: map['cardCount'] as int? ?? 0,
      masteredCount: map['masteredCount'] as int? ?? 0,
      dueCount: map['dueCount'] as int? ?? 0,
      isAiGenerated: (map['isAiGenerated'] as int?) == 1,
      isAssigned: (map['isAssigned'] as int?) == 1,
      assignedByTeacherId: map['assignedByTeacherId'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isDeleted: (map['isDeleted'] as int?) == 1,
    );
  }

  /// SQLite'ga yozish uchun Map
  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'color': color.name,
      'emoji': emoji,
      'language': language,
      'cefrLevel': cefrLevel,
      'cardCount': cardCount,
      'masteredCount': masteredCount,
      'dueCount': dueCount,
      'isAiGenerated': isAiGenerated ? 1 : 0,
      'isAssigned': isAssigned ? 1 : 0,
      'assignedByTeacherId': assignedByTeacherId,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  /// Entity'dan model yaratish
  factory FolderModel.fromEntity(FolderEntity entity) {
    return FolderModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      description: entity.description,
      color: entity.color,
      emoji: entity.emoji,
      language: entity.language,
      cefrLevel: entity.cefrLevel,
      cardCount: entity.cardCount,
      masteredCount: entity.masteredCount,
      dueCount: entity.dueCount,
      isAiGenerated: entity.isAiGenerated,
      isAssigned: entity.isAssigned,
      assignedByTeacherId: entity.assignedByTeacherId,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isDeleted: entity.isDeleted,
    );
  }

  /// Rang parse qilish
  static FolderColor _parseColor(String? value) {
    switch (value) {
      case 'green':
        return FolderColor.green;
      case 'orange':
        return FolderColor.orange;
      case 'purple':
        return FolderColor.purple;
      case 'red':
        return FolderColor.red;
      case 'teal':
        return FolderColor.teal;
      case 'pink':
        return FolderColor.pink;
      case 'indigo':
        return FolderColor.indigo;
      default:
        return FolderColor.blue;
    }
  }

  /// DateTime parse qilish
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }
}
