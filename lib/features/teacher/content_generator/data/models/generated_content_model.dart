// QO'YISH: lib/features/teacher/content_generator/data/models/generated_content_model.dart
// Generated Content Model — Entity va JSON o'rtasida converter

import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';

/// Generated Content Model — JSON bilan ishlash uchun
///
/// Bolaga: Entity — biznes uchun, Model — ma'lumotlar uchun.
/// Model JSON'ga aylantirish va JSON'dan olish usullariga ega.
class GeneratedContentModel extends GeneratedContent {
  const GeneratedContentModel({
    required super.id,
    required super.type,
    required super.language,
    required super.level,
    required super.topic,
    required super.data,
    required super.status,
    super.errorMessage,
    required super.generatedAt,
    required super.aiModel,
  });

  /// Entity'dan Model yaratish
  factory GeneratedContentModel.fromEntity(GeneratedContent entity) {
    return GeneratedContentModel(
      id: entity.id,
      type: entity.type,
      language: entity.language,
      level: entity.level,
      topic: entity.topic,
      data: entity.data,
      status: entity.status,
      errorMessage: entity.errorMessage,
      generatedAt: entity.generatedAt,
      aiModel: entity.aiModel,
    );
  }

  /// JSON'dan Model yaratish (Cloud Function javobidan)
  ///
  /// ✅ FIX: Cloud Function ikki xil formatda javob berishi mumkin:
  ///
  /// FORMAT 1 (quiz_generate.ts): To'g'ridan-to'g'ri fields:
  ///   { "questions": [...], "totalPoints": 100, "language": "en", ... }
  ///
  /// FORMAT 2 (eski/boshqa): data ichida:
  ///   { "data": { "questions": [...] }, "type": "quiz", ... }
  factory GeneratedContentModel.fromJson(Map<String, dynamic> json) {
    // ✅ FIX: Firebase dan kelgan Map<Object?,Object?> ni Map<String,dynamic> ga o'tkazish
    final safeJson = _safeMap(json);
    final metadata = _safeMap(safeJson['metadata']);

    final Map<String, dynamic> contentData;
    final String contentType;

    if (safeJson.containsKey('data') && safeJson['data'] is Map) {
      contentData = _safeMap(safeJson['data'] as Map);
      contentType = safeJson['type'] as String? ?? _inferType(contentData);
    } else {
      contentType = safeJson['type'] as String? ?? _inferTypeFromRaw(safeJson);
      contentData = _extractContentData(safeJson, contentType);
    }

    return GeneratedContentModel(
      id: safeJson['id'] as String? ?? _generateTempId(),
      type: ContentType.fromString(contentType),
      language: safeJson['language'] as String? ??
          (metadata['language'] as String?) ??
          'en',
      level: safeJson['level'] as String? ??
          (metadata['level'] as String?) ??
          'A1',
      topic:
          safeJson['topic'] as String? ?? (metadata['topic'] as String?) ?? '',
      data: contentData,
      status: GenerationStatus.completed,
      errorMessage: null,
      generatedAt:
          _parseDateTime(metadata['generatedAt'] ?? safeJson['generatedAt']),
      aiModel: safeJson['aiModel'] as String? ??
          metadata['aiModel'] as String? ??
          'gemini',
    );
  }

