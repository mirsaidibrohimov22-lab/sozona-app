// QO'YISH: lib/core/services/adaptive_engine_service.dart
// So'zona — Adaptive Learning Engine (Flutter side)
// ✅ Barcha AI funksiyalarni Cloud Functions orqali chaqiradi
//
// Bu service:
// - Activity natijalarni backendga yuboradi
// - User profilini oladi
// - Adaptive quiz, speaking task, content plan oladi
// - AI Chat bilan suhbatlashadi

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/services/logger_service.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/activity_record.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/user_ai_profile.dart';

/// Adaptive Learning Engine — barcha AI interaksiyalar shu orqali
class AdaptiveEngineService {
  final FirebaseFunctions _functions;

  AdaptiveEngineService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  // ═══════════════════════════════════
  // 1. ACTIVITY SAQLASH
  // ═══════════════════════════════════

  /// Mashq natijasini backendga yuborish
  /// Quiz/Flashcard/Listening/Speaking tugaganda chaqiriladi
  Future<String?> recordActivity(ActivityRecord record) async {
    try {
      final result = await _functions
          .httpsCallable('recordActivity')
          .call(record.toCallData());

      final data = result.data as Map<String, dynamic>;
      LoggerService.info(
        '📊 Activity saqlandi: ${record.skillType.name} | ${record.scorePercent}%',
      );
      return data['activityId'] as String?;
    } catch (e) {
      LoggerService.error('Activity saqlash xatosi', error: e);
      return null;
    }
  }

  // ═══════════════════════════════════
  // 2. USER PROFIL
  // ═══════════════════════════════════

  /// Foydalanuvchi AI profilini olish
  Future<UserAiProfile?> getUserProfile() async {
    try {
      final result =
          await _functions.httpsCallable('fetchUserProfile').call({});

      final data = result.data as Map<String, dynamic>;
      return UserAiProfile.fromMap(data);
    } catch (e) {
      LoggerService.error('Profil olish xatosi', error: e);
      return null;
    }
  }

  // ═══════════════════════════════════
  // 3. ADAPTIVE QUIZ (60/20/20)
  // ═══════════════════════════════════

