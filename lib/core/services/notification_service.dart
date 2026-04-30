// lib/core/services/notification_service.dart
// So'zona — Push notification servisi (FCM)
// ✅ flutter_local_notifications 17.2.4
// ✅ FIX: flutter_timezone olib tashlandi — Asia/Tashkent hardcode qilindi

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:my_first_app/core/router/app_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/services/logger_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  LoggerService.info('Background xabar: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // ✅ FIX: flutter_timezone o'rniga Asia/Tashkent hardcode
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _setupLocalNotifications();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    LoggerService.info('Notification ruxsati: ${settings.authorizationStatus}');

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    await scheduleDailyReminders();
  }

  // ── Local notifications setup ──────────────────────────────
  static Future<void> _setupLocalNotifications() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'teacher_content',
        'O\'qituvchi kontentlari',
        description: 'O\'qituvchi yuborgan mashqlar haqida bildirishnomalar',
        importance: Importance.high,
      );

      const AndroidNotificationChannel reminderChannel =
          AndroidNotificationChannel(
        'daily_reminder',
        'Kunlik eslatmalar',
        description: 'Har kuni mashq qilish uchun eslatmalar',
        importance: Importance.defaultImportance,
      );

      // ✅ YANGI: streak va leaderboard uchun kanallar
      const AndroidNotificationChannel streakChannel =
          AndroidNotificationChannel(
        'streak_channel',
        'Streak va yutuqlar',
        description:
            'Streak milestones, mukofotlar va leaderboard o\'zgarishlari',
        importance: Importance.high,
      );

      const AndroidNotificationChannel leaderboardChannel =
          AndroidNotificationChannel(
        'leaderboard_channel',
        'Leaderboard',
        description: 'IELTS kampaniyasi reytingi bildirishnomalari',
        importance: Importance.high,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation();
      await androidPlugin?.createNotificationChannel(channel);
      await androidPlugin?.createNotificationChannel(reminderChannel);
      await androidPlugin?.createNotificationChannel(streakChannel);
      await androidPlugin?.createNotificationChannel(leaderboardChannel);
    } catch (e) {
      debugPrint('⚠️ Local notifications setup xatosi: $e');
    }
  }

  // ── Foreground xabarni ko'rsatish ──────────────────────────
  static void _handleForegroundMessage(RemoteMessage message) {
    LoggerService.info('Foreground xabar: ${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;
    final type = message.data['type'] as String? ?? '';

    if (notification != null) {
      // type ga qarab to'g'ri channel tanlash
      final channelId = _channelIdForType(type);
      final channelName = _channelNameForType(type);

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: type,
      );
    }
  }

  static String _channelIdForType(String type) {
    switch (type) {
      case 'streak_milestone':
      case 'achievement':
        return 'streak_channel';
      case 'leaderboard_top3':
      case 'leaderboard_overtaken':
      case 'leaderboard_winner':
        return 'leaderboard_channel';
      case 'streak':
        return 'streak_channel';
      default:
        return 'teacher_content';
    }
  }

  static String _channelNameForType(String type) {
    switch (type) {
      case 'streak_milestone':
      case 'achievement':
      case 'streak':
        return 'Streak va yutuqlar';
      case 'leaderboard_top3':
      case 'leaderboard_overtaken':
      case 'leaderboard_winner':
        return 'Leaderboard';
      default:
        return 'O\'qituvchi kontentlari';
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    LoggerService.info('Xabardan ochildi: ${message.data}');
    final type = message.data['type'] as String? ?? '';
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'streak_milestone':
      case 'achievement':
      case 'streak':
        // Progress ekraniga yo'naltirish
        GoRouter.of(context).push(RoutePaths.progress);
        break;
      case 'leaderboard_top3':
      case 'leaderboard_overtaken':
      case 'leaderboard_winner':
        GoRouter.of(context).push(RoutePaths.leaderboard);
        break;
      case 'premium_activated':
        GoRouter.of(context).push(RoutePaths.premium);
        break;
      default:
        break;
    }
  }

  // ── FCM Token ───────────────────────────────────────────────
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      LoggerService.error('FCM token xatoligi', error: e);
      return null;
    }
  }

  static void listenTokenRefresh(Function(String) onRefresh) {
    _messaging.onTokenRefresh.listen(onRefresh);
  }

  static Future<void> saveTokenToFirestore(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      });
      debugPrint('✅ FCM token Firestore ga saqlandi');
    } catch (e) {
      debugPrint('⚠️ FCM token saqlash xatolik: $e');
    }
  }

  static Future<void> refreshAndSaveToken() async {
    try {
      final token = await getToken();
      if (token != null) await saveTokenToFirestore(token);
    } catch (e) {
      debugPrint('⚠️ Token refresh xatolik: $e');
    }
  }

  // ── Notification bosilganda navigatsiya ────────────────────
  static void _onNotificationTap(NotificationResponse response) {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final payload = response.payload ?? '';

      // Kunlik eslatmalar (id ga ko'ra)
      if (response.id == 1001 || response.id == 1002 || response.id == 1003) {
        GoRouter.of(context).push(
          RoutePaths.premiumCoach,
          extra: {'trigger': 'daily_check'},
        );
        return;
      }

      // FCM foreground notification (payload = type string)
      switch (payload) {
        case 'streak_milestone':
        case 'achievement':
        case 'streak':
          GoRouter.of(context).push(RoutePaths.progress);
          break;
        case 'leaderboard_top3':
        case 'leaderboard_overtaken':
        case 'leaderboard_winner':
          GoRouter.of(context).push(RoutePaths.leaderboard);
          break;
        case 'premium_activated':
          GoRouter.of(context).push(RoutePaths.premium);
          break;
        default:
          // flashcard payload: 'flashcard:folderId:cardId'
          if (payload.startsWith('flashcard:')) {
            GoRouter.of(context).pushNamed(RouteNames.flashcards);
          }
          break;
      }
    } catch (e) {
      debugPrint('⚠️ Notification tap xatosi: $e');
    }
  }

  // ── Kunlik eslatmalar ──────────────────────────────────────
  static Future<void> scheduleDailyReminders() async {
    try {
      await cancelDailyReminders();

      const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Kunlik eslatmalar',
          channelDescription: 'Har kuni mashq qilish uchun eslatmalar',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );

      await _localNotifications.zonedSchedule(
        1001,
        'Xayrli tong! ☀️',
        'Bugungi mashqni boshlash vaqti. Daraxtingizni sug\'oring! 🌱',
        _nextInstanceOfTime(8, 0),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await _localNotifications.zonedSchedule(
        1002,
        'Tushlik payti mashq! 🧠',
        'Kunlik maqsadingizning yarmiga yetdingizmi? 5 daqiqa yetarli!',
        _nextInstanceOfTime(13, 0),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await _localNotifications.zonedSchedule(
        1003,
        'Kechqurun eslatma 🌙',
        'Bugun hali mashq qilmadingizmi? Streakingizni yo\'qotmang! 🔥',
        _nextInstanceOfTime(20, 0),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('✅ Kunlik eslatmalar sozlandi (08:00, 13:00, 20:00)');
    } catch (e) {
      debugPrint('⚠️ Eslatma scheduling xatolik: $e');
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // ═══════════════════════════════════════════════════════
  // EBBINGHAUS SPACED REPETITION NOTIFIKATSIYALARI
  // Intervallar: 30 daq → 1s → 3s → 8s → 1kun → 3kun → 7kun → 14kun
  // ═══════════════════════════════════════════════════════

  static Future<void> scheduleFlashcardReviews({
    required String cardId,
    required String cardFront,
    required String folderId,
  }) async {
    try {
      const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          'flashcard_review',
          'Flashcard takrorlash',
          channelDescription:
              'Ebbinghaus qonuniga asosan takrorlash eslatmalari',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );

      final intervals = [
        const Duration(minutes: 30),
        const Duration(hours: 1),
        const Duration(hours: 3),
        const Duration(hours: 8),
        const Duration(days: 1),
        const Duration(days: 3),
        const Duration(days: 7),
        const Duration(days: 14),
      ];

      final labels = [
        '30 daqiqa',
        '1 soat',
        '3 soat',
        '8 soat',
        '1 kun',
        '3 kun',
        '7 kun',
        '14 kun'
      ];

      await cancelFlashcardReviews(cardId);
      final baseId = cardId.hashCode.abs() % 100000;

      // short - loop tashqarisida bir marta hisoblanadi
      final short = cardFront.length > 40
          ? '${cardFront.substring(0, 40)}...'
          : cardFront;

      for (int i = 0; i < intervals.length; i++) {
        final scheduledTime = tz.TZDateTime.now(tz.local).add(intervals[i]);
        final notifId = baseId + i;

        await _localNotifications.zonedSchedule(
          notifId,
          '🔁 Takrorlash vaqti keldi!',
          "'$short' — ${labels[i]} o'tdi",
          scheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'flashcard:$folderId:$cardId',
        );
      }
      debugPrint('✅ ${intervals.length} ta Ebbinghaus eslatma: $cardId');
    } catch (e) {
      debugPrint('⚠️ Flashcard eslatma xatolik: $e');
    }
  }

  static Future<void> cancelFlashcardReviews(String cardId) async {
    try {
      final baseId = cardId.hashCode.abs() % 100000;
      for (int i = 0; i < 8; i++) {
        await _localNotifications.cancel(baseId + i);
      }
    } catch (e) {
      debugPrint('⚠️ Eslatma bekor qilish: $e');
    }
  }

  static Future<void> onCardMastered(String cardId) async {
    await cancelFlashcardReviews(cardId);
    debugPrint('✅ Karta o\'zlashtirildi, eslatmalar bekor: $cardId');
  }

  static Future<void> cancelDailyReminders() async {
    try {
      await _localNotifications.cancel(1001);
      await _localNotifications.cancel(1002);
      await _localNotifications.cancel(1003);
    } catch (e) {
      debugPrint('⚠️ Eslatma bekor qilish xatolik: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      LoggerService.error('Topic obuna xatoligi', error: e);
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      LoggerService.error('Topic chiqish xatoligi', error: e);
    }
  }
}
