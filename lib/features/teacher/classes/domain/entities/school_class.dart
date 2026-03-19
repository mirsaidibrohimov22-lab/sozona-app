// QO'YISH: lib/features/teacher/classes/domain/entities/school_class.dart
// So'zona — Sinf entity (Domain Layer)
// O'qituvchi tomonidan yaratilgan sinf (class) modeli

import 'package:equatable/equatable.dart';

/// O'qituvchi sinfi — o'quvchilar guruhi
///
/// Bolaga tushuntirish:
/// Maktabda 5A, 5B sinflar bo'ladi. O'qituvchi o'z sinfini
/// yaratadi, o'quvchilarga join code beradi, ular qo'shiladi.
class SchoolClass extends Equatable {
  /// Yagona identifikator (Firestore document ID)
  final String id;

  /// Sinf nomi — masalan "English A2 Group"
  final String name;

  /// Sinf tavsifi (ixtiyoriy)
  final String? description;

  /// O'qituvchi identifikatori
  final String teacherId;

  /// O'qituvchi ismi (denormalized — tez o'qish uchun)
  final String teacherName;

  /// O'rganish tili: "en" | "de"
  final String language;

  /// CEFR darajasi: "A1" | "A2" | "B1" | "B2" | "C1"
  final String level;

  /// Qo'shilish kodi — 6 belgili (masalan: "ABC123")
  /// Student shu kodni kiritib sinfga qo'shiladi
  final String joinCode;

  /// A'zolar soni
  final int memberCount;

  /// Maksimal a'zolar soni (default: 50)
  final int maxMembers;

  /// Sinf faolmi yoki arxivlangan
  final bool isActive;

  /// Sinf yaratilgan sana
  final DateTime createdAt;

  /// Oxirgi yangilangan sana
  final DateTime updatedAt;

  const SchoolClass({
    required this.id,
    required this.name,
    this.description,
    required this.teacherId,
    required this.teacherName,
    required this.language,
    required this.level,
    required this.joinCode,
    required this.memberCount,
    this.maxMembers = 50,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Sinf to'liqmi? (Yangi o'quvchi qo'shish mumkinmi)
  bool get isFull => memberCount >= maxMembers;

  /// Nemis tilimi?
  bool get isGerman => language == 'de';

  /// Ingliz tilimi?
  bool get isEnglish => language == 'en';

  /// Til belgisi (emoji)
  String get languageFlag => language == 'de' ? '🇩🇪' : '🇬🇧';

  /// Til nomi (o'zbekcha)
  String get languageName => language == 'de' ? 'Nemischa' : 'Inglizcha';

  /// Yangi qiymatlar bilan nusxa olish
  SchoolClass copyWith({
    String? id,
    String? name,
    String? description,
    String? teacherId,
    String? teacherName,
    String? language,
    String? level,
    String? joinCode,
    int? memberCount,
    int? maxMembers,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolClass(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      language: language ?? this.language,
      level: level ?? this.level,
      joinCode: joinCode ?? this.joinCode,
      memberCount: memberCount ?? this.memberCount,
      maxMembers: maxMembers ?? this.maxMembers,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        teacherId,
        language,
        level,
        joinCode,
        memberCount,
        isActive,
        updatedAt,
      ];

  @override
  String toString() =>
      'SchoolClass(id: $id, name: $name, level: $level, members: $memberCount)';
}
