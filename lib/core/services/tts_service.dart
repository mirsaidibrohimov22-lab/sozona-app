// lib/core/services/tts_service.dart
// So'zona — TTS servisi (flutter_tts offline)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:my_first_app/core/services/logger_service.dart';

class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isSpeaking = false;

  static bool get isSpeaking => _isSpeaking;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        LoggerService.warning('TTS xatoligi: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      LoggerService.error('TTS init xatoligi', error: e);
    }
  }

  static Future<void> speak(String text, {String language = 'en-US'}) async {
    if (!_isInitialized) await init();
    try {
      await _tts.setLanguage(language);
      await _tts.speak(text);
    } catch (e) {
      LoggerService.error('TTS speak xatoligi', error: e);
    }
  }

  static Future<void> speakGerman(String text) async {
    await speak(text, language: 'de-DE');
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      LoggerService.error('TTS stop xatoligi', error: e);
    }
  }

  static Future<void> speakSlow(String text, {String language = 'en-US'}) async {
    if (!_isInitialized) await init();
    try {
      await _tts.setSpeechRate(0.3);
      await speak(text, language: language);
      await _tts.setSpeechRate(0.5);
    } catch (e) {
      LoggerService.error('TTS speakSlow xatoligi', error: e);
    }
  }

  static Future<void> dispose() async {
    await _tts.stop();
  }
}

// Riverpod provider
class TtsServiceWrapper {
  Future<void> speak(String text, {String language = 'en-US'}) =>
      TtsService.speak(text, language: language);
  Future<void> stop() => TtsService.stop();
}

final ttsServiceProvider = Provider<TtsServiceWrapper>((ref) {
  return TtsServiceWrapper();
});
