// ═══════════════════════════════════════════════════════════════════════════════
// SO'ZONA — Listening Model
// QO'YISH: lib/features/student/listening/data/models/listening_model.dart
// ✅ FIX: createdAt — Timestamp, int va String uchlarini qo'llab-quvvatlaydi
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/student/listening/domain/entities/listening_exercise.dart';

/// createdAt maydonini xavfsiz o'qish — Timestamp, int, String hammasini qabul qiladi
DateTime _parseCreatedAt(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

/// Listening Model — JSON serialization bilan
class ListeningModel extends ListeningExercise {
  const ListeningModel({
    required super.id,
    required super.title,
    required super.description,
    required super.audioUrl,
    required super.duration,
    required super.language,
    required super.level,
    required super.topic,
    required super.transcript,
    required super.questions,
    required super.createdAt,
    super.isTeacherCreated,
    super.createdBy,
    super.classId,
    super.isActive,
  });

  // ═══════════════════════════════════
  // JSON → Model (Firestore)
  // ✅ FIX: _parseCreatedAt — Timestamp muammosi hal qilindi
  // ═══════════════════════════════════

  factory ListeningModel.fromFirestore(
    Map<String, dynamic> json,
    String id,
  ) {
    return ListeningModel(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      language: json['language'] as String? ?? 'english',
      level: json['level'] as String? ?? 'beginner',
      topic: json['topic'] as String? ?? '',
      transcript: json['transcript'] as String? ?? '',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) =>
                  ListeningQuestionModel.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      // ✅ FIX: Timestamp, int, String barchasini qo'llab-quvvatlaydi
      createdAt: _parseCreatedAt(json['createdAt']),
      isTeacherCreated: json['isTeacherCreated'] as bool? ?? false,
      createdBy: json['createdBy'] as String?,
      classId: json['classId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  factory ListeningModel.fromJson(Map<String, dynamic> json) {
    return ListeningModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      language: json['language'] as String? ?? 'english',
      level: json['level'] as String? ?? 'beginner',
      topic: json['topic'] as String? ?? '',
      transcript: json['transcript'] as String? ?? '',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) =>
                  ListeningQuestionModel.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _parseCreatedAt(json['createdAt']),
      isTeacherCreated: json['isTeacherCreated'] as bool? ?? false,
      createdBy: json['createdBy'] as String?,
      classId: json['classId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // ═══════════════════════════════════
  // Model → JSON
  // ═══════════════════════════════════

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'duration': duration,
      'language': language,
      'level': level,
      'topic': topic,
      'transcript': transcript,
      'questions': questions
          .map((q) => ListeningQuestionModel.fromEntity(q).toJson())
          .toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isTeacherCreated': isTeacherCreated,
      'createdBy': createdBy,
      'classId': classId,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'duration': duration,
      'language': language,
      'level': level,
      'topic': topic,
      'transcript': transcript,
      'questions': questions
          .map((q) => ListeningQuestionModel.fromEntity(q).toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'isTeacherCreated': isTeacherCreated,
      'createdBy': createdBy,
      'classId': classId,
      'isActive': isActive,
    };
  }

  factory ListeningModel.fromEntity(ListeningExercise entity) {
    return ListeningModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      audioUrl: entity.audioUrl,
      duration: entity.duration,
      language: entity.language,
      level: entity.level,
      topic: entity.topic,
      transcript: entity.transcript,
      questions: entity.questions,
      createdAt: entity.createdAt,
      isTeacherCreated: entity.isTeacherCreated,
      createdBy: entity.createdBy,
      classId: entity.classId,
      isActive: entity.isActive,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Listening Question Model
// ═══════════════════════════════════════════════════════════════════════════════

class ListeningQuestionModel extends ListeningQuestion {
  const ListeningQuestionModel({
    required super.id,
    required super.question,
    required super.type,
    super.options,
    required super.correctAnswer,
    required super.explanation,
    super.timestamp,
  });

  factory ListeningQuestionModel.fromJson(Map<String, dynamic> json) {
    return ListeningQuestionModel(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      type: json['type'] as String? ?? 'mcq',
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      timestamp: json['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'timestamp': timestamp,
    };
  }

  factory ListeningQuestionModel.fromEntity(ListeningQuestion entity) {
    return ListeningQuestionModel(
      id: entity.id,
      question: entity.question,
      type: entity.type,
      options: entity.options,
      correctAnswer: entity.correctAnswer,
      explanation: entity.explanation,
      timestamp: entity.timestamp,
    );
  }
}
