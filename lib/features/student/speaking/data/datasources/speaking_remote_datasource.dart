// lib/features/student/speaking/data/datasources/speaking_remote_datasource.dart
// So'zona — Speaking Remote DataSource
// ✅ AI FALLBACK: Cloud Functions ishlamasa → mock speaking prompts qaytariladi
// ✅ App hech qachon crash bo'lmaydi — AI yo'q bo'lsa ham ishlaydi

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:my_first_app/core/constants/api_endpoints.dart';
import 'package:my_first_app/features/student/speaking/data/models/speaking_model.dart';

abstract class SpeakingRemoteDataSource {
  Future<SpeakingModel> generateDialog({
    required String topic,
    required String language,
    required String level,
  });

  Future<List<SpeakingModel>> getExercises({
    String? language,
    String? level,
  });

  Future<Map<String, dynamic>> createSpeakingTask({
    required String language,
    required String level,
    String? topic,
    String taskType,
  });

  Future<Map<String, dynamic>> assessSpeakingResponse({
    required String taskId,
    required String language,
    required String level,
    required String topic,
    required String transcribedText,
    required int audioDuration,
  });

  Future<void> recordSpeakingActivity({
    required String topic,
    required String language,
    required String level,
    required int overallScore,
    required int responseTime,
    required List<String> grammarErrors,
  });

  Future<Map<String, dynamic>> sendMessage({
    required String exerciseId,
    required String userMessage,
    required int turnIndex,
  });
}

class SpeakingRemoteDataSourceImpl implements SpeakingRemoteDataSource {
  final FirebaseFunctions functions;
  final FirebaseFirestore firestore;

  SpeakingRemoteDataSourceImpl({
    required this.functions,
    required this.firestore,
  });

  // ═══════════════════════════════════════════════════════════════
  // MOCK DATA — AI ishlamasa ishlatiladi
  // ═══════════════════════════════════════════════════════════════

  static List<Map<String, dynamic>> _mockSpeakingTopics(String language) {
    if (language == 'de') {
      return [
        {
          'id': 'mock-de-1',
          'topic': 'Mein Alltag',
          'prompt': 'Beschreiben Sie Ihren typischen Tag.',
          'hint': 'Wann stehen Sie auf? Was frühstücken Sie?',
        },
        {
          'id': 'mock-de-2',
          'topic': 'Meine Familie',
          'prompt': 'Erzählen Sie über Ihre Familie.',
          'hint': 'Wie viele Personen? Was machen sie?',
        },
        {
          'id': 'mock-de-3',
          'topic': 'Hobbys und Freizeit',
          'prompt': 'Was machen Sie in Ihrer Freizeit?',
          'hint': 'Sport, Musik, Lesen?',
        },
      ];
    }
    return [
      {
        'id': 'mock-en-1',
        'topic': 'My Daily Routine',
        'prompt': 'Describe your typical day from morning to evening.',
        'hint': 'When do you wake up? What do you have for breakfast?',
      },
      {
        'id': 'mock-en-2',
        'topic': 'My Favorite Place',
        'prompt': 'Describe your favorite place and why you like it.',
        'hint': 'Is it a city, a park, your home?',
      },
      {
        'id': 'mock-en-3',
        'topic': 'My Best Friend',
        'prompt': 'Talk about your best friend.',
        'hint': 'How did you meet? What do you do together?',
      },
      {
        'id': 'mock-en-4',
        'topic': 'Last Weekend',
        'prompt': 'What did you do last weekend?',
        'hint': 'Did you go somewhere? Meet someone?',
      },
      {
        'id': 'mock-en-5',
        'topic': 'My Goals',
        'prompt': 'What are your goals for this year?',
        'hint': 'Study, career, personal growth?',
      },
    ];
  }

  static SpeakingModel _buildMockExercise(
      Map<String, dynamic> t, String lang, String level) {
    return SpeakingModel.fromJson({
      'topic': t['topic'],
      'language': lang,
      'level': level,
      'turns': [
        {
          'role': 'ai',
          'text': t['prompt'],
          'hint': t['hint'],
          'order': 0,
        }
      ],
      'vocabulary': [],
      'culturalNotes': null,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    }, t['id'] as String);
  }

