// ═══════════════════════════════════════════════════════════════
// TO'LIQ FAYL — COPY-PASTE QILING
// PATH: lib/features/profile/data/datasources/profile_remote_datasource.dart
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/profile/data/models/profile_model.dart';
import 'package:my_first_app/features/profile/domain/entities/profile.dart';

// ─── Interface ───────────────────────────────────────────────
abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile(String userId, {bool forceServer});

  Future<UserProfileModel> updateProfile(
    String userId,
    Map<String, dynamic> fields,
  );

  // ✅ YANGI: Notification uchun alohida method — Timestamp bug yo'q
  Future<UserProfileModel> updateNotificationSettings(
    String userId,
    UserNotificationSettings notifications,
  );

  Future<String> uploadAvatar(String userId, String filePath);
  Future<void> deleteAvatar(String userId); // ✅ FIX: O'chirish metodi
  Future<void> requestDataExport(String userId);
  Future<void> requestAccountDelete(String userId);
}

// ─── Implementation ───────────────────────────────────────────
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  ProfileRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  // ─── getProfile ───────────────────────────────────────────
  // ✅ FIX: forceServer=true — rasm yoki profil yangilangandan keyin
  // cache eski avatarUrl qaytarmasligi uchun server dan o'qiladi.
  // ✅ FIX 2: progress/{uid} dan totalXp va badges ham o'qiladi —
  // daily_box_service va giveStreakReward shu collection ga yozadi.
  @override
  Future<UserProfileModel> getProfile(String userId,
      {bool forceServer = false}) async {
    try {
      final options = forceServer
          ? const GetOptions(source: Source.server)
          : const GetOptions(source: Source.serverAndCache);

      // users + progress parallel o'qiymiz
      final results = await Future.wait([
        _firestore.collection('users').doc(userId).get(options),
        _firestore.collection('progress').doc(userId).get(options),
      ]);

      final userDoc = results[0];
      final progressDoc = results[1];

      if (!userDoc.exists) {
        throw const ServerException(message: 'Profil topilmadi');
      }

      final model = UserProfileModel.fromFirestore(userDoc);

      // progress/{uid} dan totalXp va badges ni ustiga yozamiz
      if (progressDoc.exists) {
        final pd = progressDoc.data() ?? {};
        final progressXp = pd['totalXp'] as int? ?? 0;
        final progressBadges = (pd['badges'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];

        // users/{uid} dan kelgan badges bilan progress dan kelganlarni birlashtir
        final allBadges = {...model.badges, ...progressBadges}.toList();

        // XP: users/{uid} yoki progress/{uid} — qaysi kattaroq bo'lsa
        final effectiveXp =
            progressXp > model.totalXp ? progressXp : model.totalXp;

        return UserProfileModel(
          id: model.id,
          fullName: model.fullName,
          email: model.email,
          phone: model.phone,
          role: model.role,
          preferredLanguage: model.preferredLanguage,
          uiLanguage: model.uiLanguage,
          level: model.level,
          avatarUrl: model.avatarUrl,
          dailyGoalMinutes: model.dailyGoalMinutes,
          currentStreak: model.currentStreak,
          longestStreak: model.longestStreak,
          totalXp: effectiveXp,
          badges: allBadges,
          notifications: model.notifications,
          preferences: model.preferences,
          lastActiveDate: model.lastActiveDate,
          createdAt: model.createdAt,
          updatedAt: model.updatedAt,
        );
      }

      return model;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Profil yuklanmadi: $e');
    }
  }

  // ─── updateProfile ────────────────────────────────────────
  // ESLATMA: Bu methodda notifications yubormang!
  // Notifications uchun updateNotificationSettings ishlating.
  @override
  Future<UserProfileModel> updateProfile(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      // ✅ server-side timestamp — mijoz soati bilan chalkashmasin
      fields['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(fields);
      // ✅ FIX: forceServer=true — yangilangandan keyin cache eski qolmasin
      return getProfile(userId, forceServer: true);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Profil yangilanmadi',
        code: e.code,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Profil yangilanmadi: $e');
    }
  }

  // ─── updateNotificationSettings ───────────────────────────
  // ✅ BUG FIX: Timestamp crash muammosi shu yerda hal qilindi.
  //
  // MUAMMO NIMA EDI:
  //   updateProfile() ichida fields['updatedAt'] = Timestamp.fromDate(now)
  //   qo'shilardi. Firestore.update() chaqirilganda ba'zan nested map
  //   sifatida yuborilardi:
  //     { notifications: {microSession: true}, updatedAt: Timestamp }
  //   Firestore SDK bu ikki fieldni birlashtirmay, ba'zan
  //   notifications field o'rniga Timestamp qaytarishi mumkin edi.
  //   Keyin fromFirestore() da:
  //     d['notifications'] as Map<String, dynamic>  ← CRASH!
  //
  // FIX:
  //   Dot notation bilan har bir fieldni alohida yangilash:
  //     'notifications.microSession': true
  //     'notifications.streak': true
  //   Bu Firestore'da faqat o'sha nested fieldni o'zgartiradi,
  //   boshqa fieldlarga tegmaydi.
  @override
  Future<UserProfileModel> updateNotificationSettings(
    String userId,
    UserNotificationSettings notifications,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        // ✅ Dot notation — notifications va updatedAt aralashmaydi
        'notifications.microSession': notifications.microSession,
        'notifications.streak': notifications.streak,
        'notifications.teacherContent': notifications.teacherContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // ✅ FIX: forceServer=true
      return getProfile(userId, forceServer: true);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Bildirishnoma sozlamalari saqlanmadi',
        code: e.code,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Bildirishnoma sozlamalari saqlanmadi: $e',
      );
    }
  }

  // ─── uploadAvatar ─────────────────────────────────────────
  // ✅ FIX: avatarUrl + photoUrl ikkisini ham yozamiz
  // Sabab: UserEntity photoUrl ni o'qiydi, ProfileHeader avatarUrl ni o'qiydi
  // Ikkalasi ham bir xil URL bo'lishi kerak — aks holda biri yangilanadi, ikkinchisi eski qoladi
  @override
  Future<String> uploadAvatar(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final ext = filePath.split('.').last.toLowerCase();
      // ✅ FIX: UUID o'rniga timestamp — debug qilish osonroq
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = _storage.ref('avatars/$userId/$fileName');

      // Metadata qo'shamiz — CORS muammolari oldini oladi
      final metadata = SettableMetadata(contentType: 'image/$ext');
      await ref.putFile(file, metadata);
      final url = await ref.getDownloadURL();

      // ✅ avatarUrl + photoUrl — ikkalasini ham yozamiz
      await _firestore.collection('users').doc(userId).update({
        'avatarUrl': url,
        'photoUrl': url, // UserEntity.photoUrl ham yangilanadi
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // ✅ FIX: Cache emas server dan tasdiqlash — rasm ko'rinadi
      await getProfile(userId, forceServer: true);
      return url;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Avatar yuklanmadi',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Avatar yuklanmadi: $e');
    }
  }

  // ─── deleteAvatar ─────────────────────────────────────────
  // ✅ YANGI: Rasmni Storage + Firestore dan o'chirish
  @override
  Future<void> deleteAvatar(String userId) async {
    try {
      // 1. Firestore dan hozirgi avatarUrl ni olish
      final doc = await _firestore.collection('users').doc(userId).get();
      final avatarUrl = doc.data()?['avatarUrl'] as String?;

      // 2. Storage dan o'chirish (URL mavjud bo'lsa)
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        try {
          final storageRef = _storage.refFromURL(avatarUrl);
          await storageRef.delete();
        } catch (_) {
          // Storage xatosi — Firestore ni baribir tozalaymiz
        }
      }

      // 3. Firestore dan URL ni o'chirish
      await _firestore.collection('users').doc(userId).update({
        'avatarUrl': FieldValue.delete(),
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? "Rasmni o'chirib bo'lmadi",
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: "Rasmni o'chirib bo'lmadi: $e");
    }
  }

  // ─── requestDataExport ────────────────────────────────────
  @override
  Future<void> requestDataExport(String userId) async {
    try {
      await _firestore.collection('dataRequests').add({
        'userId': userId,
        'type': 'export',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? "Export so'rov yuborilmadi",
        code: e.code,
      );
    }
  }

  // ─── requestAccountDelete ─────────────────────────────────
  // ✅ Google Play talabi: Firebase Auth hisobi ham o'chiriladi
  @override
  Future<void> requestAccountDelete(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // 1. Firestore da so'rov yozamiz (ma'lumotlarni tozalash uchun)
      await _firestore.collection('dataRequests').add({
        'userId': userId,
        'type': 'delete',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Firebase Auth hisobini o'chirish (Google Play talabi)
      // Bu operatsiya "recent login" talab qilishi mumkin
      // Agar xato bo'lsa — Firestore so'rovi saqlangan, admin keyinroq o'chiradi
      if (user != null && user.uid == userId) {
        try {
          await user.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            // Foydalanuvchi qayta login qilishi kerak
            // dataRequests da 'pending' holda qoladi — admin tomonidan o'chiriladi
            throw ServerException(
              message: "Hisobni o'chirish uchun qayta kirish talab etiladi. "
                  "Iltimos chiqib, qayta kiring va so'rov yuboring.",
              code: e.code,
            );
          }
          // Boshqa Auth xatolari — Firestore so'rov saqlangan, davom etamiz
        }
      }
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? "O'chirish so'rov yuborilmadi",
        code: e.code,
      );
    }
  }
}
