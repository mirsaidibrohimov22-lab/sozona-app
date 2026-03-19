// lib/core/services/ai_motivation_service.dart
// So'zona — AI Motivation Coach Service
// ✅ YANGILANDI: Har kirganida boshqacha xabar
// ✅ YANGILANDI: Vaqtga qarab (tong/kun/kech/tun) moslashadi
// ✅ YANGILANDI: Foydalanuvchi ismi dinamik
// ✅ YANGILANDI: O'zbek/ingliz tillarida to'g'ri chiqadi
// ✅ YANGILANDI: Kuchli fallback xabarlar (har safar tasodifiy)

import 'dart:async';
import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════
// MOTIVATION EVENT TURLARI
// ═══════════════════════════════════════════════════════════════

enum MotivationTrigger {
  lessonCompleted,
  weakAreaDetected,
  streakRisk,
  userReturned,
  levelUp,
  milestone,
}

class MotivationResult {
  final String message;
  final MotivationTrigger trigger;
  final DateTime timestamp;
  final bool isAiGenerated;

  const MotivationResult({
    required this.message,
    required this.trigger,
    required this.timestamp,
    this.isAiGenerated = true,
  });
}

// ═══════════════════════════════════════════════════════════════
// AI MOTIVATION SERVICE
// ═══════════════════════════════════════════════════════════════

class AiMotivationService {
  final FirebaseFunctions _functions;
  final SharedPreferences _prefs;
  final _random = Random();

  static const Duration _minInterval = Duration(minutes: 10);
  static const String _lastShownKey = 'motivation_last_shown';
  static const String _lastTriggerKey = 'motivation_last_trigger';
  static const String _lastActiveKey = 'motivation_last_active';
  // ✅ YANGI: Oxirgi xabar indeksi — takrorlanmasin
  static const String _lastMessageIndexKey = 'motivation_last_msg_index';

  bool _isRequestInProgress = false;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 3;

  AiMotivationService({
    required FirebaseFunctions functions,
    required SharedPreferences prefs,
  })  : _functions = functions,
        _prefs = prefs;

  // ═══════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════

  Future<MotivationResult?> onLessonCompleted({
    required String studentName,
    required int score,
    required int streak,
    required String language,
  }) async {
    if (!_canShowMotivation(MotivationTrigger.lessonCompleted)) return null;
    return _requestMotivation(
      trigger: MotivationTrigger.lessonCompleted,
      studentName: studentName,
      streak: streak,
      score: score.toDouble(),
      language: language,
    );
  }

  Future<MotivationResult?> onWeakAreaDetected({
    required String studentName,
    required List<String> weakAreas,
    required String language,
  }) async {
    if (!_canShowMotivation(MotivationTrigger.weakAreaDetected)) return null;
    return _requestMotivation(
      trigger: MotivationTrigger.weakAreaDetected,
      studentName: studentName,
      streak: 0,
      score: 30,
      language: language,
    );
  }

  Future<MotivationResult?> onStreakRisk({
    required String studentName,
    required int currentStreak,
    required String language,
  }) async {
    if (!_canShowMotivation(MotivationTrigger.streakRisk)) return null;
    return _requestMotivation(
      trigger: MotivationTrigger.streakRisk,
      studentName: studentName,
      streak: currentStreak,
      score: 50,
      language: language,
    );
  }

  /// ✅ YANGILANDI: Har kirganida ko'rsatadi (2 kunlik cheklov o'chirildi)
  Future<MotivationResult?> onUserReturned({
    required String studentName,
    required String language,
  }) async {
    // Anti-spam: 10 daqiqada bir marta
    if (!_canShowMotivation(MotivationTrigger.userReturned)) return null;

    return _requestMotivation(
      trigger: MotivationTrigger.userReturned,
      studentName: studentName,
      streak: 0,
      score: 50,
      language: language,
    );
  }

  Future<MotivationResult?> onLevelUp({
    required String studentName,
    required String newLevel,
    required String language,
  }) async {
    return _requestMotivation(
      trigger: MotivationTrigger.levelUp,
      studentName: studentName,
      streak: 0,
      score: 90,
      language: language,
    );
  }

