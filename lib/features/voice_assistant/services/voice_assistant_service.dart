// lib/features/voice_assistant/services/voice_assistant_service.dart
// ✅ v6 — Professional yechim
//
// O'zgartirishlar:
//   - Wake word STT OLIB TASHLANDI (beep yo'q, loop yo'q, battery tejaldi)
//   - Faqat tugma orqali aktivlashtirish
//   - STT faqat user gapirayotganda ishlatiladi
//   - Fonda ishlash — foreground notification tugmasi orqali
//   - Barcha xatolar xavfsiz ushlangan

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
// ✅ FIX: import lar deklaratsiyadan oldin bo'lishi shart
import 'package:my_first_app/features/voice_assistant/providers/voice_assistant_settings_provider.dart';
import 'package:my_first_app/features/voice_assistant/services/voice_foreground_task.dart';

// ✅ unawaited helper
void unawaited(Future<void> future) {
  future.ignore();
}

enum VoiceAssistantState {
  inactive, // Ilova ishlamayapti
  listening, // Fonda — tugma kutmoqda (beep yo'q!)
  activated, // AI javob tayyorlamoqda
  speaking, // AI gapirmoqda
  waitingInput, // User gapirishini kutmoqda
  keyMissing, // Eski kod bilan moslik uchun (ishlatilmaydi)
}

class VoiceAssistantService extends ChangeNotifier {
  final String userName;
  final bool isPremium;
  final SozanaVoice voice;
  final bool backgroundEnabled;

  final SpeechToText _stt = SpeechToText();
  final AudioPlayer _player = AudioPlayer();
  final Dio _dio =
      Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
  final Random _rng = Random();
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  VoiceAssistantState _state = VoiceAssistantState.inactive;
  String _displayText = '';
  bool _sttReady = false;
  String? _sttLocale;

  bool _conversationActive = false;
  final List<Map<String, String>> _history = [];
  int _turnCount = 0;
  int _silentTurns = 0;
  String? _weatherCtx;
  String? _tempAudioPath;

  bool _disposed = false;

  VoiceAssistantState get state => _state;
  String get displayText => _displayText;
  bool get hasKey => true;

  VoiceAssistantService({
    required this.userName,
    required this.isPremium,
    required this.voice,
    required this.backgroundEnabled,
  });

  // ══════════════════════════════════════════════════
  // INIT — faqat STT tayyor qiladi, hech narsani tinglmaydi
  // ══════════════════════════════════════════════════
  Future<void> initialize() async {
    if (!isPremium) {
      _set(VoiceAssistantState.inactive, text: '');
      return;
    }

    _sttReady = await _stt.initialize(
      onError: _onSttError,
      onStatus: _onSttStatus,
    );

    if (!_sttReady) {
      _set(VoiceAssistantState.inactive, text: 'Mikrofon ruxsati yo\'q.');
      return;
    }

    await _resolveLocale();

    final dir = await getTemporaryDirectory();
    _tempAudioPath = '${dir.path}/sozana_tts.mp3';

    if (backgroundEnabled) {
      VoiceForegroundService.init();
      await VoiceForegroundService.start();
    }

    // ✅ Wake word yo'q — faqat tayyor holatga o'tamiz
    _set(VoiceAssistantState.listening, text: 'Tugmani bosib gaplashing');

    if (backgroundEnabled) {
      VoiceForegroundService.updateNotification('Tugmani bosib gaplashing');
    }
  }

  // ── Locale ──────────────────────────────────────
  Future<void> _resolveLocale() async {
    try {
      final locales = await _stt.locales();
      final ids = locales.map((l) => l.localeId).toList();
      if (ids.any((l) => l.startsWith('uz'))) {
        _sttLocale = 'uz_UZ';
      } else if (ids.any((l) => l.startsWith('ru'))) {
        _sttLocale = 'ru_RU';
      } else {
        _sttLocale = ids.isNotEmpty ? ids.first : 'ru_RU';
      }
    } catch (_) {
      _sttLocale = 'ru_RU';
    }
  }

