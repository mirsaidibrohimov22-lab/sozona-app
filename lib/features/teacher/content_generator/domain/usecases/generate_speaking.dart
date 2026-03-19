// lib/features/teacher/content_generator/domain/usecases/generate_speaking.dart
// ✅ FIX: generateListening o'rniga generateSpeaking chaqiradi
// Speaking Dialog — o'qituvchi sinfga dialog suhbat yuboradi

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/content_generator/data/models/generated_content_model.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/repositories/content_generator_repository.dart';

/// AI yordamida Speaking Dialog yaratish
class GenerateSpeaking
    extends UseCase<GeneratedContent, GenerateSpeakingParams> {
  final ContentGeneratorRepository repository;
  final FirebaseFunctions functions;

  GenerateSpeaking(this.repository, this.functions);

  @override
  Future<Either<Failure, GeneratedContent>> call(
      GenerateSpeakingParams params) async {
    try {
      debugPrint('🚀 generateSpeakingDialog chaqirilmoqda: ${params.topic}');

      final callable = functions.httpsCallable(
        'createSpeakingDialog',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );

      final result = await callable.call({
        'language': params.language,
        'level': params.level,
        'topic': params.topic,
        'turns': 6,
      });

      final raw = Map<String, dynamic>.from(result.data as Map);
      debugPrint('✅ Speaking dialog yaratildi');

      // Speaking dialog data ni GeneratedContent ga o'tkazish
      final content = GeneratedContentModel(
        id: 'speaking_${DateTime.now().millisecondsSinceEpoch}',
        type: ContentType.speaking,
        language: params.language,
        level: params.level,
        topic: params.topic,
        data: {
          'dialog': raw['dialog'] ?? raw['turns'] ?? [],
          'transcript': raw['transcript'] ?? raw['fullText'] ?? '',
          'exercises': _buildExercises(raw, params.topic),
          'isMock': false,
        },
        status: GenerationStatus.completed,
        generatedAt: DateTime.now(),
        aiModel: 'gemini',
      );

      return Right(content);
    } catch (e) {
      debugPrint('❌ Speaking xato: $e');
      // Xato bo'lsa Listening bilan ishlatamiz (fallback)
      return repository.generateListening(
        language: params.language,
        level: params.level,
        topic: params.topic,
      );
    }
  }

  List<Map<String, dynamic>> _buildExercises(
      Map<String, dynamic> raw, String topic) {
    final dialog = raw['dialog'] as List? ?? raw['turns'] as List? ?? [];
    if (dialog.isNotEmpty) {
      return dialog.map((turn) {
        final t = Map<String, dynamic>.from(turn as Map? ?? {});
        return {
          'prompt': t['text'] ?? t['content'] ?? '',
          'speaker': t['speaker'] ?? t['role'] ?? 'Speaker',
          'sampleAnswer': t['text'] ?? '',
        };
      }).toList();
    }
    return [
      {'prompt': 'Talk about $topic', 'sampleAnswer': '', 'speaker': 'You'},
    ];
  }
}

class GenerateSpeakingParams extends Equatable {
  final String language;
  final String level;
  final String topic;

  const GenerateSpeakingParams({
    required this.language,
    required this.level,
    required this.topic,
  });

  @override
  List<Object?> get props => [language, level, topic];
}
