// lib/core/services/notification_service.dart
// So'zona — Push notification servisi (FCM)
// ✅ flutter_local_notifications ^18.x API

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'teacher_content',
    'O\'qituvchi kontentlari',
    description: 'O\'qituvchi yuborgan mashqlar haqida bildirishnomalar',
    importance: Importance.high,
  );

  static Future<void> init() async {
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
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Local notifications setup xatosi: $e');
    }
  }

  // ── Foreground xabarni ko'rsatish ──────────────────────────
  static void _handleForegroundMessage(RemoteMessage message) {
    LoggerService.info('Foreground xabar: ${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
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
      );
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    LoggerService.info('Xabardan ochildi: ${message.data}');
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

  // ── Kunlik eslatmalar ───────────────────────────────────────
  static Future<void> scheduleDailyReminders() async {
    try {
      await cancelDailyReminders();

      const details = NotificationDetails(
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

      await _localNotifications.periodicallyShow(
        id: 1001,
        title: 'Xayrli tong! ☀️',
        body: 'Bugungi mashqni boshlash vaqti. Daraxtingizni sug\'oring! 🌱',
        repeatInterval: RepeatInterval.daily,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexact,
      );

      await _localNotifications.periodicallyShow(
        id: 1002,
        title: 'Tushlik payti mashq! 🧠',
        body: 'Kunlik maqsadingizning yarmiga yetdingizmi? 5 daqiqa yetarli!',
        repeatInterval: RepeatInterval.daily,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexact,
      );

      await _localNotifications.periodicallyShow(
        id: 1003,
        title: 'Kechqurun eslatma 🌙',
        body: 'Bugun hali mashq qilmadingizmi? Streakingizni yo\'qotmang! 🔥',
        repeatInterval: RepeatInterval.daily,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexact,
      );

      debugPrint('✅ Kunlik eslatmalar sozlandi');
    } catch (e) {
      debugPrint('⚠️ Eslatma scheduling xatolik: $e');
    }
  }

  static Future<void> cancelDailyReminders() async {
    try {
      await _localNotifications.cancel(id: 1001);
      await _localNotifications.cancel(id: 1002);
      await _localNotifications.cancel(id: 1003);
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
