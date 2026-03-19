// QO'YISH: lib/features/profile/data/models/profile_model.dart
// So'zona — UserProfile Firestore modeli

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/profile/domain/entities/profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.fullName,
    super.email,
    super.phone,
    required super.role,
    super.preferredLanguage,
    super.uiLanguage,
    super.level,
    super.avatarUrl,
    super.dailyGoalMinutes,
    super.currentStreak,
    super.longestStreak,
    super.totalXp,
    super.notifications,
    super.preferences,
    super.lastActiveDate,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserProfileModel.fromMap(d, doc.id);
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> d, String id) {
    final notif = d['notifications'] as Map<String, dynamic>? ?? {};
    final prefs = d['preferences'] as Map<String, dynamic>? ?? {};

    return UserProfileModel(
      id: id,
      fullName: d['fullName'] as String? ?? '',
      email: d['email'] as String?,
      phone: d['phone'] as String?,
      role: d['role'] as String? ?? 'student',
      preferredLanguage: d['preferredLanguage'] as String? ?? 'en',
      uiLanguage: d['uiLanguage'] as String? ?? 'uz',
      level: d['level'] as String? ?? 'A1',
      avatarUrl: d['avatarUrl'] as String?,
      dailyGoalMinutes: d['dailyGoalMinutes'] as int? ?? 20,
      currentStreak: d['currentStreak'] as int? ?? 0,
      longestStreak: d['longestStreak'] as int? ?? 0,
      totalXp: d['totalXp'] as int? ?? 0,
      notifications: UserNotificationSettings(
        microSession: notif['microSession'] as bool? ?? true,
        streak: notif['streak'] as bool? ?? true,
        teacherContent: notif['teacherContent'] as bool? ?? true,
      ),
      preferences: UserPreferences(
        microSessionEnabled: prefs['microSessionEnabled'] as bool? ?? true,
        microSessionIntervalMin: prefs['microSessionIntervalMin'] as int? ?? 60,
        microSessionDurationMin: prefs['microSessionDurationMin'] as int? ?? 10,
        premiumTtsEnabled: prefs['premiumTtsEnabled'] as bool? ?? false,
        studentQuizAddEnabled: prefs['studentQuizAddEnabled'] as bool? ?? true,
      ),
      lastActiveDate: (d['lastActiveDate'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'preferredLanguage': preferredLanguage,
        'uiLanguage': uiLanguage,
        'level': level,
        'avatarUrl': avatarUrl,
        'dailyGoalMinutes': dailyGoalMinutes,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalXp': totalXp,
        'notifications': {
          'microSession': notifications.microSession,
          'streak': notifications.streak,
          'teacherContent': notifications.teacherContent,
        },
        'preferences': {
          'microSessionEnabled': preferences.microSessionEnabled,
          'microSessionIntervalMin': preferences.microSessionIntervalMin,
          'microSessionDurationMin': preferences.microSessionDurationMin,
          'premiumTtsEnabled': preferences.premiumTtsEnabled,
          'studentQuizAddEnabled': preferences.studentQuizAddEnabled,
        },
        'lastActiveDate':
            lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory UserProfileModel.fromEntity(UserProfile e) => UserProfileModel(
        id: e.id,
        fullName: e.fullName,
        email: e.email,
        phone: e.phone,
        role: e.role,
        preferredLanguage: e.preferredLanguage,
        uiLanguage: e.uiLanguage,
        level: e.level,
        avatarUrl: e.avatarUrl,
        dailyGoalMinutes: e.dailyGoalMinutes,
        currentStreak: e.currentStreak,
        longestStreak: e.longestStreak,
        totalXp: e.totalXp,
        notifications: e.notifications,
        preferences: e.preferences,
        lastActiveDate: e.lastActiveDate,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
}
