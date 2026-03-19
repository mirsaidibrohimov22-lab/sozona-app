import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';

/// Question Model — JSON serialization bilan
/// QuizQuestion entity ni extend qiladi
class QuestionModel extends QuizQuestion {
  const QuestionModel({
    required super.id,
    required super.type,
    required super.question,
    required super.options,
    required super.correctAnswer,
    required super.explanation,
    super.points = 10,
    super.timeLimitSeconds = 30,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String? ?? '',
      type: _parseType(json['type'] as String? ?? 'mcq'),
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      points: json['points'] as int? ?? 10,
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 30,
    );
  }

  static QuestionType _parseType(String type) {
    switch (type) {
      case 'trueFalse':
        return QuestionType.trueFalse;
      case 'fillBlank':
        return QuestionType.fillBlank;
      case 'artikel':
        return QuestionType.artikel;
      default:
        return QuestionType.mcq;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'points': points,
      'timeLimitSeconds': timeLimitSeconds,
    };
  }

  QuestionModel copyWith({
    String? id,
    QuestionType? type,
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    int? points,
    int? timeLimitSeconds,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      points: points ?? this.points,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
    );
  }

  static QuestionModel fromEntity(QuizQuestion entity) {
    return QuestionModel(
      id: entity.id,
      type: entity.type,
      question: entity.question,
      options: entity.options,
      correctAnswer: entity.correctAnswer,
      explanation: entity.explanation,
      points: entity.points,
      timeLimitSeconds: entity.timeLimitSeconds,
    );
  }
}
