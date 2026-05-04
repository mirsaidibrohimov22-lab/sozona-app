// lib/core/services/activity_sync_service.dart
// So'zona — Activity Sync Service
// Internet qaytganda offline queue dagi faoliyatlarni serverga yuboradi.
// App ochilganda va connectivity o'zgarganda chaqiriladi.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/api_endpoints.dart';
import 'package:my_first_app/core/services/connectivity_service.dart';
import 'package:my_first_app/core/services/offline_activity_queue.dart';

class ActivitySyncService {
  ActivitySyncService._();

  static final _fn = FirebaseFunctions.instanceFor(region: 'us-central1');
  static bool _isSyncing = false;

  /// App ochilganda chaqiring — pending faoliyatlarni yuboradi
  static Future<void> syncOnStartup() async {
    final isEmpty = await OfflineActivityQueue.isEmpty();
    if (isEmpty) return;

    // Mavjud ConnectivityService orqali tekshiramiz
    final service = ConnectivityService();
    final hasInternet = await service.hasConnection;
    if (!hasInternet) {
      debugPrint('📴 Startup sync: internet yo\'q, keyinga qoldirildi');
      return;
    }

    await _sync();
  }

  /// Tashqaridan chaqirish uchun (provider ishlatadi)
  static Future<void> syncNow() => _sync();

  /// Asosiy sync logikasi
  static Future<void> _sync() async {
    if (_isSyncing) return; // Parallel sync oldini olamiz
    _isSyncing = true;

    try {
      final activities = await OfflineActivityQueue.getAll();
      if (activities.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint(
          '📤 Offline sync: ${activities.length} ta faoliyat yuborilmoqda...');

      final callable = _fn.httpsCallable(
        ApiEndpoints.recordActivity,
        options: HttpsCallableOptions(timeout: ApiEndpoints.defaultTimeout),
      );

      int successCount = 0;
      int failCount = 0;

      // Har bir faoliyatni ketma-ket yuboramiz
      // (parallel yuborilsa server haddan ziyod yuklanadi)
      for (final activity in activities) {
        try {
          // _queuedAt internal maydon — backendga yubormaymiz
          final payload = Map<String, dynamic>.from(activity)
            ..remove('_queuedAt');

          await callable.call(payload);
          successCount++;
        } catch (e) {
          failCount++;
          debugPrint('⚠️ Sync xatosi (bitta faoliyat): $e');
          // Bitta xato hamma narsani to'xtatmasin — davom etamiz
        }
      }

      // Hech bo'lmasa bitta muvaffaqiyatli bo'lsa — queue ni tozalaymiz
      // (muvaffaqiyatsizlar yo'qolishi afzal, loop bo'lishidan ko'ra)
      if (successCount > 0) {
        await OfflineActivityQueue.clear();
        debugPrint(
            '✅ Offline sync tugadi: $successCount muvaffaqiyatli, $failCount xato');
      } else {
        debugPrint('⚠️ Offline sync: hech biri yuklanmadi ($failCount xato)');
      }
    } catch (e) {
      debugPrint('⚠️ Offline sync umumiy xatosi: $e');
    } finally {
      _isSyncing = false;
    }
  }
}

/// Provider — mavjud connectivityStreamProvider orqali internet qaytganda sync
/// Connectivity() yangi instance yaratish o'rniga loyihadagi provider ishlatiladi
final activitySyncProvider = Provider<void>((ref) {
  // connectivityStreamProvider: true=online, false=offline
  ref.listen<AsyncValue<bool>>(connectivityStreamProvider, (prev, next) {
    final wasOffline = prev?.value == false || prev == null;
    final isNowOnline = next.value == true;

    // Faqat offline → online o'tganda sync qilamiz
    if (wasOffline && isNowOnline) {
      debugPrint('🌐 Internet qaytdi — offline faoliyatlar sync qilinmoqda...');
      ActivitySyncService.syncNow();
    }
  });
});
