// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Listening Exercise Entity
// QO'YISH: lib/features/student/listening/domain/entities/listening_exercise.dart
// ═══════════════════════════════════════════════════════════════
//
// Bu fayl — Listening Exercise'ning domain entity'si.
// Audio bilan bog'liq mashqlar uchun.
//
// Bolaga tushuntirish:
// Bu — audio dars. Tinglab, savolga javob berasan.
// Masalan: podcast, dialog, yoki hikoya eshitasan va tushunganingni tekshirasan.
// ═══════════════════════════════════════════════════════════════

import 'package:equatable/equatable.dart';

/// Listening Exercise Entity — audio mashq
class ListeningExercise extends Equatable {
  /// Exercise ID
  final String id;

  /// Sarlavha
  final String title;

  /// Qisqacha tavsif
  final String description;

  /// Audio URL (Firebase Storage yoki CDN)
  final String audioUrl;

  /// Audio davomiyligi (sekundda)
  final int duration;

  /// Til (english / deutsch)
  final String language;

  /// Daraja (beginner / intermediate / advanced)
  final String level;

  /// Mavzu (masalan: "daily_conversation", "news", "story")
  final String topic;

  /// Transcript (audio matni) - ko'rsatish/yashirish mumkin
  final String transcript;

  /// Savollar (comprehension questions)
  final List<ListeningQuestion> questions;

  /// Yaratilgan sana
  final DateTime createdAt;

  /// O'qituvchi tomonidan yaratilganmi?
  final bool isTeacherCreated;

  /// Yaratuvchi ID
  final String? createdBy;

  /// Sinf ID (agar teacher quiz bo'lsa)
  final String? classId;

  /// Aktiv/Arxivlangan
  final bool isActive;

  const ListeningExercise({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.duration,
    required this.language,
    required this.level,
    required this.topic,
    required this.transcript,
    required this.questions,
    required this.createdAt,
    this.isTeacherCreated = false,
    this.createdBy,
    this.classId,
    this.isActive = true,
  });

  // ═══════════════════════════════════
  // Qulaylik metodlari
  // ═══════════════════════════════════

  /// Audio davomiyligi (formatlangan)
  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Til nomi (o'zbekchada)
  String get languageLabel {
    switch (language.toLowerCase()) {
      case 'english':
        return 'Ingliz tili';
      case 'deutsch':
      case 'german':
        return 'Nemis tili';
      default:
        return language;
    }
  }

  /// Daraja nomi
  String get levelLabel {
    switch (level) {
      case 'beginner':
        return 'Boshlang\'ich';
      case 'intermediate':
        return 'O\'rta';
      case 'advanced':
        return 'Murakkab';
      default:
        return level;
    }
  }

  /// Mavzu nomi
  String get topicLabel {
    switch (topic) {
      case 'daily_conversation':
        return 'Kundalik suhbat';
      case 'news':
        return 'Yangiliklar';
      case 'story':
        return 'Hikoya';
      case 'interview':
        return 'Intervyu';
      case 'lecture':
        return 'Ma\'ruza';
      default:
        return topic;
    }
  }

  /// Savollar soni
  int get questionCount => questions.length;

  /// Qisqacha ma'lumot
  String get summary {
    return '$durationFormatted • $levelLabel • $questionCount savol';
  }

  // ═══════════════════════════════════
  // CopyWith
  // ═══════════════════════════════════
  ListeningExercise copyWith({
    String? id,
    String? title,
    String? description,
    String? audioUrl,
    int? duration,
    String? language,
    String? level,
    String? topic,
    String? transcript,
    List<ListeningQuestion>? questions,
    DateTime? createdAt,
    bool? isTeacherCreated,
    String? createdBy,
    String? classId,
    bool? isActive,
  }) {
    return ListeningExercise(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      language: language ?? this.language,
      level: level ?? this.level,
      topic: topic ?? this.topic,
      transcript: transcript ?? this.transcript,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      isTeacherCreated: isTeacherCreated ?? this.isTeacherCreated,
      createdBy: createdBy ?? this.createdBy,
      classId: classId ?? this.classId,
      isActive: isActive ?? this.isActive,
    );
  }

  // ═══════════════════════════════════
  // Equatable
  // ═══════════════════════════════════
  @override
  List<Object?> get props => [
        id,
        title,
        description,
        audioUrl,
        duration,
        language,
        level,
        topic,
        transcript,
        questions,
        createdAt,
        isTeacherCreated,
        createdBy,
        classId,
        isActive,
      ];
}

// ═══════════════════════════════════════════════════════════════
// Listening Question Entity
// ═══════════════════════════════════════════════════════════════

/// Listening Question — audio bo'yicha savol
class ListeningQuestion extends Equatable {
  /// Savol ID
  final String id;

  /// Savol matni
  final String question;

  /// Savol turi (mcq / true_false / short_answer)
  final String type;

  /// Variantlar (faqat MCQ uchun)
  final List<String>? options;

  /// To'g'ri javob
  final String correctAnswer;

  /// Tushuntirish
  final String explanation;

  /// Audio'ning qaysi daqiqasida? (timestamp in seconds)
  final int? timestamp;

  const ListeningQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options,
    required this.correctAnswer,
    required this.explanation,
    this.timestamp,
  });

  /// Javobni tekshirish
  bool isCorrect(String userAnswer) {
    return userAnswer.trim().toLowerCase() ==
        correctAnswer.trim().toLowerCase();
  }

  @override
  List<Object?> get props => [
        id,
        question,
        type,
        options,
        correctAnswer,
        explanation,
        timestamp,
      ];
}
