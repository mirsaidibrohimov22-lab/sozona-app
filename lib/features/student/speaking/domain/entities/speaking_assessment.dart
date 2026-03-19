// QO'YISH: lib/features/student/speaking/domain/entities/speaking_assessment.dart
// So'zona — Speaking Assessment Entity
// ✅ Prompt talabi: pronunciation, grammar, fluency bo'yicha baholash

import 'package:equatable/equatable.dart';

/// Speaking vazifa (AI yaratadi)
class SpeakingTask extends Equatable {
  final String taskId;
  final String instruction; // "Describe your favorite place"
  final List<String> hints; // Yordam beruvchi savollar
  final List<String> vocabulary; // Ishlatishi kerak bo'lgan so'zlar
  final int timeLimit; // Soniyalarda
  final List<String> criteria; // Baholash mezonlari

  const SpeakingTask({
    required this.taskId,
    required this.instruction,
    this.hints = const [],
    this.vocabulary = const [],
    this.timeLimit = 60,
    this.criteria = const [],
  });

  @override
  List<Object?> get props => [taskId, instruction];
}

/// Speaking baholash natijasi
class SpeakingAssessment extends Equatable {
  /// Talaffuz balli (0-100)
  final int pronunciationScore;

  /// Grammatika balli (0-100)
  final int grammarScore;

  /// Ravonlik balli (0-100)
  final int fluencyScore;

  /// So'z boyligi balli (0-100)
  final int vocabularyScore;

  /// Umumiy ball (0-100)
  final int overallScore;

  /// Har bir mezon bo'yicha izoh
  final String pronunciationFeedback;
  final String grammarFeedback;
  final String fluencyFeedback;
  final String vocabularyFeedback;

  /// Grammatik xatolar ro'yxati
  final List<SpeakingGrammarError> grammarErrors;

  /// Ishlatilgan so'zlar
  final List<String> vocabularyUsed;

  /// Tavsiya qilingan yangi so'zlar
  final List<String> suggestedVocabulary;

  /// Umumiy tavsiya
  final String overallFeedback;

  /// Yaxshilash maslahatlari
  final List<String> improvementTips;

  /// Keyingi vazifa tavsiyasi
  final String? nextTask;

  /// Qo'shimcha ma'lumotlar
  final int wordsPerMinute;
  final int totalWords;
  final int audioDuration;

  const SpeakingAssessment({
    required this.pronunciationScore,
    required this.grammarScore,
    required this.fluencyScore,
    required this.vocabularyScore,
    required this.overallScore,
    required this.pronunciationFeedback,
    required this.grammarFeedback,
    required this.fluencyFeedback,
    required this.vocabularyFeedback,
    this.grammarErrors = const [],
    this.vocabularyUsed = const [],
    this.suggestedVocabulary = const [],
    required this.overallFeedback,
    this.improvementTips = const [],
    this.nextTask,
    this.wordsPerMinute = 0,
    this.totalWords = 0,
    this.audioDuration = 0,
  });

  /// O'rtacha ball (4 ta mezon)
  double get averageScore =>
      (pronunciationScore + grammarScore + fluencyScore + vocabularyScore) / 4;

  /// Yaxshi natijami?
  bool get isPassing => overallScore >= 60;

  /// Ajoyib natijami?
  bool get isExcellent => overallScore >= 85;

  /// Eng zaif ko'nikma
  String get weakestArea {
    final scores = {
      'Talaffuz': pronunciationScore,
      'Grammatika': grammarScore,
      'Ravonlik': fluencyScore,
      "So'z boyligi": vocabularyScore,
    };
    return scores.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  /// Eng kuchli ko'nikma
  String get strongestArea {
    final scores = {
      'Talaffuz': pronunciationScore,
      'Grammatika': grammarScore,
      'Ravonlik': fluencyScore,
      "So'z boyligi": vocabularyScore,
    };
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Yulduzlar soni (1-5)
  int get stars {
    if (overallScore >= 90) return 5;
    if (overallScore >= 75) return 4;
    if (overallScore >= 60) return 3;
    if (overallScore >= 40) return 2;
    return 1;
  }

  @override
  List<Object?> get props => [
        pronunciationScore,
        grammarScore,
        fluencyScore,
        vocabularyScore,
        overallScore,
      ];
}

/// Grammatik xato
class SpeakingGrammarError extends Equatable {
  /// Xato gap
  final String original;

  /// To'g'ri shakl
  final String corrected;

  /// Tushuntirish
  final String explanation;

  /// Grammatik qoida nomi
  final String rule;

  const SpeakingGrammarError({
    required this.original,
    required this.corrected,
    required this.explanation,
    required this.rule,
  });

  @override
  List<Object?> get props => [original, corrected, rule];
}
