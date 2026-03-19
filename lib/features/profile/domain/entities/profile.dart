// QO'YISH: lib/features/profile/domain/entities/profile.dart
// So'zona — Foydalanuvchi profil entity

import 'package:equatable/equatable.dart';

class UserNotificationSettings extends Equatable {
  final bool microSession;
  final bool streak;
  final bool teacherContent;

  const UserNotificationSettings({
    this.microSession = true,
    this.streak = true,
    this.teacherContent = true,
  });

  UserNotificationSettings copyWith({
    bool? microSession,
    bool? streak,
    bool? teacherContent,
  }) =>
      UserNotificationSettings(
        microSession: microSession ?? this.microSession,
        streak: streak ?? this.streak,
        teacherContent: teacherContent ?? this.teacherContent,
      );

  @override
  List<Object?> get props => [microSession, streak, teacherContent];
}

class UserPreferences extends Equatable {
  final bool microSessionEnabled;
  final int microSessionIntervalMin;
  final int microSessionDurationMin;
  final bool premiumTtsEnabled;
  final bool studentQuizAddEnabled;

  const UserPreferences({
    this.microSessionEnabled = true,
    this.microSessionIntervalMin = 60,
    this.microSessionDurationMin = 10,
    this.premiumTtsEnabled = false,
    this.studentQuizAddEnabled = true,
  });

  UserPreferences copyWith({
    bool? microSessionEnabled,
    int? microSessionIntervalMin,
    int? microSessionDurationMin,
    bool? premiumTtsEnabled,
    bool? studentQuizAddEnabled,
  }) =>
      UserPreferences(
        microSessionEnabled: microSessionEnabled ?? this.microSessionEnabled,
        microSessionIntervalMin:
            microSessionIntervalMin ?? this.microSessionIntervalMin,
        microSessionDurationMin:
            microSessionDurationMin ?? this.microSessionDurationMin,
        premiumTtsEnabled: premiumTtsEnabled ?? this.premiumTtsEnabled,
        studentQuizAddEnabled:
            studentQuizAddEnabled ?? this.studentQuizAddEnabled,
      );

  @override
  List<Object?> get props =>
      [microSessionEnabled, microSessionIntervalMin, premiumTtsEnabled];
}

class UserProfile extends Equatable {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final String? preferredLanguage;
  final String? uiLanguage;
  final String? level;
  final String? avatarUrl;
  final int dailyGoalMinutes;
  final int currentStreak;
  final int longestStreak;
  final int totalXp;
  final UserNotificationSettings notifications;
  final UserPreferences preferences;
  final DateTime? lastActiveDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.preferredLanguage = 'en',
    this.uiLanguage = 'uz',
    this.level = 'A1',
    this.avatarUrl,
    this.dailyGoalMinutes = 20,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalXp = 0,
    this.notifications = const UserNotificationSettings(),
    this.preferences = const UserPreferences(),
    this.lastActiveDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  String get initials => fullName
      .trim()
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
      .take(2)
      .join();

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? preferredLanguage,
    String? uiLanguage,
    String? level,
    String? avatarUrl,
    int? dailyGoalMinutes,
    int? currentStreak,
    int? longestStreak,
    int? totalXp,
    UserNotificationSettings? notifications,
    UserPreferences? preferences,
    DateTime? lastActiveDate,
    DateTime? updatedAt,
  }) =>
      UserProfile(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        uiLanguage: uiLanguage ?? this.uiLanguage,
        level: level ?? this.level,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        totalXp: totalXp ?? this.totalXp,
        notifications: notifications ?? this.notifications,
        preferences: preferences ?? this.preferences,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id, fullName, role, level, totalXp];
}
