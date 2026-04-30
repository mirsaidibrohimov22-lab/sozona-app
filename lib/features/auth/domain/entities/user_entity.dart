// lib/features/auth/domain/entities/user_entity.dart
// So'zona — Foydalanuvchi domain entity
// Clean Architecture: Domain layer — framework'ga bog'liq emas

import 'package:equatable/equatable.dart';

/// Foydalanuvchi roli
enum UserRole {
  /// O'quvchi — dars o'rganadi
  student,

  /// O'qituvchi — kontent yaratadi, sinflarni boshqaradi
  teacher,
}

/// CEFR darajasi — A1 dan C1 gacha
enum LanguageLevel {
  a1,
  a2,
  b1,
  b2,
  c1,
}

/// O'rganiladigan til
enum LearningLanguage {
  english,
  german,
}

/// Ilova interfeysi tili
enum AppLanguage {
  uzbek,
  english,
}

/// Foydalanuvchi entity — ilovaning asosiy modeli
class UserEntity extends Equatable {
  /// Yagona identifikator (Firebase UID)
  final String id;

  /// Foydalanuvchi ismi
  final String displayName;

  /// Elektron pochta
  final String email;

  /// Telefon raqami (ixtiyoriy)
  final String? phoneNumber;

  /// Profil rasmi URL (ixtiyoriy)
  final String? photoUrl;

  /// Foydalanuvchi roli — student yoki teacher
  final UserRole role;

  /// O'rganiladigan til — ingliz yoki nemis
  final LearningLanguage learningLanguage;

  /// Hozirgi CEFR darajasi
  final LanguageLevel level;

  /// Ilova interfeysi tili
  final AppLanguage appLanguage;

  /// Bildirishnomalar yoqilganmi
  final bool notificationsEnabled;

  /// Kunlik maqsad (daqiqalarda)
  final int dailyGoalMinutes;

  /// Hisob yaratilgan sana
  final DateTime createdAt;

  /// Oxirgi yangilangan sana
  final DateTime updatedAt;

  /// Oxirgi kirish sanasi
  final DateTime? lastLoginAt;

  /// Profil sozlanganmi (onboarding tugaganmi)
  final bool isProfileComplete;

  // ✅ YANGI: Premium va O'zbekiston
  final bool isPremium;
  final bool isUzbekUser;
  final DateTime? premiumExpiresAt;

  const UserEntity({
    required this.id,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
    required this.role,
    this.learningLanguage = LearningLanguage.english,
    this.level = LanguageLevel.a1,
    this.appLanguage = AppLanguage.uzbek,
    this.notificationsEnabled = true,
    this.dailyGoalMinutes = 15,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.isProfileComplete = false,
    this.isPremium = false,
    this.isUzbekUser = false,
    this.premiumExpiresAt,
  });

  /// Foydalanuvchi o'quvchimi?
  bool get isStudent => role == UserRole.student;

  /// Foydalanuvchi o'qituvchimi?
  bool get isTeacher => role == UserRole.teacher;

  /// Nemis tili o'rganayaptimi? (Artikel moduli uchun)
  bool get isLearningGerman => learningLanguage == LearningLanguage.german;

  /// Premium faolmi?
  bool get hasActivePremium {
    if (!isPremium) return false;
    if (premiumExpiresAt == null) return true;
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

  /// Yangi nusxa yaratish (immutability)
  UserEntity copyWith({
    String? id,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    UserRole? role,
    LearningLanguage? learningLanguage,
    LanguageLevel? level,
    AppLanguage? appLanguage,
    bool? notificationsEnabled,
    int? dailyGoalMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isProfileComplete,
    bool? isPremium,
    bool? isUzbekUser,
    DateTime? premiumExpiresAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      learningLanguage: learningLanguage ?? this.learningLanguage,
      level: level ?? this.level,
      appLanguage: appLanguage ?? this.appLanguage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isPremium: isPremium ?? this.isPremium,
      isUzbekUser: isUzbekUser ?? this.isUzbekUser,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        email,
        phoneNumber,
        photoUrl,
        role,
        learningLanguage,
        level,
        appLanguage,
        notificationsEnabled,
        dailyGoalMinutes,
        createdAt,
        updatedAt,
        lastLoginAt,
        isProfileComplete,
        isPremium,
        isUzbekUser,
        premiumExpiresAt,
      ];
}
