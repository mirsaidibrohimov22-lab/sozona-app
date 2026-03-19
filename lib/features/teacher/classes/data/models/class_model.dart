// QO'YISH: lib/features/teacher/classes/data/models/class_model.dart
// So'zona — Sinf Firestore modeli (Data Layer)
// Firestore JSON ↔ SchoolClass entity o'girish

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_first_app/features/teacher/classes/domain/entities/school_class.dart';

/// SchoolClass ning Firestore versiyasi
///
/// Bolaga tushuntirish:
/// Entity — ilovaning "tili". Model — Firestore ning "tili".
/// Model ikki tilni tarjima qiladi.
class ClassModel extends SchoolClass {
  const ClassModel({
    required super.id,
    required super.name,
    super.description,
    required super.teacherId,
    required super.teacherName,
    required super.language,
    required super.level,
    required super.joinCode,
    required super.memberCount,
    super.maxMembers,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Firestore document'dan ClassModel yaratish
  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel.fromMap(data, doc.id);
  }

  /// Map'dan ClassModel yaratish
  factory ClassModel.fromMap(Map<String, dynamic> map, String docId) {
    return ClassModel(
      id: docId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      teacherId: map['teacherId'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      language: map['language'] as String? ?? 'en',
      level: map['level'] as String? ?? 'A1',
      joinCode: map['joinCode'] as String? ?? '',
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
      maxMembers: (map['maxMembers'] as num?)?.toInt() ?? 50,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  /// SchoolClass entity'dan ClassModel yaratish
  factory ClassModel.fromEntity(SchoolClass entity) {
    return ClassModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      teacherId: entity.teacherId,
      teacherName: entity.teacherName,
      language: entity.language,
      level: entity.level,
      joinCode: entity.joinCode,
      memberCount: entity.memberCount,
      maxMembers: entity.maxMembers,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Firestore'ga saqlash uchun Map'ga aylantirish
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'language': language,
      'level': level,
      'joinCode': joinCode,
      'memberCount': memberCount,
      'maxMembers': maxMembers,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Yangilash uchun Map (faqat o'zgartiriladigan maydonlar)
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Timestamp'ni DateTime ga aylantirish
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
