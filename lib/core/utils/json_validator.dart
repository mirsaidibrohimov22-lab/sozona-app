// lib/core/utils/json_validator.dart
// ✅ FIX: isValidQuizResponse() — 'title' EMAS, 'questions' tekshirilsin
//    ESKI: json.containsKey('title') → Cloud Function hech qachon 'title' bermaydi
//    YANGI: json.containsKey('questions') → AI response bilan 100% mos
// ✅ FIX: isValidListening() — 'audioUrl' shart emas (TTS ishlatiladi)

class JsonValidator {
  static bool isValidQuiz(Map<String, dynamic> json) {
    // Firestore da saqlangan quiz uchun (title mavjud bo'ladi)
    return json.containsKey('title') &&
        json.containsKey('questions') &&
        json['questions'] is List &&
        (json['questions'] as List).isNotEmpty;
  }

  static bool isValidFlashcardSet(Map<String, dynamic> json) {
    return json.containsKey('title') &&
        json.containsKey('cards') &&
        json['cards'] is List &&
        (json['cards'] as List).isNotEmpty;
  }

  static bool isValidListening(Map<String, dynamic> json) {
    // ✅ FIX: audioUrl shart emas — TTS ishlatilishi mumkin
    return json.containsKey('questions') && json['questions'] is List;
  }

  static T? safeGet<T>(Map<String, dynamic> json, String key) {
    try {
      final val = json[key];
      if (val is T) return val;
      return null;
    } catch (_) {
      return null;
    }
  }

  static double safeDouble(
    Map<String, dynamic> json,
    String key, [
    double defaultValue = 0.0,
  ]) {
    final val = json[key];
    if (val == null) return defaultValue;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  static int safeInt(
    Map<String, dynamic> json,
    String key, [
    int defaultValue = 0,
  ]) {
    final val = json[key];
    if (val == null) return defaultValue;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  /// ✅ FIX: AI Quiz response validatsiyasi
  ///
  /// Cloud Function generateQuiz qaytaradi:
  ///   { "questions": [...], "totalPoints": ..., "passingScore": ..., "metadata": {...} }
  ///
  /// 'title' YO'Q — shuning uchun isValidQuiz() bilan tekshirish NOTO'G'RI edi.
  /// Bu metod faqat AI response uchun — 'questions' bormi tekshiradi.
  static bool isValidQuizResponse(Map<String, dynamic> json) {
    return json.containsKey('questions') &&
        json['questions'] is List &&
        (json['questions'] as List).isNotEmpty;
  }

  /// AI Flashcard response validatsiyasi
  static bool isValidFlashcardResponse(Map<String, dynamic> json) {
    return json.containsKey('cards') &&
        json['cards'] is List &&
        (json['cards'] as List).isNotEmpty;
  }

  /// AI Listening response validatsiyasi
  static bool isValidListeningResponse(Map<String, dynamic> json) {
    return json.containsKey('transcript') &&
        json.containsKey('questions') &&
        json['questions'] is List &&
        (json['questions'] as List).isNotEmpty;
  }
}
