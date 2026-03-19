// QO'YISH: lib/features/learning_loop/domain/entities/micro_session.dart
// So'zona — Mikro-sessiya entity
// Har 1 soatda 10 daqiqa mashq — shu entity orqali boshqariladi

import 'package:equatable/equatable.dart';

/// Sessiya turi — navbatma-navbat almashadi
enum SessionType {
  flashcardQuiz, // Flashcard + Quiz
  listeningSpeaking, // Listening + Speaking
}

/// Sessiya holati
enum SessionStatus {
  scheduled, // Rejalashtirilgan
  inProgress, // Davom etmoqda
  completed, // Tugallangan
  skipped, // O'tkazib yuborilgan
}

/// Sessiya ichidagi bitta mashq
class SessionActivity extends Equatable {
  /// Mashq turi: "flashcard", "quiz", "listening", "speaking"
  final String type;

  /// Kontent ID
  final String contentId;

  /// Olingan ball (null = hali bajarilmagan)
  final int? score;

  /// Sarflangan vaqt (soniya)
  final int? timeSpentSeconds;

  const SessionActivity({
    required this.type,
    required this.contentId,
    this.score,
    this.timeSpentSeconds,
  });

  bool get isCompleted => score != null;

  SessionActivity copyWith({
    String? type,
    String? contentId,
    int? score,
    int? timeSpentSeconds,
  }) {
    return SessionActivity(
      type: type ?? this.type,
      contentId: contentId ?? this.contentId,
      score: score ?? this.score,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }

  @override
  List<Object?> get props => [type, contentId, score, timeSpentSeconds];
}

/// Mikro-sessiya — 1 soatda 1 marta, 10 daqiqa
class MicroSession extends Equatable {
  final String id;
  final String userId;

  /// Sessiya turi (navbatma-navbat)
  final SessionType sessionType;

  /// Holat
  final SessionStatus status;

  /// Rejalashtirilgan davomiylik (daqiqa)
  final int durationMinutes;

  /// Haqiqiy davomiylik (daqiqa) — tugatilgandan keyin
  final int? actualDurationMinutes;

  /// Sessiya ichidagi mashqlar
  final List<SessionActivity> activities;

  /// Umumiy ball (null = tugatilmagan)
  final int? overallScore;

  /// Qayta ko'rilgan zaif elementlar soni
  final int weakItemsReviewed;

  /// Yangi zaif elementlar soni
  final int newWeakItems;

  /// Olingan XP
  final int xpEarned;

  /// AI motivatsiya xabari
  final String? motivationMessage;

  /// Rejalashtirilgan vaqt
  final DateTime scheduledAt;

  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const MicroSession({
    required this.id,
    required this.userId,
    required this.sessionType,
    this.status = SessionStatus.scheduled,
    this.durationMinutes = 10,
    this.actualDurationMinutes,
    this.activities = const [],
    this.overallScore,
    this.weakItemsReviewed = 0,
    this.newWeakItems = 0,
    this.xpEarned = 0,
    this.motivationMessage,
    required this.scheduledAt,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  /// Sessiya tugallanganmi?
  bool get isCompleted => status == SessionStatus.completed;

  /// Sessiya davom etmoqdami?
  bool get isActive => status == SessionStatus.inProgress;

  /// Hozir sessiya vaqti kelganmi?
  bool get isDue =>
      status == SessionStatus.scheduled && DateTime.now().isAfter(scheduledAt);

  /// Sessiyani boshlash
  MicroSession start() {
    return copyWith(
      status: SessionStatus.inProgress,
      startedAt: DateTime.now(),
    );
  }

  /// Sessiyani tugatish
  MicroSession complete({
    required int overallScore,
    required int weakItemsReviewed,
    required int newWeakItems,
    required int xpEarned,
    String? motivationMessage,
  }) {
    final now = DateTime.now();
    final actualDuration = startedAt != null
        ? now.difference(startedAt!).inMinutes
        : durationMinutes;

    return copyWith(
      status: SessionStatus.completed,
      completedAt: now,
      actualDurationMinutes: actualDuration,
      overallScore: overallScore,
      weakItemsReviewed: weakItemsReviewed,
      newWeakItems: newWeakItems,
      xpEarned: xpEarned,
      motivationMessage: motivationMessage,
    );
  }

  /// Sessiyani o'tkazib yuborish
  MicroSession skip() {
    return copyWith(status: SessionStatus.skipped);
  }

  /// Sessiya turi matnini olish
  String get sessionTypeLabel {
    switch (sessionType) {
      case SessionType.flashcardQuiz:
        return 'Flashcard + Quiz';
      case SessionType.listeningSpeaking:
        return 'Listening + Speaking';
    }
  }

  MicroSession copyWith({
    String? id,
    String? userId,
    SessionType? sessionType,
    SessionStatus? status,
    int? durationMinutes,
    int? actualDurationMinutes,
    List<SessionActivity>? activities,
    int? overallScore,
    int? weakItemsReviewed,
    int? newWeakItems,
    int? xpEarned,
    String? motivationMessage,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return MicroSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionType: sessionType ?? this.sessionType,
      status: status ?? this.status,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      activities: activities ?? this.activities,
      overallScore: overallScore ?? this.overallScore,
      weakItemsReviewed: weakItemsReviewed ?? this.weakItemsReviewed,
      newWeakItems: newWeakItems ?? this.newWeakItems,
      xpEarned: xpEarned ?? this.xpEarned,
      motivationMessage: motivationMessage ?? this.motivationMessage,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, sessionType, status, scheduledAt];
}
