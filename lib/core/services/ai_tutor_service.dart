// lib/core/services/ai_tutor_service.dart
// So'zona — AI Murabbiy Service (datasource lar uchun)
// Singleton — faqat xato yozish va tavsiya olish uchun
// AiTutorNotifier dan farqli: bu state saqlamaydi, keraksiz call qilmaydi

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:my_first_app/core/constants/api_endpoints.dart';

class AiTutorService {
  AiTutorService._();
  static final instance = AiTutorService._();

  final FirebaseFunctions _fn =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Xato yozish — quiz/listening/speaking tugaganda chaqiriladi
  /// contentId: Firestore content/ kolleksiyasidagi hujjat ID si
  /// scorePercent: 0–100
  Future<void> recordMistake({
    required String userId,
    required String contentId,
    required String contentType, // 'quiz' | 'listening' | 'speaking'
    String userAnswer = '',
    String correctAnswer = '',
    required double scorePercent,
    String language = 'en', // backend content/ dan oladi — faqat fallback
  }) async {
    if (userId.isEmpty || contentId.isEmpty) return;
    // Faqat ball past bo'lsagina xato yozamiz
    if (scorePercent >= 80) return;

    try {
      await _fn.httpsCallable(ApiEndpoints.recordMistake).call({
        'contentId': contentId,
        'contentType': contentType,
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
        'scorePercent': scorePercent,
        'language': language,
      });
    } catch (e) {
      // Xato yozish muvaffaqiyatsiz bo'lsa — asosiy oqim to'xtamasin
      debugPrint('⚠️ AiTutorService.recordMistake: $e');
    }
  }
}
