// lib/features/auth/data/models/user_model.dart
// So'zona — UserModel: Firestore ↔ UserEntity o'tkazuvchi
// Data layer: tashqi ma'lumot formati bilan ishlaydi

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';

/// Foydalanuvchi modeli — Firestore JSON bilan ishlaydi
/// [UserEntity] ni kengaytiradi
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.displayName,
    required super.email,
    super.phoneNumber,
    super.photoUrl,
    required super.role,
    super.learningLanguage,
    super.level,
    super.appLanguage,
    super.notificationsEnabled,
    super.dailyGoalMinutes,
    required super.createdAt,
    required super.updatedAt,
    super.lastLoginAt,
    super.isProfileComplete,
    super.isPremium,
    super.isUzbekUser,
    super.premiumExpiresAt,
  });

  /// Firestore JSON dan UserModel yaratish
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  /// Map dan UserModel yaratish
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: _parseRole(map['role'] as String?),
      learningLanguage: _parseLearningLanguage(
        map['learningLanguage'] as String?,
      ),
      level: _parseLevel(map['level'] as String?),
      appLanguage: _parseAppLanguage(map['appLanguage'] as String?),
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      dailyGoalMinutes: map['dailyGoalMinutes'] as int? ?? 15,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      lastLoginAt: map['lastLoginAt'] != null
          ? _parseTimestamp(map['lastLoginAt'])
          : null,
      isProfileComplete: map['isProfileComplete'] as bool? ?? false,
      isPremium: map['isPremium'] as bool? ?? false,
      isUzbekUser: map['isUzbekUser'] as bool? ?? false,
      premiumExpiresAt: map['premiumExpiresAt'] != null
          ? _parseTimestamp(map['premiumExpiresAt'])
          : null,
    );
  }

  /// UserEntity dan UserModel yaratish
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      displayName: entity.displayName,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      photoUrl: entity.photoUrl,
      role: entity.role,
      learningLanguage: entity.learningLanguage,
      level: entity.level,
      appLanguage: entity.appLanguage,
      notificationsEnabled: entity.notificationsEnabled,
      dailyGoalMinutes: entity.dailyGoalMinutes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastLoginAt: entity.lastLoginAt,
      isProfileComplete: entity.isProfileComplete,
      isPremium: entity.isPremium,
      isUzbekUser: entity.isUzbekUser,
      premiumExpiresAt: entity.premiumExpiresAt,
    );
  }

  /// Firestore'ga yozish uchun Map'ga o'girish
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role.name,
      'learningLanguage': learningLanguage.name,
      'level': level.name,
      'appLanguage': appLanguage.name,
      'notificationsEnabled': notificationsEnabled,
      'dailyGoalMinutes': dailyGoalMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isProfileComplete': isProfileComplete,
    };
  }

  /// Yangilash uchun faqat o'zgargan maydonlar
  Map<String, dynamic> toUpdateMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'learningLanguage': learningLanguage.name,
      'level': level.name,
      'appLanguage': appLanguage.name,
      'notificationsEnabled': notificationsEnabled,
      'dailyGoalMinutes': dailyGoalMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
      'isProfileComplete': isProfileComplete,
    };
  }

  /// Local cache uchun Map'ga o'girish (Timestamp ishlatmasdan)
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role.name,
      'learningLanguage': learningLanguage.name,
      'level': level.name,
      'appLanguage': appLanguage.name,
      'notificationsEnabled': notificationsEnabled,
      'dailyGoalMinutes': dailyGoalMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isProfileComplete': isProfileComplete,
      'isPremium': isPremium,
      'isUzbekUser': isUzbekUser,
      'premiumExpiresAt': premiumExpiresAt?.toIso8601String(),
    };
  }

  /// Local cache'dan o'qish
  factory UserModel.fromLocalMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: _parseRole(map['role'] as String?),
      learningLanguage: _parseLearningLanguage(
        map['learningLanguage'] as String?,
      ),
      level: _parseLevel(map['level'] as String?),
      appLanguage: _parseAppLanguage(map['appLanguage'] as String?),
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      dailyGoalMinutes: map['dailyGoalMinutes'] as int? ?? 15,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'] as String)
          : null,
      isProfileComplete: map['isProfileComplete'] as bool? ?? false,
      isPremium: map['isPremium'] as bool? ?? false,
      isUzbekUser: map['isUzbekUser'] as bool? ?? false,
      premiumExpiresAt: map['premiumExpiresAt'] != null
          ? _parseTimestamp(map['premiumExpiresAt'])
          : null,
    );
  }

  // ─── Yordamchi parser metodlar ───

  /// Rolni parse qilish
  static UserRole _parseRole(String? value) {
    switch (value) {
      case 'teacher':
        return UserRole.teacher;
      case 'student':
      default:
        return UserRole.student;
    }
  }

  /// O'rganiladigan tilni parse qilish
  static LearningLanguage _parseLearningLanguage(String? value) {
    switch (value) {
      case 'german':
        return LearningLanguage.german;
      case 'english':
      default:
        return LearningLanguage.english;
    }
  }

  /// Darajani parse qilish
  static LanguageLevel _parseLevel(String? value) {
    // ✅ FIX: Katta va kichik harflarni qo'llab-quvvatlash ('B1' va 'b1' ham)
    switch (value?.toLowerCase()) {
      case 'a2':
        return LanguageLevel.a2;
      case 'b1':
        return LanguageLevel.b1;
      case 'b2':
        return LanguageLevel.b2;
      case 'c1':
        return LanguageLevel.c1;
      case 'a1':
      default:
        return LanguageLevel.a1;
    }
  }

  /// Interfeys tilini parse qilish
  static AppLanguage _parseAppLanguage(String? value) {
    switch (value) {
      case 'english':
        return AppLanguage.english;
      case 'uzbek':
      default:
        return AppLanguage.uzbek;
    }
  }

  /// Timestamp yoki null ni DateTime'ga o'girish
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }
}