  /// ✅ FIX: Firebase `Map<Object?,Object?>` → `Map<String,dynamic>` ga xavfsiz o'tkazish
  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    return Map<String, dynamic>.from(
      (value as Map).map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  /// Cloud Function raw javobidan content type ni aniqlash
  static String _inferTypeFromRaw(Map<String, dynamic> json) {
    if (json.containsKey('questions') && !json.containsKey('transcript'))
      return 'quiz';
    if (json.containsKey('transcript')) return 'listening';
    if (json.containsKey('cards') || json.containsKey('exercises'))
      return 'speaking';
    return 'quiz';
  }

  /// data field ichidan type aniqlash
  static String _inferType(Map<String, dynamic> data) {
    if (data.containsKey('questions') && !data.containsKey('transcript'))
      return 'quiz';
    if (data.containsKey('transcript')) return 'listening';
    return 'speaking';
  }

  /// Cloud Function raw javobini 'data' formatiga o'tkazish
  static Map<String, dynamic> _extractContentData(
      Map<String, dynamic> json, String type) {
    switch (type) {
      case 'quiz':
        // ✅ FIX: questions list ichidagi har bir element ham cast qilish kerak
        final rawQuestions = json['questions'] as List? ?? [];
        final questions = rawQuestions.map((q) => _safeMap(q)).toList();
        return {
          'questions': questions,
          'totalPoints': json['totalPoints'] ?? 0,
          'passingScore': json['passingScore'] ?? 0,
          'grammar': json['grammar'] ?? '',
          'isMock': false,
        };
      case 'listening':
        final rawQuestions = json['questions'] as List? ?? [];
        final questions = rawQuestions.map((q) => _safeMap(q)).toList();
        return {
          'title': json['title'] ?? '',
          'description': json['description'] ?? '',
          'transcript': json['transcript'] ?? '',
          'duration': json['audioDuration'] ?? json['duration'] ?? 0,
          'questions': questions,
          'scenario': json['scenario'] ?? '',
          'metadata': _safeMap(json['metadata']),
          'audioUrl': json['audioUrl'] ?? '',
          'isMock': false,
        };
      default:
        return _safeMap(json)
          ..remove('language')
          ..remove('level')
          ..remove('topic')
          ..remove('type')
          ..remove('id')
          ..remove('aiModel');
    }
  }

  /// Model'dan JSON yaratish (Firestore'ga saqlash uchun)
  ///
  /// Bu method Firestore'ga content document yaratishda ishlatiladi.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type.toFirestore(),
      'language': language,
      'level': level,
      'topic': topic,
      'data': data,
      'status': status.toFirestore(),
      'errorMessage': errorMessage,
      'generatedAt': generatedAt.toIso8601String(),
      'aiModel': aiModel,
      // Qo'shimcha metadata
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Firestore document'dan Model yaratish
  factory GeneratedContentModel.fromFirestore(Map<String, dynamic> doc) {
    return GeneratedContentModel(
      id: doc['id'] as String,
      type: ContentType.fromString(doc['type'] as String),
      language: doc['language'] as String,
      level: doc['level'] as String,
      topic: doc['topic'] as String,
      data: doc['data'] as Map<String, dynamic>,
      status: GenerationStatus.fromString(doc['status'] as String),
      errorMessage: doc['errorMessage'] as String?,
      generatedAt: _parseDateTime(doc['generatedAt']),
      aiModel: doc['aiModel'] as String? ?? 'unknown',
    );
  }

  /// Copy with (Model uchun)
  @override
  GeneratedContentModel copyWith({
    String? id,
    ContentType? type,
    String? language,
    String? level,
    String? topic,
    Map<String, dynamic>? data,
    GenerationStatus? status,
    String? errorMessage,
    DateTime? generatedAt,
    String? aiModel,
  }) {
    return GeneratedContentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      language: language ?? this.language,
      level: level ?? this.level,
      topic: topic ?? this.topic,
      data: data ?? this.data,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      generatedAt: generatedAt ?? this.generatedAt,
      aiModel: aiModel ?? this.aiModel,
    );
  }

  /// Error bilan Model yaratish
  factory GeneratedContentModel.withError({
    required String id,
    required ContentType type,
    required String language,
    required String level,
    required String topic,
    required String errorMessage,
  }) {
    return GeneratedContentModel(
      id: id,
      type: type,
      language: language,
      level: level,
      topic: topic,
      data: const {}, // Bo'sh data
      status: GenerationStatus.failed,
      errorMessage: errorMessage,
      generatedAt: DateTime.now(),
      aiModel: 'unknown',
    );
  }

  // ====== Helper methods ======

  /// Vaqtinchalik ID generatsiya qilish (UUID o'rniga)
  static String _generateTempId() {
    final now = DateTime.now();
    return 'temp_${now.millisecondsSinceEpoch}';
  }

  /// DateTime parsing (ISO 8601 string'dan)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