  // ═══════════════════════════════════════════════════════════════
  // METODLAR
  // ═══════════════════════════════════════════════════════════════

  @override
  Future<SpeakingModel> generateDialog({
    required String topic,
    required String language,
    required String level,
  }) async {
    try {
      final callable = functions.httpsCallable(
        ApiEndpoints.generateSpeaking,
        options: HttpsCallableOptions(timeout: ApiEndpoints.longTimeout),
      );
      final result = await callable.call({
        'topic': topic,
        'language': language,
        'level': level,
      });

      final data = result.data as Map<String, dynamic>;
      final docRef = await firestore.collection('speaking_exercises').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return SpeakingModel.fromJson(data, docRef.id);
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
          '⚠️ Speaking generateDialog AI xatosi: ${e.code} — mock qaytariladi');
      // AI ishlamasa — mock qaytariladi
      final topics = _mockSpeakingTopics(language);
      final matched = topics.firstWhere(
        (t) =>
            (t['topic'] as String).toLowerCase().contains(topic.toLowerCase()),
        orElse: () => topics.first,
      );
      return _buildMockExercise(matched, language, level);
    } catch (e) {
      debugPrint('⚠️ Speaking generateDialog xatosi: $e — mock qaytariladi');
      final topics = _mockSpeakingTopics(language);
      return _buildMockExercise(topics.first, language, level);
    }
  }

  @override
  Future<List<SpeakingModel>> getExercises({
    String? language,
    String? level,
  }) async {
    try {
      Query query = firestore.collection('speaking_exercises');
      if (language != null) {
        query = query.where('language', isEqualTo: language);
      }
      if (level != null) {
        query = query.where('level', isEqualTo: level);
      }
      query = query.orderBy('createdAt', descending: true).limit(20);

      final snapshot = await query.get();
      final results = snapshot.docs
          .map((doc) => SpeakingModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      // Firestore bo'sh bo'lsa — mock qaytariladi
      if (results.isEmpty) {
        debugPrint('⚠️ Speaking exercises bo\'sh — mock qaytariladi');
        return _getMockExercises(language ?? 'en', level ?? 'A1');
      }
      return results;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        // Index yo'q — orderBy olmagan fallback
        try {
          final snapshot =
              await firestore.collection('speaking_exercises').limit(20).get();
          final results = snapshot.docs
              .map((doc) => SpeakingModel.fromJson(doc.data(), doc.id))
              .toList();
          if (results.isEmpty) {
            return _getMockExercises(language ?? 'en', level ?? 'A1');
          }
          return results;
        } catch (_) {
          return _getMockExercises(language ?? 'en', level ?? 'A1');
        }
      }
      debugPrint(
          '⚠️ Speaking getExercises Firebase xatosi: ${e.message} — mock qaytariladi');
      return _getMockExercises(language ?? 'en', level ?? 'A1');
    } catch (e) {
      debugPrint('⚠️ Speaking getExercises xatosi: $e — mock qaytariladi');
      return _getMockExercises(language ?? 'en', level ?? 'A1');
    }
  }

  List<SpeakingModel> _getMockExercises(String language, String level) {
    return _mockSpeakingTopics(language)
        .map((t) => _buildMockExercise(t, language, level))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createSpeakingTask({
    required String language,
    required String level,
    String? topic,
    String taskType = 'describe',
  }) async {
    try {
      final callable = functions.httpsCallable(
        ApiEndpoints.createSpeakingTask,
        options: HttpsCallableOptions(timeout: ApiEndpoints.longTimeout),
      );
      final result = await callable.call({
        'language': language,
        'level': level,
        if (topic != null) 'topic': topic,
        'taskType': taskType,
      });
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
          '⚠️ createSpeakingTask AI xatosi: ${e.code} — mock qaytariladi');
      return _mockSpeakingTask(language, level, topic);
    } catch (e) {
      debugPrint('⚠️ createSpeakingTask xatosi: $e — mock qaytariladi');
      return _mockSpeakingTask(language, level, topic);
    }
  }

  Map<String, dynamic> _mockSpeakingTask(
      String language, String level, String? topic) {
    final topics = _mockSpeakingTopics(language);
    final t = topic != null
        ? topics.firstWhere(
            (x) => (x['topic'] as String)
                .toLowerCase()
                .contains(topic.toLowerCase()),
            orElse: () => topics.first,
          )
        : topics.first;
    return {
      'taskId': 'mock-task-${DateTime.now().millisecondsSinceEpoch}',
      'topic': t['topic'],
      'prompt': t['prompt'],
      'hint': t['hint'],
      'language': language,
      'level': level,
      'isMock': true,
    };
  }

  @override
  Future<Map<String, dynamic>> assessSpeakingResponse({
    required String taskId,
    required String language,
    required String level,
    required String topic,
    required String transcribedText,
    required int audioDuration,
  }) async {
    try {
      final callable = functions.httpsCallable(
        ApiEndpoints.assessSpeaking,
        options: HttpsCallableOptions(timeout: ApiEndpoints.assessmentTimeout),
      );
      final result = await callable.call({
        'taskId': taskId,
        'language': language,
        'level': level,
        'topic': topic,
        'transcribedText': transcribedText,
        'audioDuration': audioDuration,
      });
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
          '⚠️ assessSpeaking AI xatosi: ${e.code} — mock baho qaytariladi');
      return _mockAssessment(transcribedText);
    } catch (e) {
      debugPrint('⚠️ assessSpeaking xatosi: $e — mock baho qaytariladi');
      return _mockAssessment(transcribedText);
    }
  }

  Map<String, dynamic> _mockAssessment(String text) {
    final wordCount = text.trim().split(RegExp(r'\s+')).length;
    final score = (wordCount * 3).clamp(30, 85);
    return {
      'overallScore': score,
      'pronunciation': score,
      'grammar': score,
      'fluency': score,
      'vocabulary': score,
      'feedback':
          'AI baholash hozir mavjud emas. Keyinroq to\'liq baho beriladi.',
      'suggestions': [
        'Gap tuzilishiga e\'tibor bering',
        'Ko\'proq so\'z ishlating'
      ],
      'isMock': true,
    };
  }

  @override
  Future<void> recordSpeakingActivity({
    required String topic,
    required String language,
    required String level,
    required int overallScore,
    required int responseTime,
    required List<String> grammarErrors,
  }) async {
    try {
      final callable = functions.httpsCallable(
        ApiEndpoints.recordActivity,
        options: HttpsCallableOptions(timeout: ApiEndpoints.defaultTimeout),
      );
      await callable.call({
        'skillType': 'speaking',
        'topic': topic,
        'difficulty': 'medium',
        'correctAnswers': overallScore >= 60 ? 1 : 0,
        'wrongAnswers': overallScore < 60 ? 1 : 0,
        'responseTime': responseTime,
        'vocabularyUsed': <String>[],
        'grammarErrors': grammarErrors,
        'language': language,
        'level': level,
        'scorePercent': overallScore,
        'weakItems': grammarErrors,
        'strongItems': <String>[],
      });
    } catch (e) {
      // Activity saqlash xatosi — sessiyani buzmaydi
      debugPrint('⚠️ Speaking activity saqlash xatosi: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> sendMessage({
    required String exerciseId,
    required String userMessage,
    required int turnIndex,
  }) async {
    final wordCount = userMessage.trim().split(RegExp(r'\s+')).length;
    final hasContent = wordCount >= 2;
    return {
      'isCorrect': hasContent,
      'feedback': hasContent ? 'Davom eting! 👍' : 'Kamida 2 so\'z yozing',
      'score': hasContent ? 10 : 0,
      'wordCount': wordCount,
    };
  }
}
