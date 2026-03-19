// lib/features/flashcard/domain/entities/folder_entity.dart
// So'zona — Flashcard papka (to'plam) entity
// Kartochkalar guruhlash uchun papka modeli

import 'package:equatable/equatable.dart';

/// Papka rangi (UI uchun)
enum FolderColor {
  blue,
  green,
  orange,
  purple,
  red,
  teal,
  pink,
  indigo,
}

/// Flashcard papka entity
class FolderEntity extends Equatable {
  /// Yagona identifikator
  final String id;

  /// Foydalanuvchi identifikatori
  final String userId;

  /// Papka nomi (masalan: "A1 so'zlar", "Familie", "Business English")
  final String name;

  /// Tavsif (ixtiyoriy)
  final String? description;

  /// Papka rangi
  final FolderColor color;

  /// Ikonka emoji (ixtiyoriy)
  final String? emoji;

  /// Til (english / german)
  final String language;

  /// CEFR darajasi (ixtiyoriy)
  final String? cefrLevel;

  /// Kartochkalar soni
  final int cardCount;

  /// O'zlashtirilgan kartochkalar soni
  final int masteredCount;

  /// Takrorlashga tayyor kartochkalar soni
  final int dueCount;

  /// AI tomonidan yaratilganmi
  final bool isAiGenerated;

  /// O'qituvchi tomonidan tayinlanganmi
  final bool isAssigned;

  /// O'qituvchi ID (agar tayinlangan bo'lsa)
  final String? assignedByTeacherId;

  /// Tartib raqami (foydalanuvchi o'zgartirishi mumkin)
  final int sortOrder;

  /// Yaratilgan sana
  final DateTime createdAt;

  /// Yangilangan sana
  final DateTime updatedAt;

  /// O'chirilganmi (soft delete)
  final bool isDeleted;

  const FolderEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color = FolderColor.blue,
    this.emoji,
    this.language = 'english',
    this.cefrLevel,
    this.cardCount = 0,
    this.masteredCount = 0,
    this.dueCount = 0,
    this.isAiGenerated = false,
    this.isAssigned = false,
    this.assignedByTeacherId,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  /// O'zlashtirish foizi (0 dan 100 gacha)
  double get masteryPercent {
    if (cardCount == 0) return 0;
    return (masteredCount / cardCount * 100).clamp(0, 100);
  }

  /// Bo'sh papkami?
  bool get isEmpty => cardCount == 0;

  /// To'liq o'zlashtirilganmi?
  bool get isFullyMastered => cardCount > 0 && masteredCount >= cardCount;

  /// Takrorlash kerakmi?
  bool get hasDueCards => dueCount > 0;

  /// Nusxa yaratish
  FolderEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    FolderColor? color,
    String? emoji,
    String? language,
    String? cefrLevel,
    int? cardCount,
    int? masteredCount,
    int? dueCount,
    bool? isAiGenerated,
    bool? isAssigned,
    String? assignedByTeacherId,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return FolderEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      emoji: emoji ?? this.emoji,
      language: language ?? this.language,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      cardCount: cardCount ?? this.cardCount,
      masteredCount: masteredCount ?? this.masteredCount,
      dueCount: dueCount ?? this.dueCount,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      isAssigned: isAssigned ?? this.isAssigned,
      assignedByTeacherId: assignedByTeacherId ?? this.assignedByTeacherId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        color,
        emoji,
        language,
        cefrLevel,
        cardCount,
        masteredCount,
        dueCount,
        isAiGenerated,
        isAssigned,
        assignedByTeacherId,
        sortOrder,
        createdAt,
        updatedAt,
        isDeleted,
      ];
}
