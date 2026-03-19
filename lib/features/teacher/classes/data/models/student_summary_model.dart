// QO'YISH: lib/features/teacher/classes/data/models/student_summary_model.dart
// So'zona — StudentSummary Firestore modeli

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_first_app/features/teacher/classes/domain/entities/student_summary.dart';

/// StudentSummary ning Firestore versiyasi
class StudentSummaryModel extends StudentSummary {
  const StudentSummaryModel({
    required super.userId,
    required super.fullName,
    required super.level,
    required super.joinedAt,
    required super.lastActiveAt,
    required super.averageScore,
    required super.totalAttempts,
    required super.currentStreak,
    super.avatarUrl,
  });

  /// Firestore members subcollection'dan yaratish
  factory StudentSummaryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentSummaryModel.fromMap(data, doc.id);
  }

  /// Map'dan yaratish
  factory StudentSummaryModel.fromMap(Map<String, dynamic> map, String userId) {
    return StudentSummaryModel(
      userId: userId,
      fullName: map['fullName'] as String? ?? '',
      level: map['level'] as String? ?? 'A1',
      joinedAt: _parseTimestamp(map['joinedAt']),
      lastActiveAt: _parseTimestamp(map['lastActiveAt']),
      averageScore: (map['averageScore'] as num?)?.toDouble() ?? 0.0,
      totalAttempts: (map['totalAttempts'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      avatarUrl: map['avatarUrl'] as String?,
    );
  }

  /// Firestore'ga saqlash uchun Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fullName': fullName,
      'level': level,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'averageScore': averageScore,
      'totalAttempts': totalAttempts,
      'currentStreak': currentStreak,
      'avatarUrl': avatarUrl,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