  Future<MotivationResult?> onMilestone({
    required String studentName,
    required String milestoneText,
    required String language,
  }) async {
    return _requestMotivation(
      trigger: MotivationTrigger.milestone,
      studentName: studentName,
      streak: 0,
      score: 80,
      language: language,
    );
  }

  void markActive() {
    _prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ═══════════════════════════════════════
  // PRIVATE
  // ═══════════════════════════════════════

  Future<MotivationResult?> _requestMotivation({
    required MotivationTrigger trigger,
    required String studentName,
    required int streak,
    required double score,
    required String language,
  }) async {
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      debugPrint('⚠️ Motivation: fallback ishlatiladi');
      _consecutiveErrors = 0;
      return _buildFallback(trigger, studentName, streak, language);
    }

    if (_isRequestInProgress) return null;
    _isRequestInProgress = true;

    try {
      final callable = _functions.httpsCallable(
        'getMotivationMessage',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );

      // ✅ YANGI: Vaqt va trigger konteksti yuboriladi
      final timeOfDay = _getTimeOfDay();

      final result = await callable.call({
        'studentName': studentName,
        'currentStreak': streak,
        'averageScore': score,
        'language': language == 'english' ? 'en' : 'uz',
        'context': _triggerToContext(trigger),
        'timeOfDay': timeOfDay,
      });

      final data = result.data as Map<String, dynamic>;
      final message = data['message'] as String? ?? '';

      if (message.isEmpty || message.length < 10) {
        throw Exception('Bo\'sh javob');
      }

      _consecutiveErrors = 0;
      _markShown(trigger);

      return MotivationResult(
        message: message,
        trigger: trigger,
        timestamp: DateTime.now(),
        isAiGenerated: true,
      );
    } catch (e) {
      debugPrint('⚠️ Motivation AI xatosi: $e');
      _consecutiveErrors++;
      return _buildFallback(trigger, studentName, streak, language);
    } finally {
      _isRequestInProgress = false;
    }
  }

  String _triggerToContext(MotivationTrigger trigger) {
    switch (trigger) {
      case MotivationTrigger.lessonCompleted:
        return 'good_streak';
      case MotivationTrigger.weakAreaDetected:
        return 'low_performance';
      case MotivationTrigger.streakRisk:
        return 'streak_risk';
      case MotivationTrigger.userReturned:
        return 'user_returned';
      case MotivationTrigger.levelUp:
        return 'level_up';
      case MotivationTrigger.milestone:
        return 'milestone';
    }
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }

  String _getGreeting(bool isUz) {
    final tod = _getTimeOfDay();
    if (isUz) {
      switch (tod) {
        case 'morning':
          return 'Xayrli tong';
        case 'afternoon':
          return 'Xayrli kun';
        case 'evening':
          return 'Xayrli kech';
        default:
          return 'Xayrli tun';
      }
    } else {
      switch (tod) {
        case 'morning':
          return 'Good morning';
        case 'afternoon':
          return 'Good afternoon';
        case 'evening':
          return 'Good evening';
        default:
          return 'Good night';
      }
    }
  }

  bool _canShowMotivation(MotivationTrigger trigger) {
    final lastShown = _prefs.getInt(_lastShownKey);
    if (lastShown != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastShown;
      if (elapsed < _minInterval.inMilliseconds) {
        debugPrint('⏱️ Motivation: interval kutilmoqda (${elapsed ~/ 1000}s)');
        return false;
      }
    }

    final lastTrigger = _prefs.getString(_lastTriggerKey);
    if (lastTrigger == trigger.name) {
      final lastShownMs = _prefs.getInt(_lastShownKey) ?? 0;
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastShownMs;
      if (elapsed < const Duration(minutes: 30).inMilliseconds) {
        return false;
      }
    }

    return true;
  }

  void _markShown(MotivationTrigger trigger) {
    _prefs.setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
    _prefs.setString(_lastTriggerKey, trigger.name);
  }