  /// Adaptive quiz yaratish — 60% zaif, 20% review, 20% yangi
  Future<Map<String, dynamic>?> generateAdaptiveQuiz({
    required String language,
    required String level,
    int questionCount = 10,
  }) async {
    try {
      final result = await _functions.httpsCallable('createAdaptiveQuiz').call({
        'language': language,
        'level': level,
        'questionCount': questionCount,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Adaptive quiz xatosi', error: e);
      return null;
    }
  }

  // ═══════════════════════════════════
  // 4. AI CHAT (O'qituvchi)
  // ═══════════════════════════════════

  /// AI o'qituvchi bilan suhbat
  Future<AiChatResponse?> chatWithTeacher({
    required String message,
    required String language,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final result = await _functions.httpsCallable('chatWithAI').call({
        'message': message,
        'language': language,
        'history': history,
      });

      final data = result.data as Map<String, dynamic>;
      return AiChatResponse.fromMap(data);
    } catch (e) {
      LoggerService.error('AI Chat xatosi', error: e);
      return null;
    }
  }

  /// Tezkor grammatik tushuntirish
  Future<Map<String, dynamic>?> quickGrammarExplain({
    required String topic,
    required String language,
    required String level,
  }) async {
    try {
      final result = await _functions.httpsCallable('quickGrammar').call({
        'topic': topic,
        'language': language,
        'level': level,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Quick grammar xatosi', error: e);
      return null;
    }
  }

  // ═══════════════════════════════════
  // 5. SPEAKING
  // ═══════════════════════════════════

  /// Speaking vazifa yaratish
  Future<SpeakingTaskData?> createSpeakingTask({
    required String language,
    required String level,
    String? topic,
    String taskType = 'describe',
  }) async {
    try {
      final result = await _functions.httpsCallable('createSpeakingTask').call({
        'language': language,
        'level': level,
        if (topic != null) 'topic': topic,
        'taskType': taskType,
      });

      final data = result.data as Map<String, dynamic>;
      return SpeakingTaskData.fromMap(data);
    } catch (e) {
      LoggerService.error('Speaking task xatosi', error: e);
      return null;
    }
  }

  /// Speaking natijasini baholash
  Future<SpeakingAssessmentData?> assessSpeaking({
    required String taskId,
    required String language,
    required String level,
    required String topic,
    required String transcribedText,
    required int audioDuration,
  }) async {
    try {
      final result =
          await _functions.httpsCallable('assessSpeakingResult').call({
        'taskId': taskId,
        'language': language,
        'level': level,
        'topic': topic,
        'transcribedText': transcribedText,
        'audioDuration': audioDuration,
      });

      final data = result.data as Map<String, dynamic>;
      return SpeakingAssessmentData.fromMap(data);
    } catch (e) {
      LoggerService.error('Speaking assessment xatosi', error: e);
      return null;
    }
  }

  // ═══════════════════════════════════
  // 6. ADAPTIVE CONTENT PLAN
  // ═══════════════════════════════════

  /// Keyingi mashqlar rejasini olish
  Future<AdaptivePlanData?> getAdaptivePlan({
    required String language,
    int sessionDuration = 10,
  }) async {
    try {
      final result = await _functions.httpsCallable('getAdaptivePlan').call({
        'language': language,
        'sessionDuration': sessionDuration,
      });

      final data = result.data as Map<String, dynamic>;
      return AdaptivePlanData.fromMap(data);
    } catch (e) {
      LoggerService.error('Adaptive plan xatosi', error: e);
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// RESPONSE DATA CLASSLARI
// ═══════════════════════════════════════════════════════════════

/// AI Chat javobi
class AiChatResponse {
  final String reply;
  final List<String> suggestions;
  final String? detectedTopic;
  final String? grammarTip;
  final RelatedExercise? relatedExercise;

  const AiChatResponse({
    required this.reply,
    this.suggestions = const [],
    this.detectedTopic,
    this.grammarTip,
    this.relatedExercise,
  });

  factory AiChatResponse.fromMap(Map<String, dynamic> map) {
    return AiChatResponse(
      reply: map['reply'] as String? ?? '',
      suggestions: List<String>.from(map['suggestions'] ?? []),
      detectedTopic: map['detectedTopic'] as String?,
      grammarTip: map['grammarTip'] as String?,
      relatedExercise: map['relatedExercise'] != null
          ? RelatedExercise.fromMap(
              Map<String, dynamic>.from(map['relatedExercise'] as Map),
            )
          : null,
    );
  }
}

/// Tegishli mashq tavsiyasi
class RelatedExercise {
  final String type;
  final String topic;
  final String reason;

  const RelatedExercise({
    required this.type,
    required this.topic,
    required this.reason,
  });

  factory RelatedExercise.fromMap(Map<String, dynamic> map) {
    return RelatedExercise(
      type: map['type'] as String? ?? 'quiz',
      topic: map['topic'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
    );
  }
}

/// Speaking vazifa ma'lumotlari
class SpeakingTaskData {
  final String taskId;
  final String instruction;
  final List<String> hints;
  final List<String> vocabulary;
  final int timeLimit;
  final List<String> criteria;

  const SpeakingTaskData({
    required this.taskId,
    required this.instruction,
    this.hints = const [],
    this.vocabulary = const [],
    this.timeLimit = 60,
    this.criteria = const [],
  });

  factory SpeakingTaskData.fromMap(Map<String, dynamic> map) {
    return SpeakingTaskData(
      taskId: map['taskId'] as String? ?? '',
      instruction: map['instruction'] as String? ?? '',
      hints: List<String>.from(map['hints'] ?? []),
      vocabulary: List<String>.from(map['vocabulary'] ?? []),
      timeLimit: (map['timeLimit'] as num?)?.toInt() ?? 60,
      criteria: List<String>.from(map['criteria'] ?? []),
    );
  }
}

/// Speaking baholash natijalari
class SpeakingAssessmentData {
  final int pronunciationScore;
  final int grammarScore;
  final int fluencyScore;
  final int vocabularyScore;
  final int overallScore;
  final String pronunciationFeedback;
  final String grammarFeedback;
  final String fluencyFeedback;
  final String vocabularyFeedback;
  final List<GrammarErrorData> grammarErrors;
  final List<String> vocabularyUsed;
  final List<String> suggestedVocabulary;
  final String overallFeedback;
  final List<String> improvementTips;
  final String? nextTask;

  const SpeakingAssessmentData({
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
  });

  factory SpeakingAssessmentData.fromMap(Map<String, dynamic> map) {
    return SpeakingAssessmentData(
      pronunciationScore: (map['pronunciationScore'] as num?)?.toInt() ?? 0,
      grammarScore: (map['grammarScore'] as num?)?.toInt() ?? 0,
      fluencyScore: (map['fluencyScore'] as num?)?.toInt() ?? 0,
      vocabularyScore: (map['vocabularyScore'] as num?)?.toInt() ?? 0,
      overallScore: (map['overallScore'] as num?)?.toInt() ?? 0,
      pronunciationFeedback: map['pronunciationFeedback'] as String? ?? '',
      grammarFeedback: map['grammarFeedback'] as String? ?? '',
      fluencyFeedback: map['fluencyFeedback'] as String? ?? '',
      vocabularyFeedback: map['vocabularyFeedback'] as String? ?? '',
      grammarErrors: (map['grammarErrors'] as List?)
              ?.map((e) =>
                  GrammarErrorData.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      vocabularyUsed: List<String>.from(map['vocabularyUsed'] ?? []),
      suggestedVocabulary: List<String>.from(map['suggestedVocabulary'] ?? []),
      overallFeedback: map['overallFeedback'] as String? ?? '',
      improvementTips: List<String>.from(map['improvementTips'] ?? []),
      nextTask: map['nextTask'] as String?,
    );
  }
}

/// Grammatik xato
class GrammarErrorData {
  final String original;
  final String corrected;
  final String explanation;
  final String rule;

  const GrammarErrorData({
    required this.original,
    required this.corrected,
    required this.explanation,
    required this.rule,
  });

  factory GrammarErrorData.fromMap(Map<String, dynamic> map) {
    return GrammarErrorData(
      original: map['original'] as String? ?? '',
      corrected: map['corrected'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
      rule: map['rule'] as String? ?? '',
    );
  }
}

/// Adaptive mashq rejasi
class AdaptivePlanData {
  final List<ContentSuggestionData> suggestions;
  final UserSummaryData userSummary;
  final List<SessionPlanItemData> sessionPlan;
  final String motivationNote;

  const AdaptivePlanData({
    required this.suggestions,
    required this.userSummary,
    required this.sessionPlan,
    required this.motivationNote,
  });

  factory AdaptivePlanData.fromMap(Map<String, dynamic> map) {
    return AdaptivePlanData(
      suggestions: (map['suggestions'] as List?)
              ?.map((e) => ContentSuggestionData.fromMap(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      userSummary: UserSummaryData.fromMap(
        Map<String, dynamic>.from(map['userSummary'] as Map? ?? {}),
      ),
      sessionPlan: (map['sessionPlan'] as List?)
              ?.map((e) => SessionPlanItemData.fromMap(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      motivationNote: map['motivationNote'] as String? ?? '',
    );
  }
}

/// Mashq tavsiyasi
class ContentSuggestionData {
  final String type;
  final String topic;
  final String difficulty;
  final String reason;
  final int priority;
  final int estimatedTime;
  final Map<String, dynamic> params;

  const ContentSuggestionData({
    required this.type,
    required this.topic,
    required this.difficulty,
    required this.reason,
    required this.priority,
    required this.estimatedTime,
    this.params = const {},
  });

  factory ContentSuggestionData.fromMap(Map<String, dynamic> map) {
    return ContentSuggestionData(
      type: map['type'] as String? ?? 'quiz',
      topic: map['topic'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'medium',
      reason: map['reason'] as String? ?? '',
      priority: (map['priority'] as num?)?.toInt() ?? 5,
      estimatedTime: (map['estimatedTime'] as num?)?.toInt() ?? 5,
      params: Map<String, dynamic>.from(map['params'] as Map? ?? {}),
    );
  }
}

/// Foydalanuvchi qisqacha profili
class UserSummaryData {
  final String level;
  final String strongSkill;
  final String weakSkill;
  final List<String> weakTopics;
  final double averageScore;

  const UserSummaryData({
    required this.level,
    required this.strongSkill,
    required this.weakSkill,
    required this.weakTopics,
    required this.averageScore,
  });

  factory UserSummaryData.fromMap(Map<String, dynamic> map) {
    return UserSummaryData(
      level: map['level'] as String? ?? 'A1',
      strongSkill: map['strongSkill'] as String? ?? '',
      weakSkill: map['weakSkill'] as String? ?? '',
      weakTopics: List<String>.from(map['weakTopics'] ?? []),
      averageScore: (map['averageScore'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Sessiya rejasi elementi
class SessionPlanItemData {
  final int order;
  final String type;
  final String topic;
  final int duration;

  const SessionPlanItemData({
    required this.order,
    required this.type,
    required this.topic,
    required this.duration,
  });

  factory SessionPlanItemData.fromMap(Map<String, dynamic> map) {
    return SessionPlanItemData(
      order: (map['order'] as num?)?.toInt() ?? 1,
      type: map['type'] as String? ?? 'quiz',
      topic: map['topic'] as String? ?? '',
      duration: (map['duration'] as num?)?.toInt() ?? 5,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RIVERPOD PROVIDER
// ═══════════════════════════════════════════════════════════════

/// [AdaptiveEngineService] provider
final adaptiveEngineProvider = Provider<AdaptiveEngineService>((ref) {
  return AdaptiveEngineService();
});