  // ══════════════════════════════════════════════════
  // STT CALLBACKS — faqat suhbat davomida ishlaydi
  // ══════════════════════════════════════════════════
  void _onSttError(dynamic e) {
    final msg = e.toString();
    debugPrint('STT xato: $e');

    if (!_conversationActive) return;

    // ✅ Network xatosi — qayta urinish befoyda, xavfsiz tugatish
    if (msg.contains('error_network') ||
        msg.contains('error_client') ||
        msg.contains('error_server')) {
      _speak("Internet muammo bor. Keyinroq urinib ko'ring.")
          .then((_) => _endConversation());
      return;
    }

    // Boshqa xatolar — faqat bir marta qayta urinish
    if (_state == VoiceAssistantState.waitingInput) {
      _silentTurns++;
      if (_silentTurns >= 2) {
        _speak('Eshitolmadim. Tugmani qayta bosing.')
            .then((_) => _endConversation());
      } else {
        _listenUser();
      }
    }
  }

  void _onSttStatus(String status) {
    debugPrint('STT holat: $status');
  }

  // ══════════════════════════════════════════════════
  // TUGMA BOSILDI — suhbatni boshlash
  // ✅ FIX: @override olib tashlandi — ChangeNotifier da bu metod yo'q
  // ══════════════════════════════════════════════════
  Future<void> triggerManually() async {
    if (!isPremium || !_sttReady) return;
    if (_conversationActive) return;

    _conversationActive = true;
    _history.clear();
    _turnCount = 0;
    _silentTurns = 0;

    if (backgroundEnabled) {
      VoiceForegroundService.updateNotification('Gaplashmoqda...');
    }

    _weatherCtx ??= await _fetchWeatherContext();

    // ✅ Birinchi marta kirgan user — qanday ishlashini tushuntiradi
    final isFirstTime = await _checkFirstTime();
    if (isFirstTime) {
      await _speak(
        'Salom! Men So\'zona, sizning shaxsiy ingliz tili o\'qituvchingizman. '
        'Istalgan savolingizni bering. '
        'Gapirib bo\'lgach "javob ber" deng — men darhol javob beraman. '
        'Xayrlashtirmoqchi bo\'lsangiz "xayr" deng. Boshlaylik!',
      );
    } else {
      await _speak(_timeGreeting());
    }

    if (_conversationActive) _listenUser();
  }