  // ✅ YANGILANDI: Har safar tasodifiy, kuchli fallback
  MotivationResult _buildFallback(
    MotivationTrigger trigger,
    String name,
    int streak,
    String language,
  ) {
    final isUz = language != 'english';
    final g = _getGreeting(isUz);

    final messagesUz = <MotivationTrigger, List<String>>{
      MotivationTrigger.userReturned: [
        '$g, $name! 🌟 Seni bu yerda ko\'rib turganimizdan bag\'oyat xursandmiz. Har bir kun o\'rganish uchun yangi imkoniyat — bugun ham katta qadam tashlaysan!',
        '$g, $name! ☀️ Ilovaga kirganingdan quvonamiz! Sen til o\'rganish yo\'lida eng muhim narsani qilding — BOSHLADІNG. Davom et, g\'alaba yaqin!',
        '$g, $name! 💫 Biz seni doim kutib turamiz. Bugun ozgina bo\'lsa ham mashq qilsang, bir yildan keyin sen boshqa odam bo\'lasan. Ishlaymizmi?',
        '$g, $name! 🚀 Ko\'p odam boshlaydi, lekin davom ettirish — bu g\'oliblar ishi. Sen o\'sha g\'oliblardan birisan. Bugun ham birlashib ketamizmi?',
        '$g, $name! 🏆 Seni yana ko\'rib turganimizdan xursandmiz! Bugun bir so\'z o\'rgansang ham, kecha sen bo\'lgan kishidan yaxshiroqsan. Boshlaylikmi?',
      ],
      MotivationTrigger.weakAreaDetected: [
        '$g, $name! 💪 Qiyinchilik — bu o\'sishning belgisi! Har bir xato miyangni kuchaytiradi. Yana bir bor urinib ko\'ramizmi?',
        '$g, $name! 🌱 Hech kim birinchi urinishda mukammal bo\'lmagan. Davom et — muvaffaqiyat yaqin!',
        '$g, $name! ⭐ Qiyinchilik seni to\'xtatib qo\'ymaydi — u seni kuchaytiradi. Bugun bir oz ko\'proq mashq qilsang, ertaga boshqacha bo\'lasan!',
      ],
      MotivationTrigger.streakRisk: [
        '$g, $name! ⚡ ${streak > 0 ? "$streak kunlik streaking" : "Yangi streaking"} xavfda! Faqat 5 daqiqa — bugungi mashqni tugatib, rekordingni saqlab qol!',
        '$g, $name! 🔥 Bugun hali mashq qilinmadi. Streakni yo\'qotma — 10 daqiqalik flashcard yetarli. Hoziroq boshlasak bo\'ladimi?',
        '$g, $name! ⏰ Kun tugayapti — streakingni unutma! Kichik qadam ham katta farq qiladi. Hozir 5 daqiqa ajrat!',
      ],
      MotivationTrigger.lessonCompleted: [
        '$g, $name! 🎉 Ajoyib ish! Har bir mashq seni maqsadga yaqinlashtiradi. Sen juda yaxshi ishlayapsan!',
        '$g, $name! 💪 Zo\'r natija! Bugun ham bir qadam oldinga siljidingiz. Davom eting — g\'alaba yaqin!',
        '$g, $name! 🌟 Mashqni tugatdingiz! Bu kichik g\'alaba emas — bu ulkan jasorat. Ertaga yanada kuchliroq bo\'lasiz!',
      ],
      MotivationTrigger.levelUp: [
        '$g, $name! 🎉🚀 Tabriklaymiz! Yangi darajaga chiqdingiz — bu sizning mehnatingizning mevasi!',
        '$g, $name! 🏆 LEVEL UP! Bu sening o\'sishingning isboti. Oldingda yangi dunyo ochildi — davom et!',
      ],
      MotivationTrigger.milestone: [
        '$g, $name! 🌟🎊 Tabriklaymiz! Bu yutuq — katta mehnatning natijasi. Sen ajoyib ish qildingiz!',
      ],
    };

    final messagesEn = <MotivationTrigger, List<String>>{
      MotivationTrigger.userReturned: [
        '$g, $name! 🌟 We\'re so happy to see you here! Every day is a new opportunity to learn — take a big step today!',
        '$g, $name! ☀️ Welcome back! You did the most important thing — you STARTED. Keep going, success is near!',
        '$g, $name! 💫 We always wait for you. Even a little practice today will make you a different person in a year. Ready?',
        '$g, $name! 🚀 Many people start, but continuing is what champions do. You\'re one of those champions. Let\'s go!',
        '$g, $name! 🏆 So glad to see you again! Even one word learned today makes you better than yesterday. Shall we begin?',
      ],
      MotivationTrigger.weakAreaDetected: [
        '$g, $name! 💪 Challenges are a sign of growth! Every mistake strengthens your brain. Shall we try again?',
        '$g, $name! 🌱 Nobody was perfect on the first try. Keep going — success is near!',
        '$g, $name! ⭐ Difficulties don\'t stop you — they make you stronger. A little more practice today means a better you tomorrow!',
      ],
      MotivationTrigger.streakRisk: [
        '$g, $name! ⚡ Your ${streak > 0 ? "$streak-day streak" : "streak"} is at risk! Just 5 minutes — finish today\'s practice and keep your record!',
        '$g, $name! 🔥 No practice yet today. Don\'t lose your streak — a 10-minute flashcard is enough. Start now?',
        '$g, $name! ⏰ The day is ending — don\'t forget your streak! A small step makes a big difference. Spare 5 minutes now!',
      ],
      MotivationTrigger.lessonCompleted: [
        '$g, $name! 🎉 Great job! Every practice brings you closer to your goal. You\'re doing amazingly well!',
        '$g, $name! 💪 Excellent result! You moved one step forward today. Keep going — victory is near!',
        '$g, $name! 🌟 You completed the lesson! This isn\'t a small win — it\'s a huge achievement. You\'ll be even stronger tomorrow!',
      ],
      MotivationTrigger.levelUp: [
        '$g, $name! 🎉🚀 Congratulations! You\'ve reached a new level — this is the fruit of your hard work!',
        '$g, $name! 🏆 LEVEL UP! This is proof of your growth. A new world has opened before you — keep going!',
      ],
      MotivationTrigger.milestone: [
        '$g, $name! 🌟🎊 Congratulations! This achievement is the result of great effort. You did an amazing job!',
      ],
    };

    final pool = isUz
        ? (messagesUz[trigger] ?? messagesUz[MotivationTrigger.userReturned]!)
        : (messagesEn[trigger] ?? messagesEn[MotivationTrigger.userReturned]!);

    // ✅ Tasodifiy tanlash — oldingi indeksdan farqli
    final lastIdx = _prefs.getInt(_lastMessageIndexKey) ?? -1;
    int idx;
    if (pool.length > 1) {
      do {
        idx = _random.nextInt(pool.length);
      } while (idx == lastIdx);
    } else {
      idx = 0;
    }
    _prefs.setInt(_lastMessageIndexKey, idx);

    _markShown(trigger);

    return MotivationResult(
      message: pool[idx],
      trigger: trigger,
      timestamp: DateTime.now(),
      isAiGenerated: false,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RIVERPOD PROVIDER
// ═══════════════════════════════════════════════════════════════

final aiMotivationServiceProvider = Provider<AiMotivationService>((ref) {
  final functions = ref.watch(firebaseFunctionsProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AiMotivationService(functions: functions, prefs: prefs);
});

final homeMotivationProvider =
    FutureProvider.autoDispose<MotivationResult?>((ref) async {
  final service = ref.watch(aiMotivationServiceProvider);
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;

  if (user == null) return null;

  service.markActive();

  // Har kirganida xabar ko'rsatish
  final returnResult = await service.onUserReturned(
    studentName: user.displayName,
    language: user.learningLanguage.name,
  );
  if (returnResult != null) return returnResult;

  // Streak risk (kechqurun)
  final hour = DateTime.now().hour;
  if (hour >= 18) {
    final streakResult = await service.onStreakRisk(
      studentName: user.displayName,
      currentStreak: 0,
      language: user.learningLanguage.name,
    );
    if (streakResult != null) return streakResult;
  }

  return null;
});
