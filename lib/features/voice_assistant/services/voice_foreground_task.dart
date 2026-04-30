// lib/features/voice_assistant/services/voice_foreground_task.dart
// ✅ YANGI FAYL — Fon servisi (ekran o'chsa ham, ilova yopilsa ham ishlaydi)
//
// Bu fayl flutter_foreground_task paketini ishlatadi.
// pubspec.yaml ga qo'shing:
//   flutter_foreground_task: ^8.13.0
//
// AndroidManifest.xml ga qo'shing (application tagi ICHIGA):
//   <service
//       android:name="com.pravera.flutter_foreground_task.service.ForegroundTaskService"
//       android:foregroundServiceType="microphone"
//       android:exported="false" />
//
// <uses-permission android:name="android.permission.RECORD_AUDIO"/>
// <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
// <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/material.dart';

// ─── Foreground Task Handler ──────────────────────
// Bu class isolate'da ishlaydi — to'g'ridan-to'g'ri UI bilan gaplasha olmaydi
// VoiceAssistantService bilan SendPort orqali xabar almashadi
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_VoiceTaskHandler());
}

class _VoiceTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('VoiceForegroundTask: boshlandi');
    // Asosiy wake word logikasi VoiceAssistantService da — bu faqat servis tirik turishi uchun
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Har minutda ishlaydi — servisni tirik saqlaydi
    debugPrint(
        'VoiceForegroundTask: tirik (${timestamp.hour}:${timestamp.minute})');
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('VoiceForegroundTask: to\'xtatildi');
  }

  @override
  void onReceiveData(Object data) {
    debugPrint('VoiceForegroundTask data: $data');
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }
}

// ─── Foreground Service Manager ──────────────────
class VoiceForegroundService {
  VoiceForegroundService._();

  static bool _initialized = false;

  // ── Sozlash ──────────────────────────────────────
  static void init() {
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sozana_voice_channel',
        channelName: "So'zona tinglayapti",
        channelDescription: "So'zona ovozli yordamchi fonda ishlayapti",
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // har daqiqada
        autoRunOnBoot: true, // telefon o'chirib yoqilsa ham qayta boshlaydi
        autoRunOnMyPackageReplaced: true,
        allowWifiLock: false,
      ),
    );
  }

  // ── Ruxsat so'rash ────────────────────────────────
  static Future<bool> requestPermissions() async {
    final notifPerm = await FlutterForegroundTask.checkNotificationPermission();
    if (notifPerm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    return true;
  }

  // ── Xizmatni boshlash ─────────────────────────────
  static Future<ServiceRequestResult> start() async {
    await requestPermissions();

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    }

    return FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: "So'zona tinglayapti",
      notificationText: '"Salom So\'zona" deb chaqiring',
      notificationButtons: [
        const NotificationButton(id: 'stop', text: "To'xtatish"),
      ],
      callback: startCallback,
    );
  }

  // ── Xizmatni to'xtatish ───────────────────────────
  static Future<ServiceRequestResult> stop() async {
    return FlutterForegroundTask.stopService();
  }

  // ── Holat tekshirish ──────────────────────────────
  static Future<bool> get isRunning => FlutterForegroundTask.isRunningService;

  // ── Bildirishnoma matnini yangilash ───────────────
  static Future<void> updateNotification(String text) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: "So'zona tinglayapti",
      notificationText: text,
    );
  }
}