  Future<bool> _checkFirstTime() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final used = doc.data()?['voiceAssistantUsed'] as bool? ?? false;
      if (!used) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'voiceAssistantUsed': true});
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    final n = userName.isNotEmpty ? userName : "do'stim";
    if (h < 6) return "Voy, $n, bu vaqtda uyg'oqmisiz? Tinglayapman!";
    if (h < 12) return 'Xayrli tong, $n! Nima desangiz ayting.';
    if (h < 17) return 'Salom, $n! Ishlaringiz qanday? Tinglayapman.';
    if (h < 21) return 'Xayrli kech, $n! Yordamga tayyorman.';
    return 'Salom, $n! Tinglayapman.';
  }

  // ══════════════════════════════════════════════════
  // USER TINGLASH — faqat suhbat davomida
  // ══════════════════════════════════════════════════
  void _listenUser() {
    if (!_sttReady || !_conversationActive || _disposed) return;
    _set(VoiceAssistantState.waitingInput, text: 'Gapiring...');

    bool gotResult = false;
    String accumulated = '';

    _stt.listen(
      onResult: (r) async {
        if (gotResult) return;

        final words = r.recognizedWords.trim();
        if (words.isNotEmpty) accumulated = words;

        // ✅ "javob ber" kalit so'zi — darhol yuboradi
        final lower = words.toLowerCase();
        final hasSubmitWord = lower.endsWith('javob ber') ||
            lower.endsWith('yuborilsin') ||
            lower.endsWith("shu bo'ldi") ||
            lower.endsWith('tayyor');

        if (hasSubmitWord || r.finalResult) {
          final text = accumulated
              .replaceAll(RegExp(r'javob ber$', caseSensitive: false), '')
              .replaceAll(RegExp(r'yuborilsin$', caseSensitive: false), '')
              .replaceAll(RegExp(r'tayyor$', caseSensitive: false), '')
              .trim();

          if (text.isNotEmpty) {
            gotResult = true;
            _silentTurns = 0;
            await _stt.cancel();
            await _onUserInput(text);
          }
        }
      },
      localeId: _sttLocale ?? 'ru_RU',
      listenFor: const Duration(seconds: 120),
      pauseFor: const Duration(seconds: 25),
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        partialResults: true, // ✅ "javob ber" aniqlash uchun kerak
      ),
    );

    // 65 sekundda natija yo'q — jim qolgan
    Future.delayed(const Duration(seconds: 65), () async {
      if (!gotResult &&
          _conversationActive &&
          _state == VoiceAssistantState.waitingInput &&
          !_disposed) {
        await _stt.cancel();
        _silentTurns++;
        if (_silentTurns >= 2) {
          await _speak("Yaxshi, yana kerak bo'lsa tugmani bosing. Xayr!");
          _endConversation();
        } else {
          await _speak('Eshitolmadim, qayta gapiring.');
          _listenUser();
        }
      }
    });
  }

  // ══════════════════════════════════════════════════
  // USER GAPIRDI
  // ══════════════════════════════════════════════════
  Future<void> _onUserInput(String input) async {
    if (_disposed) return;
    _set(VoiceAssistantState.activated, text: '...');
    _turnCount++;

    if (_isGoodbye(input.toLowerCase())) {
      await _speak(_goodbyeText());
      _endConversation();
      return;
    }

    _history.add({'role': 'user', 'content': input});
    final reply = await _gptChat();
    if (_disposed) return;
    _history.add({'role': 'assistant', 'content': reply});
    if (_history.length > 14) _history.removeRange(0, 2);

    if (_turnCount >= 8) {
      await _speak("$reply Yana gaplashmoqchi bo'lsangiz tugmani bosing!");
      _endConversation();
      return;
    }

    await _speak(reply);
    if (_conversationActive && !_disposed) _listenUser();
  }

  // ══════════════════════════════════════════════════
  // GPT — Cloud Function orqali
  // ══════════════════════════════════════════════════
  Future<String> _gptChat() async {
    try {
      final callable = _functions.httpsCallable(
        'voiceChat',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call({
        'messages': _history,
        'userName': userName.isNotEmpty ? userName : "Do'stim",
        if (_weatherCtx != null) 'weatherCtx': _weatherCtx,
      });
      final data = result.data as Map<String, dynamic>;
      return (data['reply'] as String? ?? '').trim();
    } catch (e) {
      debugPrint('voiceChat xato: $e');
      return _randomErrorMsg();
    }
  }

  // ══════════════════════════════════════════════════
  // TTS — generateSpeech Cloud Function orqali
  // ══════════════════════════════════════════════════
  Future<void> _speak(String text) async {
    if (text.trim().isEmpty || _disposed) return;
    // ✅ STT va state o'zgartirish parallel — kechikish yo'q
    unawaited(_stt.cancel());
    _set(VoiceAssistantState.speaking, text: text);

    if (backgroundEnabled) {
      VoiceForegroundService.updateNotification('Gapirmoqda...');
    }

    try {
      final callable = _functions.httpsCallable(
        'generateSpeech',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );
      final result = await callable.call({
        'text': text,
        'voice': voice.openAiId,
        'speed': 0.95,
      });

      if (_disposed) return;

      final data = result.data as Map<String, dynamic>;
      final base64Audio = data['audio'] as String? ?? '';
      if (base64Audio.isEmpty) return;

      final bytes = base64Decode(base64Audio);
      final filePath = _tempAudioPath ??
          '${(await getTemporaryDirectory()).path}/sozana_tts.mp3';
      await File(filePath).writeAsBytes(bytes, flush: true);

      if (_disposed) return;

      await _player.stop();
      await _player.setFilePath(filePath);

      final completer = Completer<void>();
      late StreamSubscription sub;
      sub = _player.playerStateStream.listen((ps) {
        if (ps.processingState == ProcessingState.completed) {
          sub.cancel();
          if (!completer.isCompleted) completer.complete();
        }
      });

      await _player.play();
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {},
      );
    } catch (e) {
      debugPrint('generateSpeech xato: $e');
    }
  }

  // ══════════════════════════════════════════════════
  // OB-HAVO
  // ══════════════════════════════════════════════════
  Future<String?> _fetchWeatherContext() async {
    try {
      final city = await _getUserCity();
      final r = await _dio.get(
        'https://wttr.in/${Uri.encodeComponent(city)}?format=j1',
        options: Options(
          headers: {'Accept': 'application/json'},
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final t =
          double.parse(r.data['current_condition'][0]['temp_C'].toString());
      return 'Ob-havo ($city): ${t.round()} daraja.';
    } catch (_) {
      return null;
    }
  }

  Future<String> _getUserCity() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 'Toshkent';
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final city = doc.data()?['city'] as String?;
      return (city != null && city.trim().isNotEmpty)
          ? city.trim()
          : 'Toshkent';
    } catch (_) {
      return 'Toshkent';
    }
  }

  // ══════════════════════════════════════════════════
  // XAYRLASHUV
  // ══════════════════════════════════════════════════
  bool _isGoodbye(String t) {
    final words = [
      'xayr',
      "ko'rishguncha",
      "shu bo'ldi",
      'endi yotaman',
      'yaxshi qoling',
      "omad bo'lsin",
      'gaplashib oldik',
      'ketdim',
      "bo'ldi",
    ];
    return words.any((w) => t.contains(w));
  }

  String _goodbyeText() {
    final n = userName.isNotEmpty ? userName : "do'stim";
    return [
      "Xayr, $n! O'qishni davom eting, siz zo'rsiz!",
      "Ko'rishguncha! Yana tugmani bossangiz — doim shu yerdaman.",
      'Maroqli kun tilayman, $n! Xayr!',
      "Xayr! Ingliz tilini o'rganing, dunyo sizga ochiladi!",
    ][_rng.nextInt(4)];
  }

  String _randomErrorMsg() => [
        'Kechirasiz, internet aloqasi zaif.',
        "Hmm, hozir javob ololmayapman. Qayta urinib ko'ring.",
        "Voy, nimadir noto'g'ri ketdi. Yana so'rang.",
      ][_rng.nextInt(3)];

  // ══════════════════════════════════════════════════
  // SUHBATNI YAKUNLASH
  // ══════════════════════════════════════════════════
  void _endConversation() {
    _conversationActive = false;
    _history.clear();
    _turnCount = 0;
    _silentTurns = 0;
    if (!_disposed) {
      _set(VoiceAssistantState.listening, text: 'Tugmani bosib gaplashing');
    }
    if (backgroundEnabled) {
      VoiceForegroundService.updateNotification('Tugmani bosib gaplashing');
    }
  }

  // ══════════════════════════════════════════════════
  // PUBLIC METODLAR
  // ══════════════════════════════════════════════════
  Future<void> stop() async {
    await _stt.cancel();
    await _player.stop();
    _endConversation();
  }

  void _set(VoiceAssistantState s, {String? text}) {
    if (_disposed) return;
    _state = s;
    if (text != null) _displayText = text;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stt.cancel();
    _player.dispose();
    if (_tempAudioPath != null) {
      try {
        File(_tempAudioPath!).deleteSync();
      } catch (_) {}
    }
    super.dispose();
  }
}
